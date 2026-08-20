#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [string]$LocalModel = 'qwen3.5:4b',

    [string]$SourceRepository = 'local-checkout',

    [string]$SourceCommit,

    [switch]$PullModel,

    [switch]$InstallTriggerCommands,

    [switch]$DisableSleepOnAC,

    [switch]$RunSmokeTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-CertaInstallJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$Depth = 12
    )
    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $temporaryPath = Join-Path $parent ('.{0}.{1}.tmp' -f ([IO.Path]::GetFileName($Path)),[guid]::NewGuid().ToString('N'))
    try {
        $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
        $null = Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
    }
}

$ServerRoot = [IO.Path]::GetFullPath($ServerRoot).TrimEnd('\')
if ($ServerRoot -notmatch '^[A-Za-z]:\\' -or $ServerRoot.IndexOfAny([char[]]@('"',"`r","`n",'%','!')) -ge 0) {
    throw 'ServerRoot must be a fully qualified local drive path without shell-expansion characters.'
}
if (-not [string]::IsNullOrWhiteSpace($SourceCommit) -and $SourceCommit -notmatch '^[a-fA-F0-9]{40}$') {
    throw 'SourceCommit must be an immutable 40-character Git commit SHA when supplied.'
}
$started = Get-Date
$runId = 'certa-server-install-{0:yyyyMMdd-HHmmssfff}-{1}' -f $started, ([guid]::NewGuid().ToString('N').Substring(0,8))

$sourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$requiredSourceFolders = @('router','policies','schemas','trigger','capabilities')
foreach ($name in $requiredSourceFolders) {
    if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $name))) {
        throw "Required installer source folder is missing: $name"
    }
}

$folders = @(
    'CONTROL\policies','CONTROL\registries','CONTROL\schemas','CONTROL\manifests','CONTROL\receipts','CONTROL\backups',
    'INBOX','QUEUE\script','QUEUE\ollama','QUEUE\codex','QUEUE\specialist','QUEUE\review',
    'PROJECT_LINKS','REPOS','WORKTREES','WORKING','ROUTER','SCRIPTS','SKILLS','OLLAMA\models','OLLAMA\config',
    'OUTPUTS','RECEIPTS\routing','RECEIPTS\ollama','RECEIPTS\health','LOGS','STAGING\router','QUARANTINE','ARCHIVE\tasks','BACKUPS'
)
foreach ($relative in $folders) {
    New-Item -ItemType Directory -Path (Join-Path $ServerRoot $relative) -Force | Out-Null
}

$manifestPath = Join-Path $ServerRoot 'CONTROL\manifests\server-manifest.json'
$attemptReceiptPath = Join-Path $ServerRoot "CONTROL\receipts\$runId-attempt.json"
$attemptRecord = [ordered]@{
    schema_version = 1
    run_id = $runId
    started_at = ([DateTimeOffset]$started).ToUniversalTime().ToString('o')
    completed_at = $null
    status = 'RUNNING'
    server_root = $ServerRoot
    source_repository = $SourceRepository
    source_commit = if ([string]::IsNullOrWhiteSpace($SourceCommit)) { $null } else { $SourceCommit }
    manifest = $manifestPath
    error = $null
}
try {
Write-CertaInstallJson -Value $attemptRecord -Path $attemptReceiptPath
$runningManifest = [ordered]@{
    schema_version = 1
    run_id = $runId
    started_at = $attemptRecord.started_at
    completed_at = $null
    computer = $env:COMPUTERNAME
    user = "$env:USERDOMAIN\$env:USERNAME"
    server_root = $ServerRoot
    source_repository = $SourceRepository
    source_commit = if ([string]::IsNullOrWhiteSpace($SourceCommit)) { $null } else { $SourceCommit }
    attempt_receipt = $attemptReceiptPath
    status = 'RUNNING'
    error = $null
}
Write-CertaInstallJson -Value $runningManifest -Path $manifestPath -Depth 12

Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\New-CertaTask.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\New-CertaTask.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\Invoke-CertaRouter.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\Invoke-CertaOllamaTask.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\Invoke-CertaOllamaTask.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\Get-CertaServerHealth.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\Get-CertaServerHealth.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\Test-CertaServerEndToEnd.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\Test-CertaServerEndToEnd.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\Publish-CertaServerStatus.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\Publish-CertaServerStatus.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\Test-CertaTaskRecord.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\Test-CertaTaskRecord.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'policies\task-routing-policy.json') -Destination (Join-Path $ServerRoot 'CONTROL\policies\task-routing-policy.json') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'schemas\task.schema.json') -Destination (Join-Path $ServerRoot 'CONTROL\schemas\task.schema.json') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'capabilities\New-CertaFileManifest.ps1') -Destination (Join-Path $ServerRoot 'SCRIPTS\New-CertaFileManifest.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'capabilities\Test-CertaFileManifest.ps1') -Destination (Join-Path $ServerRoot 'SCRIPTS\Test-CertaFileManifest.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'capabilities\Update-CertaCapabilityRegistry.ps1') -Destination (Join-Path $ServerRoot 'SCRIPTS\Update-CertaCapabilityRegistry.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'trigger\Install-CertaServer-TriggerCommands.ps1') -Destination (Join-Path $ServerRoot 'CONTROL\Install-CertaServer-TriggerCommands.ps1') -Force

$capabilityRegistryResult = & (Join-Path $ServerRoot 'SCRIPTS\Update-CertaCapabilityRegistry.ps1') -ServerRoot $ServerRoot

$ollamaCommand = Get-Command ollama.exe -ErrorAction SilentlyContinue
$ollamaExe = if ($ollamaCommand) { [string]$ollamaCommand.Source } else { $null }
if (-not $ollamaExe) {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'),
        (Join-Path $env:LOCALAPPDATA 'Ollama\ollama.exe')
    )
    $ollamaExe = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $ollamaExe) { throw 'Ollama was not found. Install Ollama under this Windows profile and rerun.' }

