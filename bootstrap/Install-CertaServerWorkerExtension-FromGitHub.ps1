#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [string]$Repository = 'jarredsimpkins-bot/CERTASURV',

    [string]$Ref = 'feat/certa-server-router-v1',

    [switch]$SkipModelPull,

    [switch]$SkipTriggerCommands,

    [switch]$SkipStartup,

    [switch]$KeepSleepSettings
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$stage = Join-Path $env:TEMP ('certa-server-worker-bootstrap-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null

try {
    $baseBootstrap = Join-Path $stage 'Install-CertaServer-FromGitHub.ps1'
    $extensionInstaller = Join-Path $stage 'Install-CertaServerWorkerExtension.ps1'
    $baseUrl = "https://raw.githubusercontent.com/$Repository/$Ref/bootstrap/Install-CertaServer-FromGitHub.ps1"
    $extensionUrl = "https://raw.githubusercontent.com/$Repository/$Ref/server/worker/Install-CertaServerWorkerExtension.ps1"
    Invoke-WebRequest -UseBasicParsing -Uri $baseUrl -OutFile $baseBootstrap
    Invoke-WebRequest -UseBasicParsing -Uri $extensionUrl -OutFile $extensionInstaller

    $baseArguments = @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',$baseBootstrap,
        '-ServerRoot',$ServerRoot,
        '-Repository',$Repository,
        '-Ref',$Ref
    )
    if (-not $SkipModelPull) { $baseArguments += '-PullModel' }
    if (-not $KeepSleepSettings) { $baseArguments += '-DisableSleepOnAC' }
    & powershell.exe @baseArguments
    if ($LASTEXITCODE -ne 0) { throw "Base Certa server bootstrap failed with exit code $LASTEXITCODE." }

    $extensionArguments = @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',$extensionInstaller,
        '-ServerRoot',$ServerRoot
    )
    if (-not $SkipTriggerCommands) { $extensionArguments += '-InstallTriggerCommands' }
    if (-not $SkipStartup) { $extensionArguments += '-RegisterStartup' }
    if (-not $KeepSleepSettings) { $extensionArguments += '-DisableSleepOnAC' }
    & powershell.exe @extensionArguments
    if ($LASTEXITCODE -ne 0) { throw "Queue worker extension failed with exit code $LASTEXITCODE." }

    [pscustomobject]@{
        status = 'PASS'
        server_root = $ServerRoot
        repository = $Repository
        ref = $Ref
        next = 'Restart the TRIGGERcmd tray agent, then run the Certa Server Health and Certa Server Queue Status commands.'
    }
}
finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
