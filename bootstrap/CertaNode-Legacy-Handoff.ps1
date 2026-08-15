$ErrorActionPreference='Stop'

function Get-TreeStats([string]$Path){
  if(-not(Test-Path -LiteralPath $Path)){return [pscustomobject]@{Files=0;Bytes=0}}
  $items=Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue
  $bytes=($items|Measure-Object Length -Sum).Sum;if($null-eq$bytes){$bytes=0}
  [pscustomobject]@{Files=@($items).Count;Bytes=[int64]$bytes}
}

# Discover every writable non-C volume; USB SSDs may report as Fixed.
$candidates=@()
try{
  $candidates=Get-Volume|Where-Object{$_.DriveLetter-and$_.DriveLetter-ne'C'-and$_.FileSystem}|ForEach-Object{
    $root="$($_.DriveLetter):\";$probe=Join-Path $root '.certasurv_probe';$ok=$false
    try{'x'|Set-Content $probe -Encoding ASCII -ErrorAction Stop;Remove-Item $probe -Force;$ok=$true}catch{}
    [pscustomobject]@{DeviceID="$($_.DriveLetter):";Label=$_.FileSystemLabel;FileSystem=$_.FileSystem;Size=[int64]$_.Size;FreeSpace=[int64]$_.SizeRemaining;Writable=$ok}
  }|Where-Object Writable
}catch{}
if(-not$candidates){throw 'No writable non-C: filesystem volume found.'}
$candidates=@($candidates|Sort-Object FreeSpace -Descending)

# Handoff roots on every attached drive.
$roots=@{}
foreach($d in $candidates){
  $r=Join-Path "$($d.DeviceID)\" 'CERTASURV_SERVER_HANDOFF'
  foreach($n in '01_SKILLS_AGENTS_WORKFLOWS','02_SCRIPTS_TOOLS','03_REPOS','04_LIMITED_KNOWLEDGE_BASE','99_LOGS'){
    New-Item -ItemType Directory -Force -Path (Join-Path $r $n)|Out-Null
  }
  $roots[$d.DeviceID]=$r
}
$primary=$candidates[0]
$logs=Join-Path $roots[$primary.DeviceID] '99_LOGS'
$logFile=Join-Path $logs 'legacy_handoff.log'
function Log([string]$m){"$(Get-Date -Format s) $m"|Tee-Object -FilePath $logFile -Append}
$candidates|Export-Csv (Join-Path $logs 'DRIVE_CANDIDATES.csv') -NoTypeInformation -Encoding UTF8

# MSI role policy: keep CAD production runtime local; server owns automation/task execution.
$role=[ordered]@{
  generated_at=(Get-Date).ToString('o');node=$env:COMPUTERNAME;role='CAD_PRODUCTION_NODE';
  keep_local=@('C:\Certa4010','Active CAD project working set','CAD/TBC/Land Desktop/QGIS/CloudCompare runtime','Drivers/licenses/hardware interfaces');
  server_owned=@('Skills','Agents','Rules','Workflows','Automation scripts','Git repositories','Reusable tools','Limited durable knowledge base');
  purge_rule='Delete only ledger rows with SAFE_TO_PURGE=YES. KEEP_LOCAL_RECOVERY_COPY rows are never purgeable.'
}
foreach($d in $candidates){$role|ConvertTo-Json -Depth 5|Set-Content (Join-Path $roots[$d.DeviceID] 'MSI_ROLE_POLICY.json') -Encoding UTF8}

$ledger=[System.Collections.Concurrent.ConcurrentBag[object]]::new()
$manifest=[System.Collections.Concurrent.ConcurrentBag[object]]::new()

function New-PlanItem($source,$rel,$category,$purge){
  if(Test-Path -LiteralPath $source){
    $s=Get-TreeStats $source
    [pscustomobject]@{Source=$source;Relative=$rel;Category=$category;PurgeEligible=$purge;Bytes=$s.Bytes;Files=$s.Files}
  }
}

$plan=@()
$plan+=New-PlanItem 'C:\Certa4010' '02_SCRIPTS_TOOLS\Certa4010_RECOVERY_COPY' 'CertaNode runtime/config' $false
foreach($x in @(
  @((Join-Path $env:USERPROFILE '.codex\skills'),'01_SKILLS_AGENTS_WORKFLOWS\codex_skills','Codex skills'),
  @((Join-Path $env:USERPROFILE '.codex\agents'),'01_SKILLS_AGENTS_WORKFLOWS\codex_agents','Codex agents'),
  @((Join-Path $env:USERPROFILE '.codex\rules'),'01_SKILLS_AGENTS_WORKFLOWS\codex_rules','Codex rules'),
  @((Join-Path $env:USERPROFILE '.codex\prompts'),'01_SKILLS_AGENTS_WORKFLOWS\codex_prompts','Codex prompts')
)){$plan+=New-PlanItem $x[0] $x[1] $x[2] $true}

