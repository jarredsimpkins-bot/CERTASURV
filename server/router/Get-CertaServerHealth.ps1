#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [switch]$NoReceipt
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredFolders = @('CONTROL','INBOX','QUEUE','PROJECT_LINKS','REPOS','WORKTREES','WORKING','OUTPUTS','RECEIPTS','LOGS','STAGING','ARCHIVE','BACKUPS')
$folderStatus = @()
foreach ($name in $requiredFolders) {
    $path = Join-Path $ServerRoot $name
    $folderStatus += [pscustomobject]@{ name=$name; path=$path; exists=[bool](Test-Path -LiteralPath $path) }
}

$ollamaHealthy = $false
$ollamaVersion = $null
$models = @()
try {
    $version = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 5
    $tags = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 10
    $ollamaHealthy = $true
    $ollamaVersion = [string]$version.version
    $models = @($tags.models | ForEach-Object { $_.name })
}
catch {}

$listeners = @()
try {
    $listeners = @(Get-NetTCPConnection -LocalPort 11434 -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,OwningProcess)
}
catch {}
$wildcardListener = @($listeners | Where-Object { $_.LocalAddress -in @('0.0.0.0','::') }).Count -gt 0

$driveName = ([IO.Path]::GetPathRoot($ServerRoot)).TrimEnd('\').TrimEnd(':')
$drive = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
$queueCounts = [ordered]@{}
foreach ($lane in @('script','ollama','codex','specialist','review')) {
    $path = Join-Path $ServerRoot "QUEUE\$lane"
    $queueCounts[$lane] = if (Test-Path -LiteralPath $path) { @(Get-ChildItem -LiteralPath $path -File -Filter '*.json' -ErrorAction SilentlyContinue).Count } else { 0 }
}
$queueCounts['inbox'] = if (Test-Path -LiteralPath (Join-Path $ServerRoot 'INBOX')) { @(Get-ChildItem -LiteralPath (Join-Path $ServerRoot 'INBOX') -File -Filter '*.json' -ErrorAction SilentlyContinue).Count } else { 0 }

$triggerConfig = Join-Path $env:USERPROFILE '.TRIGGERcmdData\commands.json'
$triggerItems = @()
$triggerConfigValid = $false
if (Test-Path -LiteralPath $triggerConfig) {
    try {
        $parsedTriggerItems = Get-Content -LiteralPath $triggerConfig -Raw | ConvertFrom-Json
        $triggerItems = @($parsedTriggerItems)
        $triggerConfigValid = $true
    }
    catch {}
}
$requiredTriggerCommands = @('Certa Server Health','Certa Server Route Once','Certa Server Route All','Certa Ollama Status','Certa Open Server')
$triggerCommands = @($triggerItems | ForEach-Object { [string]$_.trigger })
$missingTriggerCommands = @($requiredTriggerCommands | Where-Object { $_ -notin $triggerCommands })
$unsafeTriggerCommands = @($triggerItems | Where-Object { $_.trigger -in $requiredTriggerCommands -and [string]$_.allowParams -ne 'false' } | ForEach-Object { [string]$_.trigger })
$triggerAgentRunning = [bool](Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue)
$requiredModelPresent = @($models | Where-Object { $_ -eq 'certard-local' -or $_ -like 'certard-local:*' }).Count -gt 0
$expectedModelsPath = Join-Path $ServerRoot 'OLLAMA\models'
$configuredModelsPath = [Environment]::GetEnvironmentVariable('OLLAMA_MODELS','User')
$configuredHost = [Environment]::GetEnvironmentVariable('OLLAMA_HOST','User')
$cloudDisabled = [Environment]::GetEnvironmentVariable('OLLAMA_NO_CLOUD','User')
$stagedRouterTasks = @(Get-ChildItem -LiteralPath (Join-Path $ServerRoot 'STAGING\router') -File -Filter '*.json' -ErrorAction SilentlyContinue).Count

$status = 'PASS'
$findings = New-Object System.Collections.Generic.List[string]
if (@($folderStatus | Where-Object { -not $_.exists }).Count -gt 0) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('One or more required server folders are missing.') }
if (-not $ollamaHealthy) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('Ollama local API is not healthy.') }
if ($wildcardListener) { $status='FAIL'; $findings.Add('Ollama is listening on a wildcard address; keep it on localhost only.') }
if ($ollamaHealthy -and @($listeners).Count -eq 0) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('Ollama is healthy, but the listener address could not be verified.') }
if (-not $requiredModelPresent) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('The certard-local Ollama model alias is missing.') }
if (-not [string]::Equals($configuredModelsPath, $expectedModelsPath, [StringComparison]::OrdinalIgnoreCase)) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add("OLLAMA_MODELS does not point to $expectedModelsPath for this user.") }
if ($configuredHost -ne '127.0.0.1:11434') { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('OLLAMA_HOST is not explicitly set to localhost for this user.') }
if ($cloudDisabled -ne '1') { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('OLLAMA_NO_CLOUD is not enabled for this user.') }
if (-not (Test-Path -LiteralPath $triggerConfig)) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('TRIGGERcmd commands.json was not found for the current profile.') }
elseif (-not $triggerConfigValid) { $status='FAIL'; $findings.Add('TRIGGERcmd commands.json is invalid JSON.') }
if ($missingTriggerCommands.Count -gt 0) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add("Missing TRIGGERcmd commands: $($missingTriggerCommands -join ', ')") }
if ($unsafeTriggerCommands.Count -gt 0) { $status='FAIL'; $findings.Add("TRIGGERcmd commands allow remote parameters: $($unsafeTriggerCommands -join ', ')") }
if (-not $triggerAgentRunning) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('TRIGGERcmd foreground agent is not running for the current profile.') }
if ($drive -and $drive.Free -lt 20GB) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('Server drive has less than 20 GiB free.') }
if ($stagedRouterTasks -gt 0) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add("Router staging contains $stagedRouterTasks claimed task(s) that may require recovery.") }