$ollamaSettings = [ordered]@{
    OLLAMA_MODELS = (Join-Path $ServerRoot 'OLLAMA\models')
    OLLAMA_HOST = '127.0.0.1:11434'
    OLLAMA_MAX_LOADED_MODELS = '1'
    OLLAMA_NUM_PARALLEL = '1'
    OLLAMA_MAX_QUEUE = '64'
    OLLAMA_KEEP_ALIVE = '10m'
    OLLAMA_CONTEXT_LENGTH = '8192'
    OLLAMA_NO_CLOUD = '1'
}
foreach ($entry in $ollamaSettings.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($entry.Key,[string]$entry.Value,'User')
    Set-Item -Path "Env:$($entry.Key)" -Value ([string]$entry.Value)
}
$ollamaSettings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $ServerRoot 'OLLAMA\config\effective-settings.json') -Encoding UTF8

if ($DisableSleepOnAC) {
    & powercfg.exe /change standby-timeout-ac 0 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'powercfg failed to disable sleep on AC power. Run the installer from an elevated PowerShell session.' }
}

# Restart Ollama so the new user-scoped model path and concurrency settings take effect.
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^ollama' } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process -FilePath $ollamaExe -ArgumentList 'serve' -WindowStyle Hidden | Out-Null
$apiReady = $false
$deadline = (Get-Date).AddSeconds(45)
do {
    Start-Sleep -Seconds 2
    try { $null = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 5; $apiReady=$true } catch {}
} while (-not $apiReady -and (Get-Date) -lt $deadline)
if (-not $apiReady) { throw 'Ollama did not become healthy on localhost after restart.' }

if ($PullModel) {
    & $ollamaExe pull $LocalModel
    if ($LASTEXITCODE -ne 0) { throw "Failed to pull Ollama model $LocalModel" }
}

$modelfilePath = Join-Path $ServerRoot 'OLLAMA\config\Modelfile.certard-local'
$modelfile = @"
FROM $LocalModel
PARAMETER temperature 0.15
PARAMETER top_p 0.9
PARAMETER num_ctx 8192
SYSTEM """
You are CERTARD Local, the low-cost private worker inside the CertaSurv task router.
You may classify, extract, summarize, tag, explain, and propose safe next steps.
Prefer a verified SCRIPT over AI. Use CODEX for new code, debugging, integration, migration, or repository changes.
Use SPECIALIST for TBC, Land Desktop, CAD, or hardware-specific work on another approved node.
Use HUMAN for professional survey judgment, legal authority, credentials, destructive action, or production release.
Your output is candidate information only and never automatically authoritative survey evidence.
"""
"@
Set-Content -LiteralPath $modelfilePath -Value $modelfile -Encoding UTF8
& $ollamaExe create certard-local -f $modelfilePath
if ($LASTEXITCODE -ne 0) { throw 'Failed to create the certard-local model alias.' }

$testResult = & (Join-Path $sourceRoot 'router\Test-CertaRouter.ps1') 2>&1 | Out-String
if ($testResult -notmatch 'CERTA_ROUTER_TEST_PASS') {
    throw "Router self-test failed.`n$testResult"
}

$smokeResult = $null
if ($RunSmokeTest) {
    $smokeResult = & (Join-Path $ServerRoot 'ROUTER\Test-CertaServerEndToEnd.ps1') -ServerRoot $ServerRoot -NoExitCode
}

$triggerResult = $null
$statusBeaconResult = $null
if ($InstallTriggerCommands -and $RunSmokeTest -and [string]$smokeResult.status -eq 'PASS') {
    $triggerResult = & (Join-Path $ServerRoot 'CONTROL\Install-CertaServer-TriggerCommands.ps1') -ServerRoot $ServerRoot
    # Let the foreground watcher consume/re-arm after the fixed-command update
    # before replacing the catalog again with the fresh status beacon.
    Start-Sleep -Seconds 2
    $statusBeaconResult = & (Join-Path $ServerRoot 'ROUTER\Publish-CertaServerStatus.ps1') -ServerRoot $ServerRoot
}

