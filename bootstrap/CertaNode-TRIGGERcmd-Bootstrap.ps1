$ErrorActionPreference='Stop'
$bridge='C:\Certa4010\TriggerBridge'
$root='C:\Certa4010'
New-Item -ItemType Directory -Force -Path $bridge,$root | Out-Null

$proof=@'
$ErrorActionPreference='Stop'
$root='C:\Certa4010'
New-Item -ItemType Directory -Force -Path $root | Out-Null
$data=[ordered]@{
  timestamp=(Get-Date).ToString('o')
  computer=$env:COMPUTERNAME
  user="$env:USERDOMAIN\$env:USERNAME"
  session=(Get-Process -Id $PID).SessionId
}
$data | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'trigger-proof.json') -Encoding UTF8
'CERTANODE_PROOF_OK'
'@
Set-Content -LiteralPath (Join-Path $bridge 'CertaNode-Proof.ps1') -Value $proof -Encoding UTF8

$health=@'
$ErrorActionPreference='SilentlyContinue'
$root='C:\Certa4010'
New-Item -ItemType Directory -Force -Path $root | Out-Null
$ollama=$false
$models=@()
try {
  $tags=Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3
  $ollama=$true
  $models=@($tags.models | ForEach-Object {$_.name})
} catch {}
$h=[ordered]@{
  timestamp=(Get-Date).ToString('o')
  computer=$env:COMPUTERNAME
  user="$env:USERDOMAIN\$env:USERNAME"
  ollama_ready=$ollama
  models=$models
  trigger_agent_running=[bool](Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue)
}
$h | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root 'health.json') -Encoding UTF8
'CERTANODE_HEALTH_OK'
'@
Set-Content -LiteralPath (Join-Path $bridge 'CertaNode-Health.ps1') -Value $health -Encoding UTF8

