param(
  [int]$MinimumFreeGB = 1,
  [switch]$KeepLocalArchive
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$workRoot = Join-Path $env:LOCALAPPDATA 'CertaSurv\FastOffload'
$sessionRoot = Join-Path $workRoot $stamp
New-Item -ItemType Directory -Force -Path $sessionRoot | Out-Null
$logFile = Join-Path $sessionRoot 'FAST_OFFLOAD.log'

function Log([string]$Message) {
  $line = "$(Get-Date -Format s) $Message"
  $line | Tee-Object -FilePath $logFile -Append | Write-Host
}

function Stop-OlderOffloadWorkers {
  try {
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
      Where-Object {
        $_.ProcessId -ne $PID -and
        $_.Name -match '^(powershell|pwsh)(\.exe)?$' -and
        $_.CommandLine -match 'CertaNode-Legacy-Handoff\.ps1'
      } |
      ForEach-Object {
        Log "Stopping older offload process PID=$($_.ProcessId)"
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
      }
    Get-CimInstance Win32_Process -Filter "Name='robocopy.exe'" -ErrorAction SilentlyContinue |
      Where-Object { $_.CommandLine -match 'CERTASURV_SERVER_HANDOFF' } |
      ForEach-Object {
        Log "Stopping older robocopy offload worker PID=$($_.ProcessId)"
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
      }
  } catch {
    Log "WARN could not inspect older offload processes: $($_.Exception.Message)"
  }
}

function Get-UsbVolumes {
  $out = @()
  foreach ($v in @(Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and $_.DriveLetter -ne 'C' -and $_.FileSystem })) {
    $root = "$($v.DriveLetter):\"
    $probe = Join-Path $root '.certasurv_write_probe'
    $writable = $false
    try {
      'ok' | Set-Content -LiteralPath $probe -Encoding ASCII -ErrorAction Stop
      Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
      $writable = $true
    } catch {}
    if (-not $writable) { continue }

    $bus = ''
    try {
      $p = Get-Partition -DriveLetter $v.DriveLetter -ErrorAction Stop
      $d = $p | Get-Disk -ErrorAction Stop
      $bus = [string]$d.BusType
    } catch {}

    $isExternal = ($bus -in @('USB','SD','MMC')) -or ([string]$v.DriveType -eq 'Removable')
    if (-not $isExternal) { continue }

    $out += [pscustomobject]@{
      Drive       = "$($v.DriveLetter):"
      Root        = $root
      Label       = [string]$v.FileSystemLabel
      FileSystem  = [string]$v.FileSystem
      BusType     = $bus
      Size        = [int64]$v.Size
      FreeSpace   = [int64]$v.SizeRemaining
    }
  }
  @($out | Sort-Object FreeSpace -Descending)
}

Stop-OlderOffloadWorkers
Log "START node=$env:COMPUTERNAME user=$env:USERNAME"

$usb = @(Get-UsbVolumes)
if ($usb.Count -eq 0) {
  throw 'No writable USB/SD/MMC destination volumes were detected.'
}
Log "External destinations: $($usb.Drive -join ', ')"
$usb | Export-Csv (Join-Path $sessionRoot 'DESTINATION_DRIVES.csv') -NoTypeInformation -Encoding UTF8

$selected = New-Object System.Collections.Generic.List[object]
$seen = @{}

$scriptExt = @('.ps1','.psm1','.py','.bat','.cmd','.sh','.js','.ts','.tsx','.jsx','.lsp','.scr','.sql')
$kbExt = @('.md','.txt','.json','.yaml','.yml','.toml','.ini','.csv','.xml')
$allowedExt = @($scriptExt + $kbExt)
$keyword = '(?i)(certa|survey|certacad|certard|certanode|skill|agent|workflow|automation|script|ortho|lidar|qgis|cloudcompare|webodm|appsheet|handoff|import|classif|draft|validator|receipt|openproject|twenty|authentik|trimble|tbc|land.?desktop|cogo|deed|plat|gnss|opus|field)'
$skipDir = '(?i)^(node_modules|\.git|\.svn|\.hg|\.venv|venv|__pycache__|dist|build|cache|caches|temp|tmp|raw|photos?|images?|orthos?|lidar|pointclouds?|downloads?|output|outputs|renders?|models?)$'