$result = [ordered]@{
    schema_version = 1
    checked_at = (Get-Date).ToUniversalTime().ToString('o')
    status = $status
    computer = $env:COMPUTERNAME
    user = "$env:USERDOMAIN\$env:USERNAME"
    server_root = $ServerRoot
    folders = $folderStatus
    drive_free_gib = if ($drive) { [math]::Round(($drive.Free / 1GB),2) } else { $null }
    ollama = [ordered]@{
        healthy = $ollamaHealthy
        version = $ollamaVersion
        models = $models
        required_model_present = $requiredModelPresent
        listeners = $listeners
        wildcard_listener = $wildcardListener
        configured_host = $configuredHost
        configured_models_path = $configuredModelsPath
        cloud_disabled = ($cloudDisabled -eq '1')
    }
    trigger = [ordered]@{
        config_path = $triggerConfig
        config_exists = [bool](Test-Path -LiteralPath $triggerConfig)
        config_valid = $triggerConfigValid
        commands = $triggerCommands
        missing_commands = $missingTriggerCommands
        unsafe_parameter_commands = $unsafeTriggerCommands
        agent_running = $triggerAgentRunning
    }
    tools = [ordered]@{
        git = [bool](Get-Command git.exe -ErrorAction SilentlyContinue)
        codex = [bool](Get-Command codex.exe -ErrorAction SilentlyContinue)
        ollama = [bool](Get-Command ollama.exe -ErrorAction SilentlyContinue)
    }
    queue = $queueCounts
    staged_router_tasks = $stagedRouterTasks
    findings = $findings
}

if (-not $NoReceipt) {
    $receiptDir = Join-Path $ServerRoot 'RECEIPTS\health'
    New-Item -ItemType Directory -Path $receiptDir -Force | Out-Null
    $receiptPath = Join-Path $receiptDir ('health-{0:yyyyMMdd-HHmmss}.json' -f (Get-Date))
    $result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
    $result['receipt'] = $receiptPath
}

[pscustomobject]$result
if ($status -eq 'FAIL') { exit 2 }