# Discover reusable scripts/workflows and Git repos only.
$scanRoots=@((Join-Path $env:USERPROFILE 'Documents\ChatGPT'),(Join-Path $env:USERPROFILE 'Documents\Codex'),(Join-Path $env:USERPROFILE 'Desktop\Codex'),(Join-Path $env:USERPROFILE 'source'))|Where-Object{Test-Path $_}
$exts=@('.ps1','.psm1','.py','.bat','.cmd','.sh','.js','.ts','.tsx','.jsx','.json','.yaml','.yml','.toml','.ini','.lsp','.scr','.sql','.md')
$keyword='skill|agent|workflow|script|automation|certacad|certard|certanode|ortho|lidar|survey|qgis|cloudcompare|webodm|appsheet|handoff|import|classif|draft|qc|validator|receipt|server|openproject|twenty|authentik'
$files=@()
foreach($r in $scanRoots){$files+=Get-ChildItem -LiteralPath $r -File -Recurse -Force -ErrorAction SilentlyContinue|Where-Object{$_.Extension.ToLower()-in$exts-and($_.FullName-match$keyword-or$_.Name-match$keyword)-and$_.Length-lt50MB}}
$files=@($files|Sort-Object FullName -Unique)
$i=0
foreach($f in $files){$i++;$bucket=if($f.Extension-eq'.md'){'04_LIMITED_KNOWLEDGE_BASE'}else{'02_SCRIPTS_TOOLS'};$plan+= [pscustomobject]@{Source=$f.FullName;Relative=(Join-Path $bucket ("{0:D5}_{1}" -f $i,$f.Name));Category=if($f.Extension-eq'.md'){'Curated knowledge'}else{'Selected script/workflow'};PurgeEligible=$true;Bytes=[int64]$f.Length;Files=1}}

$repos=@()
foreach($r in $scanRoots){$repos+=Get-ChildItem -LiteralPath $r -Directory -Recurse -Depth 7 -Force -ErrorAction SilentlyContinue|Where-Object{$_.Name-eq'.git'}|ForEach-Object{$_.Parent.FullName}}
$repos=@($repos|Sort-Object -Unique)
$n=0
foreach($repo in $repos){$n++;$plan+=New-PlanItem $repo (Join-Path '03_REPOS' ("{0:D3}_{1}" -f $n,(Split-Path $repo -Leaf))) 'Git repository' $true}
$repos|Set-Content (Join-Path $logs 'REPO_PATHS.txt') -Encoding UTF8

# Greedy bin-pack by size so all drives are used; largest assets assigned first to least-loaded drive.
$driveState=@{}
foreach($d in $candidates){$driveState[$d.DeviceID]=[int64]0}
$assignments=@()
foreach($p in @($plan|Sort-Object Bytes -Descending)){
  $d=$candidates|Sort-Object @{Expression={$driveState[$_.DeviceID]};Ascending=$true}|Select-Object -First 1
  $driveState[$d.DeviceID]+=$p.Bytes
  $assignments += [pscustomobject]@{Drive=$d.DeviceID;Source=$p.Source;Relative=$p.Relative;Category=$p.Category;PurgeEligible=$p.PurgeEligible;Bytes=$p.Bytes;Files=$p.Files}
}
$assignments|Export-Csv (Join-Path $logs 'COPY_PLAN.csv') -NoTypeInformation -Encoding UTF8