function Add-SelectedFile([string]$Path, [string]$Class) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
  try {
    $f = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($f.Length -gt 50MB) { return }
    $full = [IO.Path]::GetFullPath($f.FullName)
    if ($full -notmatch '^[Cc]:\\') { return }
    $key = $full.ToLowerInvariant()
    if ($seen.ContainsKey($key)) { return }
    $seen[$key] = $true
    $selected.Add([pscustomobject]@{
      Source        = $full
      ArchivePath   = ($full.Substring(3) -replace '\\','/')
      Class         = $Class
      Bytes         = [int64]$f.Length
      LastWriteTime = $f.LastWriteTime.ToString('o')
    }) | Out-Null
  } catch {}
}

function Add-WholeTree([string]$Root, [string]$Class) {
  if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return }
  Log "Indexing $Class :: $Root"
  Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction SilentlyContinue |
    ForEach-Object { Add-SelectedFile $_.FullName $Class }
}

function Add-CuratedTree([string]$Root) {
  if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return }
  Log "Curating scripts/KB :: $Root"
  $stack = New-Object System.Collections.Stack
  $stack.Push((Get-Item -LiteralPath $Root))
  while ($stack.Count -gt 0) {
    $dir = $stack.Pop()
    try {
      foreach ($sub in @(Get-ChildItem -LiteralPath $dir.FullName -Directory -Force -ErrorAction SilentlyContinue)) {
        if ($sub.Name -notmatch $skipDir) { $stack.Push($sub) }
      }
      foreach ($f in @(Get-ChildItem -LiteralPath $dir.FullName -File -Force -ErrorAction SilentlyContinue)) {
        $ext = $f.Extension.ToLowerInvariant()
        if ($ext -notin $allowedExt) { continue }
        if ($f.Length -gt 50MB) { continue }
        if (($f.FullName -notmatch $keyword) -and ($f.Name -notmatch $keyword)) { continue }
        $class = if ($ext -in $scriptExt) { 'SCRIPT_TOOL' } else { 'LIMITED_KNOWLEDGE' }
        Add-SelectedFile $f.FullName $class
      }
    } catch {}
  }
}

# First-class live automation assets. These are intentionally small/high-value trees.
foreach ($entry in @(
  @((Join-Path $env:USERPROFILE '.codex\skills'),  'SKILLS'),
  @((Join-Path $env:USERPROFILE '.codex\agents'),  'AGENTS'),
  @((Join-Path $env:USERPROFILE '.codex\rules'),   'RULES'),
  @((Join-Path $env:USERPROFILE '.codex\prompts'), 'PROMPTS'),
  @('C:\Certa4010\TriggerBridge', 'CERTANODE_BRIDGE'),
  @('C:\Certa4010\skills',        'CERTA_SKILLS'),
  @('C:\Certa4010\scripts',       'CERTA_SCRIPTS'),
  @('C:\Certa4010\tools',         'CERTA_TOOLS'),
  @('C:\Certa4010\config',        'CERTA_CONFIG')
)) {
  Add-WholeTree $entry[0] $entry[1]
}

# Keep useful top-level Certa4010 definitions without dragging logs, caches, staging, or datasets.
if (Test-Path -LiteralPath 'C:\Certa4010') {
  Get-ChildItem -LiteralPath 'C:\Certa4010' -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension.ToLowerInvariant() -in $allowedExt } |
    ForEach-Object { Add-SelectedFile $_.FullName 'CERTA_TOPLEVEL' }
}

# Curate only script/knowledge text from legacy work areas; explicitly prune bulky data trees.
foreach ($r in @(
  (Join-Path $env:USERPROFILE 'Documents\ChatGPT'),
  (Join-Path $env:USERPROFILE 'Documents\Codex'),
  (Join-Path $env:USERPROFILE 'Desktop\Codex'),
  (Join-Path $env:USERPROFILE 'source')
)) {
  Add-CuratedTree $r
}

if ($selected.Count -eq 0) {
  throw 'No curated skills/scripts/limited-knowledge files were found.'
}

