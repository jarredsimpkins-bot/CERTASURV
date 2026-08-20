#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [string]$LocalModel = 'qwen3.5:4b',

    [string]$SourceRepository = 'local-checkout',

    [string]$SourceCommit,

    [switch]$PullModel,

    [switch]$InstallTriggerCommands,

    [switch]$DisableSleepOnAC
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
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

Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\New-CertaTask.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\New-CertaTask.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\Invoke-CertaRouter.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\Invoke-CertaOllamaTask.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\Invoke-CertaOllamaTask.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\Get-CertaServerHealth.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\Get-CertaServerHealth.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'router\Test-CertaTaskRecord.ps1') -Destination (Join-Path $ServerRoot 'ROUTER\Test-CertaTaskRecord.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'policies\task-routing-policy.json') -Destination (Join-Path $ServerRoot 'CONTROL\policies\task-routing-policy.json') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'schemas\task.schema.json') -Destination (Join-Path $ServerRoot 'CONTROL\schemas\task.schema.json') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'capabilities\New-CertaFileManifest.ps1') -Destination (Join-Path $ServerRoot 'SCRIPTS\New-CertaFileManifest.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'capabilities\Test-CertaFileManifest.ps1') -Destination (Join-Path $ServerRoot 'SCRIPTS\Test-CertaFileManifest.ps1') -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'trigger\Install-CertaServer-TriggerCommands.ps1') -Destination (Join-Path $ServerRoot 'CONTROL\Install-CertaServer-TriggerCommands.ps1') -Force

$capabilityRegistry = Join-Path $ServerRoot 'CONTROL\registries\CAPABILITY_REGISTRY.csv'
$capabilities = if (Test-Path -LiteralPath $capabilityRegistry) { @(Import-Csv -LiteralPath $capabilityRegistry) } else { @() }
$capabilities = @($capabilities | Where-Object { [string]$_.capability_id -ne 'file-manifest-v1' })
$capabilities += [pscustomobject]@{
    capability_id='file-manifest-v1'
    name='File manifest with bounded SHA256 hashing'
    intent_regex='(?i)(checksum|file manifest|inventory files)'
    status='VERIFIED'
    script_path=(Join-Path $ServerRoot 'SCRIPTS\New-CertaFileManifest.ps1')
    validator_path=(Join-Path $ServerRoot 'SCRIPTS\Test-CertaFileManifest.ps1')
    node='CERTA-SERVER'
    authority='DETERMINISTIC'
    notes='Read-only bounded scan with atomic output, self-exclusion, SHA256 validation, and CI execution test.'
}
$capabilities | Export-Csv -LiteralPath $capabilityRegistry -NoTypeInformation -Encoding UTF8

$ollamaExe = (Get-Command ollama.exe -ErrorAction SilentlyContinue).Source
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

$triggerResult = $null
if ($InstallTriggerCommands) {
    $triggerResult = & (Join-Path $ServerRoot 'CONTROL\Install-CertaServer-TriggerCommands.ps1') -ServerRoot $ServerRoot
}

$testResult = & (Join-Path $sourceRoot 'router\Test-CertaRouter.ps1') 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $testResult -notmatch 'CERTA_ROUTER_TEST_PASS') {
    throw "Router self-test failed.`n$testResult"
}

$manifest = [ordered]@{
    schema_version = 1
    installed_at = (Get-Date).ToUniversalTime().ToString('o')
    computer = $env:COMPUTERNAME
    user = "$env:USERDOMAIN\$env:USERNAME"
    server_root = $ServerRoot
    source_repository = $SourceRepository
    source_commit = if ([string]::IsNullOrWhiteSpace($SourceCommit)) { $null } else { $SourceCommit }
    ollama_executable = $ollamaExe
    local_model = $LocalModel
    local_alias = 'certard-local'
    trigger = $triggerResult
    router_test = 'PASS'
    status = 'PASS'
}
$manifestPath = Join-Path $ServerRoot 'CONTROL\manifests\server-manifest.json'
$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
$receiptPath = Join-Path $ServerRoot "CONTROL\receipts\$runId.json"
$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $receiptPath -Encoding UTF8

[pscustomobject]@{
    status='PASS'
    server_root=$ServerRoot
    manifest=$manifestPath
    receipt=$receiptPath
    next='Create a task with D:\SERVER\ROUTER\New-CertaTask.ps1, then route it with Invoke-CertaRouter.ps1.'
}
