[CmdletBinding()]
param()
$ErrorActionPreference='Stop'

$bridge='C:\Certa4010\TriggerBridge'
$cfgDir=Join-Path $env:USERPROFILE '.TRIGGERcmdData'
$cfg=Join-Path $cfgDir 'commands.json'
$backupJson=Join-Path $cfgDir 'commands.json.backup'
New-Item -ItemType Directory -Force -Path $bridge,$cfgDir | Out-Null

$agent=Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue | Select-Object -First 1
$agentPath=$null
if($agent){
  try { $agentPath=$agent.Path } catch {}
  Stop-Process -Id $agent.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
}

if(Test-Path -LiteralPath $cfg){
  Copy-Item -LiteralPath $cfg -Destination ($cfg+'.pre_force_'+(Get-Date -Format yyyyMMdd_HHmmss)) -Force
}

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
[ordered]@{timestamp=(Get-Date).ToString('o');operation=$op;argument=$arg;computer=$env:COMPUTERNAME} | ConvertTo-Json -Compress | Add-Content -LiteralPath (Join-Path $logDir 'certa-action.jsonl') -Encoding UTF8
function Parse-LatLon([string]$text){
  $p=$text -split '[, ]+' | Where-Object { $_ -ne '' }
  if($p.Count -lt 2){ throw 'Expected latitude,longitude.' }
  $lat=0.0; $lon=0.0
  if(-not [double]::TryParse($p[0],[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$lat)){ throw 'Invalid latitude.' }
  if(-not [double]::TryParse($p[1],[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$lon)){ throw 'Invalid longitude.' }
  if($lat -lt -90 -or $lat -gt 90 -or $lon -lt -180 -or $lon -gt 180){ throw 'Coordinate out of range.' }
  @($lat,$lon)
}
switch($op){
  'health' {
    $out=[ordered]@{timestamp=(Get-Date).ToString('o');computer=$env:COMPUTERNAME;user="$env:USERDOMAIN\$env:USERNAME";trigger_agent=[bool](Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue);edge=(Get-Command msedge.exe -ErrorAction SilentlyContinue).Source}
    $out | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $root 'health.json') -Encoding UTF8
    'CERTANODE_HEALTH_OK'; break
  }
  'open-url' {
    $u=$null
    if(-not [Uri]::TryCreate($arg,[UriKind]::Absolute,[ref]$u)){ throw 'Invalid URL.' }
    if($u.Scheme -ne 'https'){ throw 'Only HTTPS URLs are allowed.' }
    Start-Process $u.AbsoluteUri
    "CERTANODE_OPENED $($u.AbsoluteUri)"; break
  }
  'streetview' {
    $ll=Parse-LatLon $arg
    $lat=$ll[0].ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)
    $lon=$ll[1].ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)
    $url="https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$lat%2C$lon"
    Start-Process $url
    "CERTANODE_STREETVIEW_OPENED $lat,$lon"; break
  }
  'streetview-gate1' {
    $ll=Parse-LatLon $arg
    $uri='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/CertaStreetView-Gate1.ps1'
    $dst=Join-Path $bridge 'CertaStreetView-Gate1.ps1'
    Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $dst
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dst -Latitude $ll[0] -Longitude $ll[1]
    exit $LASTEXITCODE
  }
  'refresh' {
    $uri='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/Force-CertaNode-Action-Repair.ps1'
    $dst=Join-Path $bridge 'Force-CertaNode-Action-Repair.ps1'
    Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $dst
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dst
    exit $LASTEXITCODE
  }
  default { throw "Operation '$op' is not allowlisted." }
}
'@
$actionPath=Join-Path $bridge 'CertaNode-Action.ps1'
Set-Content -LiteralPath $actionPath -Value $action -Encoding UTF8

$refresh=@'
$ErrorActionPreference='Stop'
$uri='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/Force-CertaNode-Action-Repair.ps1'
$dst='C:\Certa4010\TriggerBridge\Force-CertaNode-Action-Repair.ps1'
Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $dst
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dst
exit $LASTEXITCODE
'@
Set-Content -LiteralPath (Join-Path $bridge 'CertaNode-Refresh.ps1') -Value $refresh -Encoding UTF8

$items=@(
  [ordered]@{trigger='Calculator';command='calc';offCommand='';ground='foreground';voice='calculator';voiceReply='';allowParams='true'},
  [ordered]@{trigger='Notepad';command='notepad';offCommand='';ground='foreground';voice='notepad';voiceReply='';allowParams='true'},
  [ordered]@{trigger='CertaNode Bridge';command='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Certa4010\TriggerBridge\CertaNode-Refresh.ps1"';offCommand='';ground='foreground';voice='certa node bridge';voiceReply='';allowParams='false'},
  [ordered]@{trigger='CertaNode Action';command='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Certa4010\TriggerBridge\CertaNode-Action.ps1"';offCommand='';ground='foreground';voice='certa node action';voiceReply='';allowParams='true'}
)
$json=$items | ConvertTo-Json -Depth 8
$null=$json | ConvertFrom-Json
Set-Content -LiteralPath $cfg -Value $json -Encoding UTF8
Set-Content -LiteralPath $backupJson -Value $json -Encoding UTF8

if(-not $agentPath){
  $candidate=Get-ChildItem "$env:LOCALAPPDATA\Programs" -Recurse -Filter 'TRIGGERcmdAgent.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
  if($candidate){ $agentPath=$candidate.FullName }
}
if($agentPath -and (Test-Path -LiteralPath $agentPath)){
  Start-Process -FilePath $agentPath
  Start-Sleep -Seconds 6
}

$status=[ordered]@{timestamp=(Get-Date).ToString('o');config=$cfg;action_exists=(Test-Path $actionPath);agent_path=$agentPath;json_valid=$true}
$status | ConvertTo-Json | Set-Content -LiteralPath 'C:\Certa4010\TriggerBridge\FORCE_REPAIR_STATUS.json' -Encoding UTF8
Write-Output 'CERTANODE_FORCE_REPAIR_READY'
Write-Output $cfg
