#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [string]$Repository = 'jarredsimpkins-bot/CERTASURV',
    [string]$Ref = 'main',
    [string]$LocalModel = 'qwen3.5:4b',
    [switch]$PullModel,
    [switch]$InstallTriggerCommands,
    [switch]$InstallScheduledTasks,
    [switch]$CloneControlRepo,
    [switch]$DisableSleepOnAC
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$stage = Join-Path $env:TEMP ('certa-server-autonomy-v2-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null

try {
    $bundleName = 'certa-server-autonomy-v2.zip'
    $manifestName = 'certa-server-autonomy-v2.manifest.json'
    $bundleUrl = "https://raw.githubusercontent.com/$Repository/$Ref/server/bundles/$bundleName"
    $manifestUrl = "https://raw.githubusercontent.com/$Repository/$Ref/server/bundles/$manifestName"
    $bundlePath = Join-Path $stage $bundleName
    $manifestPath = Join-Path $stage $manifestName

    Invoke-WebRequest -UseBasicParsing -Uri $manifestUrl -OutFile $manifestPath
    Invoke-WebRequest -UseBasicParsing -Uri $bundleUrl -OutFile $bundlePath

    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $actualHash = (Get-FileHash -LiteralPath $bundlePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne ([string]$manifest.sha256).ToLowerInvariant()) {
        throw "Bundle SHA256 mismatch. Expected $($manifest.sha256); got $actualHash."
    }
    if ((Get-Item -LiteralPath $bundlePath).Length -ne [int64]$manifest.size_bytes) {
        throw 'Bundle size does not match the signed manifest.'
    }

    $expanded = Join-Path $stage 'expanded'
    Expand-Archive -LiteralPath $bundlePath -DestinationPath $expanded -Force
    foreach ($relativePath in @($manifest.files)) {
        if (-not (Test-Path -LiteralPath (Join-Path $expanded ([string]$relativePath)))) {
            throw "Bundle is missing manifest file: $relativePath"
        }
    }

    $installer = Join-Path $expanded 'server\Install-CertaServer.ps1'
    $arguments = @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',$installer,
        '-ServerRoot',$ServerRoot,
        '-LocalModel',$LocalModel
    )
    if ($PullModel) { $arguments += '-PullModel' }
    if ($InstallTriggerCommands) { $arguments += '-InstallTriggerCommands' }
    if ($InstallScheduledTasks) { $arguments += '-InstallScheduledTasks' }
    if ($CloneControlRepo) { $arguments += '-CloneControlRepo' }
    if ($DisableSleepOnAC) { $arguments += '-DisableSleepOnAC' }

    & powershell.exe @arguments
    exit $LASTEXITCODE
}
finally {
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
}
