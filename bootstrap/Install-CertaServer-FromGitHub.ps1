#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [string]$Repository = 'jarredsimpkins-bot/CERTASURV',
    [string]$Ref = 'main',
    [switch]$PullModel,
    [switch]$InstallTriggerCommands,
    [switch]$DisableSleepOnAC
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$stage = Join-Path $env:TEMP ('certa-server-bootstrap-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null

try {
    $files = @(
        'server/Install-CertaServer.ps1',
        'server/router/New-CertaTask.ps1',
        'server/router/Invoke-CertaRouter.ps1',
        'server/router/Invoke-CertaOllamaTask.ps1',
        'server/router/Get-CertaServerHealth.ps1',
        'server/router/Test-CertaRouter.ps1',
        'server/policies/task-routing-policy.json',
        'server/schemas/task.schema.json',
        'server/trigger/Install-CertaServer-TriggerCommands.ps1',
        'server/capabilities/New-CertaFileManifest.ps1'
    )

    foreach ($path in $files) {
        $destination = Join-Path $stage ($path -replace '/', '\')
        $parent = Split-Path -Parent $destination
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        $url = "https://raw.githubusercontent.com/$Repository/$Ref/$path"
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $destination
    }

    $installer = Join-Path $stage 'server\Install-CertaServer.ps1'
    $arguments = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$installer,'-ServerRoot',$ServerRoot)
    if ($PullModel) { $arguments += '-PullModel' }
    if ($InstallTriggerCommands) { $arguments += '-InstallTriggerCommands' }
    if ($DisableSleepOnAC) { $arguments += '-DisableSleepOnAC' }
    & powershell.exe @arguments
    exit $LASTEXITCODE
}
finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