$manifest = Join-Path $sessionRoot 'CURATED_MANIFEST.csv'
$selected | Sort-Object Source | Export-Csv $manifest -NoTypeInformation -Encoding UTF8
$totalBytes = [int64](($selected | Measure-Object Bytes -Sum).Sum)
$estimatedArchive = $totalBytes + ([int64]$selected.Count * 2048) + 128MB
Log "Selected files=$($selected.Count) payloadGB=$([math]::Round($totalBytes/1GB,3)) estimatedArchiveGB=$([math]::Round($estimatedArchive/1GB,3))"

$readme = Join-Path $sessionRoot 'README_CURATED_OFFLOAD.txt'
@"
CertaSurv FAST CURATED OFFLOAD
Generated: $(Get-Date -Format o)
Computer: $env:COMPUTERNAME

PURPOSE
- Preserve CertaSurv skills, agents, rules, prompts, reusable scripts/tools, and a LIMITED text knowledge base.
- This is intentionally NOT a full workstation backup.
- Large project data, imagery, lidar, point clouds, downloads, caches, build trees, and generic legacy files are excluded.

VERIFICATION
- One TAR archive is created.
- The identical archive is copied to every detected writable USB/SD/MMC destination.
- SHA-256 of every destination must equal the source archive hash.
- CURATED_OFFLOAD_VERIFIED.flag is written only when every detected destination passes.

Do not treat this archive as proof that unrelated personal/project data was backed up.
"@ | Set-Content -LiteralPath $readme -Encoding UTF8

$fileList = Join-Path $sessionRoot 'tar_file_list.txt'
$tarEntries = New-Object System.Collections.Generic.List[string]
foreach ($x in @($selected | Sort-Object ArchivePath)) { $tarEntries.Add($x.ArchivePath) | Out-Null }
foreach ($metaPath in @($manifest,$readme)) {
  $fullMeta = [IO.Path]::GetFullPath($metaPath)
  $tarEntries.Add(($fullMeta.Substring(3) -replace '\\','/')) | Out-Null
}
$tarEntries | Set-Content -LiteralPath $fileList -Encoding ASCII

$archiveName = "CERTASURV_CURATED_$stamp.tar"
$localArchive = Join-Path $sessionRoot $archiveName
$cFree = [int64](Get-PSDrive -Name C).Free
$useLocalSeed = $cFree -gt ($estimatedArchive + 512MB)

$seedDrive = $null
if ($useLocalSeed) {
  $archive = $localArchive
  Log "Archive seed=C: (enough free space for one temporary TAR)"
} else {
  $seedDrive = $usb | Where-Object { $_.FreeSpace -gt ($estimatedArchive + 256MB) } | Select-Object -First 1
  if (-not $seedDrive) { throw 'No destination has enough free space for the curated archive.' }
  $seedDir = Join-Path $seedDrive.Root 'CERTASURV_SERVER_HANDOFF\FAST_OFFLOAD'
  New-Item -ItemType Directory -Force -Path $seedDir | Out-Null
  $archive = Join-Path $seedDir $archiveName
  Log "Archive seed=$($seedDrive.Drive) because C: is too full for a temporary archive"
}

$tar = (Get-Command tar.exe -ErrorAction SilentlyContinue).Source
if (-not $tar) { throw 'Windows tar.exe was not found.' }
Log "Creating single-file TAR archive..."
& $tar -cf $archive -C 'C:\' -T $fileList
if ($LASTEXITCODE -ne 0) { throw "tar.exe failed with exit code $LASTEXITCODE" }
$archiveItem = Get-Item -LiteralPath $archive -ErrorAction Stop
$sourceHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
Log "Archive ready sizeGB=$([math]::Round($archiveItem.Length/1GB,3)) sha256=$sourceHash"

