$ErrorActionPreference='Stop'

function Log([string]$Message){$line="$(Get-Date -Format s) $Message";$line|Tee-Object -FilePath $script:LogFile -Append}
function Get-TreeStats([string]$Path){if(-not(Test-Path -LiteralPath $Path)){return [pscustomobject]@{Files=0;Bytes=0}};$items=Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue;$bytes=($items|Measure-Object Length -Sum).Sum;if($null-eq$bytes){$bytes=0};[pscustomobject]@{Files=@($items).Count;Bytes=[int64]$bytes}}

# Choose the largest writable non-C filesystem volume. USB SSDs often report as Fixed rather than Removable.
$candidates=@()
try{$candidates=Get-Volume|Where-Object{$_.DriveLetter-and$_.DriveLetter-ne'C'-and$_.FileSystem}|ForEach-Object{$r="$($_.DriveLetter):\";$p=Join-Path $r '.certasurv_probe';$w=$false;try{'x'|Set-Content $p -Encoding ASCII -ErrorAction Stop;Remove-Item $p -Force;$w=$true}catch{};[pscustomobject]@{DeviceID="$($_.DriveLetter):";DriveType=$_.DriveType;Label=$_.FileSystemLabel;FileSystem=$_.FileSystem;Size=[int64]$_.Size;FreeSpace=[int64]$_.SizeRemaining;Writable=$w}}|Where-Object Writable}catch{}
if(-not$candidates){$candidates=Get-CimInstance Win32_LogicalDisk|Where-Object{$_.DeviceID-ne'C:'-and$_.FileSystem-and$_.DriveType-in 2,3}|ForEach-Object{[pscustomobject]@{DeviceID=$_.DeviceID;DriveType=$_.DriveType;Label=$_.VolumeName;FileSystem=$_.FileSystem;Size=[int64]$_.Size;FreeSpace=[int64]$_.FreeSpace;Writable=$true}}}
if(-not$candidates){throw 'No writable non-C: filesystem volume found.'}
$disk=$candidates|Sort-Object FreeSpace -Descending|Select-Object -First 1

$root=Join-Path "$($disk.DeviceID)\" 'CERTASURV_SERVER_HANDOFF'
$skills=Join-Path $root '01_SKILLS_AGENTS_WORKFLOWS'
$scripts=Join-Path $root '02_SCRIPTS_TOOLS'
$reposRoot=Join-Path $root '03_REPOS'
$kb=Join-Path $root '04_LIMITED_KNOWLEDGE_BASE'
$logs=Join-Path $root '99_LOGS'
New-Item -ItemType Directory -Force -Path $root,$skills,$scripts,$reposRoot,$kb,$logs|Out-Null
$script:LogFile=Join-Path $logs 'legacy_handoff.log'
$ledgerCsv=Join-Path $logs 'PURGE_LEDGER.csv';$ledgerJson=Join-Path $logs 'PURGE_LEDGER.json'
$candidates|Export-Csv (Join-Path $logs 'DRIVE_CANDIDATES.csv') -NoTypeInformation -Encoding UTF8
Log "START drive=$($disk.DeviceID) label=$($disk.Label) sizeGB=$([math]::Round($disk.Size/1GB,2)) freeGB=$([math]::Round($disk.FreeSpace/1GB,2))"

$ledger=@()
function Copy-Tracked([string]$Source,[string]$Destination,[string]$Category){
 if(-not(Test-Path -LiteralPath $Source)){Log "SKIP missing $Source";return}
 $before=Get-TreeStats $Source;New-Item -ItemType Directory -Force -Path $Destination|Out-Null
 & robocopy.exe $Source $Destination /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /XJ /FFT /NP /NFL /NDL /LOG+:$script:LogFile|Out-Null;$rc=$LASTEXITCODE
 $after=Get-TreeStats $Destination;$ok=($rc-le7)-and($before.Files-eq$after.Files)-and($before.Bytes-eq$after.Bytes)
 $script:ledger += [pscustomobject]@{CATEGORY=$Category;SOURCE_PATH=$Source;DESTINATION_PATH=$Destination;SOURCE_FILES=$before.Files;DEST_FILES=$after.Files;SOURCE_BYTES=$before.Bytes;DEST_BYTES=$after.Bytes;ROBOCOPY_EXIT=$rc;VERIFIED=$ok;SAFE_TO_PURGE=if($ok){'YES'}else{'NO'};COPIED_AT=(Get-Date).ToString('o')}
 Log "COPY $Category source=$Source files=$($before.Files) bytes=$($before.Bytes) verified=$ok"
}

# 1) Explicit executable/company-knowledge roots only. No bulk ChatGPT archive and no survey project data.
$roots=@(
 [pscustomobject]@{P='C:\Certa4010';D=(Join-Path $scripts 'Certa4010');C='CertaNode scripts/config'},
 [pscustomobject]@{P=(Join-Path $env:USERPROFILE '.codex\skills');D=(Join-Path $skills 'codex_skills');C='Codex skills'},
 [pscustomobject]@{P=(Join-Path $env:USERPROFILE '.codex\agents');D=(Join-Path $skills 'codex_agents');C='Codex agents'},
 [pscustomobject]@{P=(Join-Path $env:USERPROFILE '.codex\rules');D=(Join-Path $skills 'codex_rules');C='Codex rules'},
 [pscustomobject]@{P=(Join-Path $env:USERPROFILE '.codex\prompts');D=(Join-Path $skills 'codex_prompts');C='Codex prompts'}
)
foreach($x in $roots){Copy-Tracked $x.P $x.D $x.C}

# 2) Discover script/workflow/skill files in likely legacy work roots without copying unrelated binaries/data.
$scanRoots=@((Join-Path $env:USERPROFILE 'Documents\ChatGPT'),(Join-Path $env:USERPROFILE 'Documents\Codex'),(Join-Path $env:USERPROFILE 'Desktop\Codex'),(Join-Path $env:USERPROFILE 'source'))|Where-Object{Test-Path $_}
$exts=@('.ps1','.psm1','.py','.bat','.cmd','.sh','.js','.ts','.tsx','.jsx','.json','.yaml','.yml','.toml','.ini','.lsp','.scr','.sql','.md')
$keyword='skill|agent|workflow|script|automation|certacad|certard|certanode|ortho|lidar|survey|qgis|cloudcompare|webodm|appsheet|handoff|import|classif|draft|qc|validator|receipt|server|openproject|twenty|authentik'
$selected=@()
foreach($r in $scanRoots){$selected+=Get-ChildItem -LiteralPath $r -File -Recurse -Force -ErrorAction SilentlyContinue|Where-Object{$_.Extension.ToLower()-in$exts-and($_.FullName-match$keyword-or$_.Name-match$keyword)}}
$selected=$selected|Sort-Object FullName -Unique
$manifest=@()
$i=0
foreach($f in $selected){$i++;$bucket=if($f.Extension -eq '.md'){$kb}else{$scripts};$safeName=("{0:D5}_{1}" -f $i,$f.Name);$dest=Join-Path $bucket $safeName;Copy-Item -LiteralPath $f.FullName -Destination $dest -Force;$h1=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash;$h2=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash;$ok=$h1-eq$h2;$ledger+=[pscustomobject]@{CATEGORY=if($f.Extension-eq'.md'){'Curated knowledge'}else{'Selected script/workflow'};SOURCE_PATH=$f.FullName;DESTINATION_PATH=$dest;SOURCE_FILES=1;DEST_FILES=1;SOURCE_BYTES=$f.Length;DEST_BYTES=(Get-Item $dest).Length;ROBOCOPY_EXIT='';VERIFIED=$ok;SAFE_TO_PURGE=if($ok){'YES'}else{'NO'};COPIED_AT=(Get-Date).ToString('o')};$manifest+=[pscustomobject]@{Source=$f.FullName;Destination=$dest;SHA256=$h1;Bytes=$f.Length}}
$manifest|Export-Csv (Join-Path $logs 'SELECTED_FILES_MANIFEST.csv') -NoTypeInformation -Encoding UTF8

# 3) Copy Git repos as the best executable history. Still no arbitrary project folders unless they are repos.
$repoParents=@()
foreach($r in $scanRoots){$repoParents+=Get-ChildItem -LiteralPath $r -Directory -Recurse -Depth 7 -Force -ErrorAction SilentlyContinue|Where-Object{$_.Name-eq'.git'}|ForEach-Object{$_.Parent.FullName}}
$repoParents=$repoParents|Sort-Object -Unique;$repoParents|Set-Content (Join-Path $logs 'REPO_PATHS.txt') -Encoding UTF8
$n=0;foreach($repo in $repoParents){$n++;Copy-Tracked $repo (Join-Path $reposRoot ("{0:D3}_{1}" -f $n,(Split-Path $repo -Leaf))) 'Git repository'}

# 4) Curated KB index: pointers and architecture intent, not full chat/session history.
$kbIndex=@"
CERTASURV LIMITED KNOWLEDGE BASE
Generated: $(Get-Date -Format o)

Purpose: preserve only durable company knowledge required to operate/rebuild skills, agents, scripts and workflows.
Include: architecture docs, SOP/standards markdown, workflow descriptions, skill/agent definitions, configuration documentation, server/control-plane notes.
Exclude: raw ChatGPT/Codex session history, caches, model downloads, node_modules, build artifacts, raw survey data, TBC jobs, point clouds, imagery, orthos, PDFs/photos unless explicitly part of a skill/workflow package.
Execution rule: EVENT -> RULE -> SCRIPT -> AI IF NEEDED -> ACTION -> VALIDATOR -> RECEIPT.
"@
$kbIndex|Set-Content (Join-Path $kb 'README_LIMITED_KB.txt') -Encoding UTF8

$ledger|Export-Csv $ledgerCsv -NoTypeInformation -Encoding UTF8;$ledger|ConvertTo-Json -Depth 6|Set-Content $ledgerJson -Encoding UTF8
$sum=[ordered]@{completed_at=(Get-Date).ToString('o');computer=$env:COMPUTERNAME;destination_root=$root;drive=$disk.DeviceID;entries=@($ledger).Count;verified=@($ledger|Where-Object SAFE_TO_PURGE -eq 'YES').Count;unsafe=@($ledger|Where-Object SAFE_TO_PURGE -ne 'YES').Count;bytes=[int64](($ledger|Measure-Object SOURCE_BYTES -Sum).Sum);gb=[math]::Round((($ledger|Measure-Object SOURCE_BYTES -Sum).Sum)/1GB,3)}
$sum|ConvertTo-Json|Set-Content (Join-Path $logs 'HANDOFF_SUMMARY.json') -Encoding UTF8
Log "DONE entries=$($sum.entries) verified=$($sum.verified) unsafe=$($sum.unsafe) GB=$($sum.gb)"
Write-Output "CERTANODE_CURATED_HANDOFF_COMPLETE $root"
