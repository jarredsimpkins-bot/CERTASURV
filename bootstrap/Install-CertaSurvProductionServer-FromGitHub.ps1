#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [string]$Repository = 'jarredsimpkins-bot/CERTASURV',
    [string]$Ref = 'main',
    [switch]$SkipModelPull,
    [switch]$SkipTriggerCommands,
    [switch]$SkipStartup,
    [switch]$KeepSleepSettings,
    [switch]$SkipSelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$stage = Join-Path $env:TEMP ('certa-production-server-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null

try {
    $workerBootstrap = Join-Path $stage 'Install-CertaServerWorkerExtension-FromGitHub.ps1'
    $workerUrl = "https://raw.githubusercontent.com/$Repository/$Ref/bootstrap/Install-CertaServerWorkerExtension-FromGitHub.ps1"
    Invoke-WebRequest -UseBasicParsing -Uri $workerUrl -OutFile $workerBootstrap

    $workerArguments = @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',$workerBootstrap,
        '-ServerRoot',$ServerRoot,
        '-Repository',$Repository,
        '-Ref',$Ref
    )
    if ($SkipModelPull) { $workerArguments += '-SkipModelPull' }
    $workerArguments += '-SkipTriggerCommands'
    if ($SkipStartup) { $workerArguments += '-SkipStartup' }
    if ($KeepSleepSettings) { $workerArguments += '-KeepSleepSettings' }

    & powershell.exe @workerArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Base router/worker installation failed with exit code $LASTEXITCODE."
    }

    $productionFolder = Join-Path $stage 'production'
    New-Item -ItemType Directory -Path $productionFolder -Force | Out-Null
    $productionFiles = @(
        'CertaServer.Common.ps1',
        'Initialize-CertaProjectTask.ps1',
        'New-CertaCourthousePacketTask.ps1',
        'New-CertaDeedPlotTask.ps1',
        'New-CertaWorkmapTask.ps1',
        'Update-CertaFieldReturnTask.ps1',
        'Test-CertaProductionCapabilities.ps1',
        'Install-CertaProductionCapabilities.ps1',
        'Install-CertaProductionTriggerCommands.ps1'
    )
    foreach ($name in $productionFiles) {
        $url = "https://raw.githubusercontent.com/$Repository/$Ref/server/production/$name"
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile (Join-Path $productionFolder $name)
    }

    $installer = Join-Path $productionFolder 'Install-CertaProductionCapabilities.ps1'
    $productionArguments = @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',$installer,
        '-ServerRoot',$ServerRoot
    )
    if ($SkipSelfTest) { $productionArguments += '-SkipSelfTest' }
    if ($SkipTriggerCommands) { $productionArguments += '-SkipTriggerCommands' }
    & powershell.exe @productionArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Production-capability installation failed with exit code $LASTEXITCODE."
    }

    [pscustomobject]@{
        status='PASS'
        server_root=$ServerRoot
        repository=$Repository
        ref=$Ref
        installed=@(
            'base-router',
            'queue-worker',
            'certard-local',
            'project-intake-v1',
            'courthouse-packet-v1',
            'deed-plot-v1',
            'workmap-build-v1',
            'field-return-v1',
            'production-trigger-commands'
        )
        next='Run Certa Server Health, Certa Server Production Test, then submit a noncritical project-intake task.'
    }
}
finally {
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
}