# Every external destination gets the exact same archive. Copies run concurrently.
$jobs = @()
$preverified = @()
foreach ($d in $usb) {
  $destDir = Join-Path $d.Root 'CERTASURV_SERVER_HANDOFF\FAST_OFFLOAD'
  New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  $destArchive = Join-Path $destDir $archiveName

  if ([IO.Path]::GetFullPath($destArchive) -eq [IO.Path]::GetFullPath($archive)) {
    $preverified += [pscustomobject]@{
      Drive=$d.Drive; Destination=$destArchive; CopyResult=0; Hash=$sourceHash; Verified=$true; Error='SEED_ARCHIVE'
    }
    continue
  }

  if ($d.FreeSpace -lt ($archiveItem.Length + 128MB)) {
    $preverified += [pscustomobject]@{
      Drive=$d.Drive; Destination=$destArchive; CopyResult='NO_SPACE'; Hash=''; Verified=$false; Error='Not enough free space'
    }
    continue
  }

  $payload = [pscustomobject]@{
    SourceDir = (Split-Path -Parent $archive)
    ArchiveName = $archiveName
    SourceHash = $sourceHash
    DestDir = $destDir
    DestArchive = $destArchive
    Drive = $d.Drive
  }
  $jobs += Start-Job -ArgumentList (,$payload) -ScriptBlock {
    param($p)
    try {
      & robocopy.exe $p.SourceDir $p.DestDir $p.ArchiveName /J /R:1 /W:1 /NP /NFL /NDL /NJH /NJS | Out-Null
      $rc = $LASTEXITCODE
      if ($rc -gt 7) { throw "robocopy exit code $rc" }
      $h = (Get-FileHash -LiteralPath $p.DestArchive -Algorithm SHA256).Hash
      [pscustomobject]@{Drive=$p.Drive;Destination=$p.DestArchive;CopyResult=$rc;Hash=$h;Verified=($h -eq $p.SourceHash);Error=''}
    } catch {
      [pscustomobject]@{Drive=$p.Drive;Destination=$p.DestArchive;CopyResult='ERROR';Hash='';Verified=$false;Error=$_.Exception.Message}
    }
  }
}

if ($jobs.Count -gt 0) {
  Log "Parallel-copy workers started=$($jobs.Count)"
}
$jobResults = @()
if ($jobs.Count -gt 0) {
  $jobResults = @($jobs | Wait-Job | Receive-Job)
  $jobs | Remove-Job -Force
}
$results = @($preverified + $jobResults | Sort-Object Drive)
$results | Export-Csv (Join-Path $sessionRoot 'USB_VERIFY.csv') -NoTypeInformation -Encoding UTF8

$allVerified = ($results.Count -eq $usb.Count) -and (@($results | Where-Object { -not $_.Verified }).Count -eq 0)
$summary = [ordered]@{
  completed_at = (Get-Date).ToString('o')
  computer = $env:COMPUTERNAME
  selected_files = $selected.Count
  selected_bytes = $totalBytes
  selected_gb = [math]::Round($totalBytes/1GB,3)
  archive_name = $archiveName
  archive_bytes = [int64]$archiveItem.Length
  archive_sha256 = $sourceHash
  destination_count = $usb.Count
  verified_count = @($results | Where-Object { $_.Verified }).Count
  all_destinations_verified = $allVerified
  destinations = @($results)
}
$summaryPath = Join-Path $sessionRoot 'FAST_OFFLOAD_SUMMARY.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

foreach ($r in $results) {
  $destDir = Split-Path -Parent $r.Destination
  foreach ($meta in @($manifest,$readme,$summaryPath,(Join-Path $sessionRoot 'USB_VERIFY.csv'),$logFile)) {
    if (Test-Path -LiteralPath $destDir) {
      Copy-Item -LiteralPath $meta -Destination (Join-Path $destDir (Split-Path $meta -Leaf)) -Force -ErrorAction SilentlyContinue
    }
  }
  if ($allVerified) {
    "ALL DETECTED DESTINATIONS VERIFIED`r`n$sourceHash`r`n$(Get-Date -Format o)" |
      Set-Content -LiteralPath (Join-Path $destDir 'CURATED_OFFLOAD_VERIFIED.flag') -Encoding ASCII
  }
}

if ($useLocalSeed -and -not $KeepLocalArchive -and $allVerified) {
  Remove-Item -LiteralPath $localArchive -Force -ErrorAction SilentlyContinue
  Log 'Removed temporary C: archive after all USB hashes verified.'
}

if ($allVerified) {
  Log "DONE PASS destinations=$($usb.Count) hash=$sourceHash"
  Write-Output "CERTANODE_FAST_CURATED_OFFLOAD_COMPLETE drives=$($usb.Count) files=$($selected.Count) verified=$($summary.verified_count)"
} else {
  Log "DONE INCOMPLETE verified=$($summary.verified_count)/$($usb.Count). Source data was NOT deleted."
  Write-Output "CERTANODE_FAST_CURATED_OFFLOAD_INCOMPLETE verified=$($summary.verified_count)/$($usb.Count)"
  exit 2
}