# Run one worker per drive in parallel.
$jobs=@()
foreach($d in $candidates){
  $items=@($assignments|Where-Object Drive -eq $d.DeviceID)
  if(-not$items){continue}
  $destRoot=$roots[$d.DeviceID]
  $jobs+=Start-Job -ArgumentList @($items,$destRoot,$d.DeviceID) -ScriptBlock {
    param($items,$destRoot,$driveId)
    $out=@()
    foreach($p in $items){
      $dest=Join-Path $destRoot $p.Relative
      try{
        if($p.Files-eq1 -and -not (Get-Item -LiteralPath $p.Source).PSIsContainer){
          New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent)|Out-Null
          Copy-Item -LiteralPath $p.Source -Destination $dest -Force
          $h1=(Get-FileHash -LiteralPath $p.Source -Algorithm SHA256).Hash;$h2=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
          $ok=$h1-eq$h2;$df=1;$db=(Get-Item $dest).Length
        }else{
          New-Item -ItemType Directory -Force -Path $dest|Out-Null
          & robocopy.exe $p.Source $dest /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /XJ /FFT /MT:8 /NP /NFL /NDL | Out-Null
          $rc=$LASTEXITCODE
          $src=Get-ChildItem -LiteralPath $p.Source -File -Recurse -Force -ErrorAction SilentlyContinue;$dst=Get-ChildItem -LiteralPath $dest -File -Recurse -Force -ErrorAction SilentlyContinue
          $sb=($src|Measure-Object Length -Sum).Sum;if($null-eq$sb){$sb=0};$db=($dst|Measure-Object Length -Sum).Sum;if($null-eq$db){$db=0}
          $df=@($dst).Count;$ok=($rc-le7)-and(@($src).Count-eq$df)-and([int64]$sb-eq[int64]$db)
        }
        $safe=if($ok-and$p.PurgeEligible){'YES'}else{'NO'}
        $out+=[pscustomobject]@{DRIVE=$driveId;CATEGORY=$p.Category;SOURCE_PATH=$p.Source;DESTINATION_PATH=$dest;SOURCE_FILES=$p.Files;DEST_FILES=$df;SOURCE_BYTES=$p.Bytes;DEST_BYTES=[int64]$db;VERIFIED=$ok;PURGE_ELIGIBLE=$p.PurgeEligible;DISPOSITION=if($p.PurgeEligible){'OFFLOAD_SERVER'}else{'KEEP_LOCAL_RECOVERY_COPY'};SAFE_TO_PURGE=$safe;COPIED_AT=(Get-Date).ToString('o')}
      }catch{
        $out+=[pscustomobject]@{DRIVE=$driveId;CATEGORY=$p.Category;SOURCE_PATH=$p.Source;DESTINATION_PATH=$dest;SOURCE_FILES=$p.Files;DEST_FILES=0;SOURCE_BYTES=$p.Bytes;DEST_BYTES=0;VERIFIED=$false;PURGE_ELIGIBLE=$p.PurgeEligible;DISPOSITION='COPY_ERROR';SAFE_TO_PURGE='NO';COPIED_AT=(Get-Date).ToString('o');ERROR=$_.Exception.Message}
      }
    }
    $out
  }
}

$results=@($jobs|Wait-Job|Receive-Job)
$jobs|Remove-Job -Force
$results|Export-Csv (Join-Path $logs 'PURGE_LEDGER.csv') -NoTypeInformation -Encoding UTF8
$results|ConvertTo-Json -Depth 6|Set-Content (Join-Path $logs 'PURGE_LEDGER.json') -Encoding UTF8

# Mirror master ledger/plan onto every drive so any one drive identifies the complete set.
foreach($d in $candidates){
  $l=Join-Path $roots[$d.DeviceID] '99_LOGS'
  Copy-Item (Join-Path $logs 'PURGE_LEDGER.csv') (Join-Path $l 'PURGE_LEDGER.csv') -Force
  Copy-Item (Join-Path $logs 'PURGE_LEDGER.json') (Join-Path $l 'PURGE_LEDGER.json') -Force
  Copy-Item (Join-Path $logs 'COPY_PLAN.csv') (Join-Path $l 'COPY_PLAN.csv') -Force
  $candidates|Export-Csv (Join-Path $l 'DRIVE_CANDIDATES.csv') -NoTypeInformation -Encoding UTF8
}

$summary=[ordered]@{completed_at=(Get-Date).ToString('o');computer=$env:COMPUTERNAME;role='CAD_PRODUCTION_NODE';drive_count=$candidates.Count;drives=@($candidates.DeviceID);entries=$results.Count;verified=@($results|Where-Object VERIFIED -eq $true).Count;safe_to_purge=@($results|Where-Object SAFE_TO_PURGE -eq 'YES').Count;keep_local=@($results|Where-Object DISPOSITION -eq 'KEEP_LOCAL_RECOVERY_COPY').Count;total_gb=[math]::Round((($results|Measure-Object SOURCE_BYTES -Sum).Sum)/1GB,3)}
foreach($d in $candidates){$summary|ConvertTo-Json -Depth 5|Set-Content (Join-Path (Join-Path $roots[$d.DeviceID] '99_LOGS') 'HANDOFF_SUMMARY.json') -Encoding UTF8}
Log "DONE drives=$($summary.drive_count) entries=$($summary.entries) verified=$($summary.verified) safe=$($summary.safe_to_purge) keepLocal=$($summary.keep_local) GB=$($summary.total_gb)"
Write-Output "CERTANODE_PARALLEL_CURATED_HANDOFF_COMPLETE drives=$($summary.drive_count) verified=$($summary.verified) safeToPurge=$($summary.safe_to_purge)"