$boot=@'
$ErrorActionPreference='Stop'
$root='C:\Certa4010'
$logDir=Join-Path $root 'Logs'
$stageRoot=Join-Path $root 'Staging'
New-Item -ItemType Directory -Force -Path $logDir,$stageRoot | Out-Null
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$log=Join-Path $logDir "bootstrap_$stamp.log"
function Log([string]$m){ "$(Get-Date -Format s) $m" | Tee-Object -FilePath $log -Append }
$ollama=(Get-Command ollama.exe -ErrorAction SilentlyContinue).Source
if(-not $ollama){
  $candidates=@((Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'),(Join-Path $env:LOCALAPPDATA 'Ollama\ollama.exe'))
  $ollama=$candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if(-not $ollama){
  Log 'Installing Ollama from official install script.'
  $installer=Join-Path $env:TEMP 'certa-ollama-install.ps1'
  Invoke-WebRequest -UseBasicParsing -Uri 'https://ollama.com/install.ps1' -OutFile $installer
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer
  Start-Sleep -Seconds 3
  $ollama=(Get-Command ollama.exe -ErrorAction SilentlyContinue).Source
}
if($ollama){
  try { $null=Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 2 }
  catch { Start-Process -FilePath $ollama -ArgumentList 'serve' -WindowStyle Hidden; Start-Sleep -Seconds 4 }
  Log "Ollama available: $ollama"
}
$roots=@((Join-Path $env:USERPROFILE 'Downloads'),(Join-Path $env:USERPROFILE 'Desktop'),(Join-Path $root 'Inbox')) | Where-Object { Test-Path -LiteralPath $_ }
$zip=$roots | ForEach-Object { Get-ChildItem -LiteralPath $_ -Filter 'CertaShell_4010*.zip' -File -ErrorAction SilentlyContinue } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if(-not $zip){ throw 'No CertaShell ZIP found in Downloads, Desktop, or C:\Certa4010\Inbox.' }
$stage=Join-Path $stageRoot $stamp
New-Item -ItemType Directory -Force -Path $stage | Out-Null
Expand-Archive -LiteralPath $zip.FullName -DestinationPath $stage -Force
$launcher=Get-ChildItem -LiteralPath $stage -Recurse -File -Filter 'START HERE - APPLY TRUE WINDOWS 4010 SHELL.cmd' -ErrorAction SilentlyContinue | Select-Object -First 1
if(-not $launcher){ throw 'CertaShell launcher not found after extraction.' }
Start-Process -FilePath 'cmd.exe' -ArgumentList ('/c ""'+$launcher.FullName+'""') -WorkingDirectory $launcher.DirectoryName -Verb RunAs
'CERTANODE_BOOTSTRAP_STARTED'
'@
Set-Content -LiteralPath (Join-Path $bridge 'CertaNode-Bootstrap.ps1') -Value $boot -Encoding UTF8

$openrouter=@'
$ErrorActionPreference='Stop'
$uri='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/Install-CertaOpenRouter.ps1'
$dst='C:\Certa4010\TriggerBridge\Install-CertaOpenRouter.ps1'
Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $dst
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dst
exit $LASTEXITCODE
'@
Set-Content -LiteralPath (Join-Path $bridge 'CertaNode-OpenRouter.ps1') -Value $openrouter -Encoding UTF8

$gemini=@'
$ErrorActionPreference='Stop'
$uri='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/Install-CertaGemini.ps1'
$dst='C:\Certa4010\TriggerBridge\Install-CertaGemini.ps1'
Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $dst
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dst
exit $LASTEXITCODE
'@
Set-Content -LiteralPath (Join-Path $bridge 'CertaNode-Gemini.ps1') -Value $gemini -Encoding UTF8

$action=@'
[CmdletBinding()]
param([Parameter(Position=0,ValueFromRemainingArguments=$true)][string[]]$Request)
$ErrorActionPreference='Stop'
$bridge='C:\Certa4010\TriggerBridge'
$root='C:\Certa4010'
$logDir=Join-Path $root 'Logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$raw=($Request -join ' ').Trim()
if([string]::IsNullOrWhiteSpace($raw)){ throw 'CertaNode Action requires an operation.' }
$parts=$raw -split '\s+',2
$op=$parts[0].ToLowerInvariant()
$arg=if($parts.Count -gt 1){$parts[1].Trim()}else{''}
$entry=[ordered]@{timestamp=(Get-Date).ToString('o');operation=$op;argument=$arg;computer=$env:COMPUTERNAME;user="$env:USERDOMAIN\$env:USERNAME"}
$entry | ConvertTo-Json -Compress | Add-Content -LiteralPath (Join-Path $logDir 'certa-action.jsonl') -Encoding UTF8

function Parse-LatLon([string]$text){
  $p=$text -split '[, ]+' | Where-Object { $_ -ne '' }
  if($p.Count -lt 2){ throw 'Expected latitude,longitude.' }
  $lat=0.0; $lon=0.0
  if(-not [double]::TryParse($p[0],[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$lat)){ throw 'Invalid latitude.' }
  if(-not [double]::TryParse($p[1],[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$lon)){ throw 'Invalid longitude.' }
  if($lat -lt -90 -or $lat -gt 90 -or $lon -lt -180 -or $lon -gt 180){ throw 'Coordinate out of range.' }
  return @($lat,$lon)
}

switch($op){
  'health' { & (Join-Path $bridge 'CertaNode-Health.ps1'); break }
  'bootstrap' { & (Join-Path $bridge 'CertaNode-Bootstrap.ps1'); break }
  'openrouter' { & (Join-Path $bridge 'CertaNode-OpenRouter.ps1'); break }
  'gemini' { & (Join-Path $bridge 'CertaNode-Gemini.ps1'); break }
  'open-url' {
    $u=$null
    if(-not [Uri]::TryCreate($arg,[UriKind]::Absolute,[ref]$u)){ throw 'Invalid URL.' }
    if($u.Scheme -ne 'https'){ throw 'Only HTTPS URLs are allowed.' }
    Start-Process $u.AbsoluteUri
    "CERTANODE_OPENED $($u.AbsoluteUri)"
    break
  }
  'streetview' {
    $ll=Parse-LatLon $arg
    $lat=$ll[0].ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)
    $lon=$ll[1].ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)
    $url="https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$lat%2C$lon"
    Start-Process $url
    "CERTANODE_STREETVIEW_OPENED $lat,$lon"
    break
  }
  'streetview-gate1' {
    $ll=Parse-LatLon $arg
    $uri='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/CertaStreetView-Gate1.ps1'
    $dst=Join-Path $bridge 'CertaStreetView-Gate1.ps1'
    Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $dst
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dst -Latitude $ll[0] -Longitude $ll[1]
    exit $LASTEXITCODE
  }
  default { throw "Operation '$op' is not allowlisted." }
}
'@
Set-Content -LiteralPath (Join-Path $bridge 'CertaNode-Action.ps1') -Value $action -Encoding UTF8

$cfgDir=Join-Path $env:USERPROFILE '.TRIGGERcmdData'
$cfg=Join-Path $cfgDir 'commands.json'
if(-not (Test-Path -LiteralPath $cfg)){ throw "TRIGGERcmd commands file not found: $cfg" }
$backup="$cfg.certa_backup_$(Get-Date -Format yyyyMMdd_HHmmss)"
Copy-Item -LiteralPath $cfg -Destination $backup -Force
$items=@()
$raw=Get-Content -LiteralPath $cfg -Raw
if(-not [string]::IsNullOrWhiteSpace($raw)){ $items=@($raw | ConvertFrom-Json) }
$names=@('CertaNode Proof','CertaNode Health','CertaNode Bootstrap','CertaNode OpenRouter','CertaNode Gemini','CertaNode Action')
$items=@($items | Where-Object { $_.trigger -notin $names })
$items += [pscustomobject]@{trigger='CertaNode Proof';command='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Certa4010\TriggerBridge\CertaNode-Proof.ps1"';offCommand='';ground='foreground';voice='certa node proof';voiceReply='';allowParams='false'}
$items += [pscustomobject]@{trigger='CertaNode Health';command='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Certa4010\TriggerBridge\CertaNode-Health.ps1"';offCommand='';ground='foreground';voice='certa node health';voiceReply='';allowParams='false'}
$items += [pscustomobject]@{trigger='CertaNode Bootstrap';command='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Certa4010\TriggerBridge\CertaNode-Bootstrap.ps1"';offCommand='';ground='foreground';voice='certa node bootstrap';voiceReply='';allowParams='false'}
$items += [pscustomobject]@{trigger='CertaNode OpenRouter';command='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Certa4010\TriggerBridge\CertaNode-OpenRouter.ps1"';offCommand='';ground='foreground';voice='certa node open router';voiceReply='';allowParams='false'}
$items += [pscustomobject]@{trigger='CertaNode Gemini';command='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Certa4010\TriggerBridge\CertaNode-Gemini.ps1"';offCommand='';ground='foreground';voice='certa node gemini';voiceReply='';allowParams='false'}
$items += [pscustomobject]@{trigger='CertaNode Action';command='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Certa4010\TriggerBridge\CertaNode-Action.ps1"';offCommand='';ground='foreground';voice='certa node action';voiceReply='';allowParams='true'}
$items | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $cfg -Encoding UTF8
$null=Get-Content -LiteralPath $cfg -Raw | ConvertFrom-Json

$agent=Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue | Select-Object -First 1
if($agent){
  $agentPath=$null
  try { $agentPath=$agent.Path } catch {}
  if($agentPath -and (Test-Path -LiteralPath $agentPath)){
    Stop-Process -Id $agent.Id -Force
    Start-Sleep -Seconds 2
    Start-Process -FilePath $agentPath
  }
}
Write-Output "CERTANODE_TRIGGER_BRIDGE_READY $backup PARAM_ACTION=true"