$gateFailures = New-Object System.Collections.Generic.List[string]
if ($RunSmokeTest -and [string]$smokeResult.status -ne 'PASS') {
    $gateFailures.Add('End-to-end router/Ollama smoke test did not pass.')
}
if ($InstallTriggerCommands) {
    if (-not $RunSmokeTest) { $gateFailures.Add('TriggerCMD launch registration requires -RunSmokeTest.') }
    if ($null -eq $triggerResult) { $gateFailures.Add('TriggerCMD command registration was not performed because a local launch prerequisite failed.') }
    else {
        if ([string]$triggerResult.status -ne 'PASS') { $gateFailures.Add('TriggerCMD command registration did not pass.') }
        if (-not [bool]$triggerResult.agent_running) { $gateFailures.Add('Exactly one TriggerCMD foreground agent is not running in the current session.') }
        if (-not [bool]$triggerResult.catalog_change_signaled) { $gateFailures.Add('TriggerCMD registration did not signal the live catalog watcher.') }
    }
    if ($null -eq $statusBeaconResult) { $gateFailures.Add('The local status beacon was not published because a local launch prerequisite failed.') }
    else {
        if ([string]$statusBeaconResult.health -ne 'PASS') { $gateFailures.Add("Final health beacon is $($statusBeaconResult.health), not PASS.") }
        if ([string]$statusBeaconResult.smoke -ne 'PASS') { $gateFailures.Add("Published smoke beacon is $($statusBeaconResult.smoke), not PASS.") }
        if ([string]$statusBeaconResult.smoke_run_id -ne [string]$smokeResult.run_id) { $gateFailures.Add('Published smoke beacon does not match this installer smoke run.') }
        if (-not [bool]$statusBeaconResult.trigger_agent_running) { $gateFailures.Add('Status publisher did not observe exactly one TriggerCMD foreground agent in the current session.') }
        if (-not [bool]$statusBeaconResult.catalog_change_signaled) { $gateFailures.Add('Status publisher did not signal the live TriggerCMD catalog watcher.') }
    }
}
$installStatus = if ($gateFailures.Count -eq 0) { 'PASS' } else { 'FAIL' }

$manifest = [ordered]@{
    schema_version = 1
    run_id = $runId
    installed_at = (Get-Date).ToUniversalTime().ToString('o')
    computer = $env:COMPUTERNAME
    user = "$env:USERDOMAIN\$env:USERNAME"
    server_root = $ServerRoot
    source_repository = $SourceRepository
    source_commit = if ([string]::IsNullOrWhiteSpace($SourceCommit)) { $null } else { $SourceCommit }
    ollama_executable = $ollamaExe
    local_model = $LocalModel
    local_alias = 'certard-local'
    capability_registry = $capabilityRegistryResult
    trigger = $triggerResult
    router_test = 'PASS'
    smoke_test = $smokeResult
    status_beacon = $statusBeaconResult
    gate_failures = $gateFailures
    attempt_receipt = $attemptReceiptPath
    status = $installStatus
}
Write-CertaInstallJson -Value $manifest -Path $manifestPath -Depth 12
$receiptPath = Join-Path $ServerRoot "CONTROL\receipts\$runId.json"
Write-CertaInstallJson -Value $manifest -Path $receiptPath -Depth 12

if ($installStatus -ne 'PASS') {
    throw "Certa server launch gates failed: $($gateFailures -join ' ') See receipts under $(Join-Path $ServerRoot 'RECEIPTS')."
}

$attemptRecord.status = 'PASS'
$attemptRecord.completed_at = [DateTimeOffset]::UtcNow.ToString('o')
$attemptRecord.manifest = $manifestPath
Write-CertaInstallJson -Value $attemptRecord -Path $attemptReceiptPath

[pscustomobject]@{
    status=$installStatus
    server_root=$ServerRoot
    manifest=$manifestPath
    receipt=$receiptPath
    source_commit=$manifest.source_commit
    next=("Create a task with {0}, then route it with {1}." -f (Join-Path $ServerRoot 'ROUTER\New-CertaTask.ps1'),(Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1'))
}
}
catch {
    $installFailure = $_
    $failureCompletedAt = [DateTimeOffset]::UtcNow.ToString('o')
    try {
        $attemptRecord.status = 'FAIL'
        $attemptRecord.completed_at = $failureCompletedAt
        $attemptRecord.error = [string]$installFailure.Exception.Message
        Write-CertaInstallJson -Value $attemptRecord -Path $attemptReceiptPath
    }
    catch {}
    try {
        $failureManifest = [ordered]@{
            schema_version = 1
            run_id = $runId
            started_at = $attemptRecord.started_at
            completed_at = $failureCompletedAt
            computer = $env:COMPUTERNAME
            user = "$env:USERDOMAIN\$env:USERNAME"
            server_root = $ServerRoot
            source_repository = $SourceRepository
            source_commit = if ([string]::IsNullOrWhiteSpace($SourceCommit)) { $null } else { $SourceCommit }
            attempt_receipt = $attemptReceiptPath
            status = 'FAIL'
            error = [string]$installFailure.Exception.Message
        }
        Write-CertaInstallJson -Value $failureManifest -Path $manifestPath -Depth 12
    }
    catch {}
    throw $installFailure
}
