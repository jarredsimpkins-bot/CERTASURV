#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [string]$Repository = 'jarredsimpkins-bot/CERTASURV',
    [string]$Ref = 'feat/certa-server-router-v1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$stage = Join-Path $env:TEMP ('certa-trigger-repair-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null

try {
    $scriptPath = Join-Path $stage 'Install-CertaServer-TriggerCommands.ps1'
    $url = "https://raw.githubusercontent.com/$Repository/$Ref/server/trigger/Install-CertaServer-TriggerCommands.ps1"
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $scriptPath

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -ServerRoot $ServerRoot
    exit $LASTEXITCODE
}
finally {
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
}
