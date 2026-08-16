[CmdletBinding()]
param()
$ErrorActionPreference='Stop'

$bridge='C:\Certa4010\TriggerBridge'
New-Item -ItemType Directory -Force -Path $bridge | Out-Null

$bootstrapUrl='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/CertaNode-TRIGGERcmd-Bootstrap.ps1'
$bootstrap=Join-Path $bridge 'CertaNode-TRIGGERcmd-Bootstrap.ps1'
Invoke-WebRequest -UseBasicParsing -Uri $bootstrapUrl -OutFile $bootstrap
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrap
if($LASTEXITCODE -ne 0){ throw "Latest bridge bootstrap failed with exit code $LASTEXITCODE" }

$refresh=@'
$ErrorActionPreference='Stop'
$uri='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/CertaNode-TRIGGERcmd-Bootstrap.ps1'
$dst='C:\Certa4010\TriggerBridge\CertaNode-TRIGGERcmd-Bootstrap.ps1'
Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $dst
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dst
exit $LASTEXITCODE
'@
$refreshPath=Join-Path $bridge 'CertaNode-Refresh.ps1'
Set-Content -LiteralPath $refreshPath -Value $refresh -Encoding UTF8

$cfg=Join-Path $env:USERPROFILE '.TRIGGERcmdData\commands.json'
if(-not (Test-Path -LiteralPath $cfg)){ throw "TRIGGERcmd commands file not found: $cfg" }
$backup="$cfg.changeable_backup_$(Get-Date -Format yyyyMMdd_HHmmss)"
Copy-Item -LiteralPath $cfg -Destination $backup -Force
$items=@((Get-Content -LiteralPath $cfg -Raw) | ConvertFrom-Json)
$items=@($items | Where-Object { $_.trigger -ne 'CertaNode Bridge' })
$items += [pscustomobject]@{
  trigger='CertaNode Bridge'
  command='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Certa4010\TriggerBridge\CertaNode-Refresh.ps1"'
  offCommand=''
  ground='foreground'
  voice='certa node bridge'
  voiceReply=''
  allowParams='false'
}
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
    Start-Sleep -Seconds 3
  }
}

Write-Output "CERTANODE_CHANGEABLE_READY backup=$backup"
Write-Output 'Expected trigger: CertaNode Action (allowParams=true)'
Write-Output 'Examples: health | streetview 38.2856,-82.1055 | streetview-gate1 38.2856,-82.1055 | open-url https://example.com'
