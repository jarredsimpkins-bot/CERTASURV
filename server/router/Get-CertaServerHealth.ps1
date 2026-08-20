#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [switch]$NoReceipt,
    [switch]$NoExitCode,
    [switch]$AllowMissingBeacon
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ServerRoot = [IO.Path]::GetFullPath($ServerRoot).TrimEnd('\')

function Get-CertaPropertyValue {
    param(
        [Parameter(Mandatory=$true)][AllowNull()]$InputObject,
        [Parameter(Mandatory=$true)][string]$Name
    )

    if ($null -eq $InputObject) { return '' }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return '' }
    return [string]$property.Value
}

function Test-CertaBooleanFalseProperty {
    param([Parameter(Mandatory=$true)][AllowNull()]$InputObject, [Parameter(Mandatory=$true)][string]$Name)
    if ($null -eq $InputObject) { return $false }
    $property = $InputObject.PSObject.Properties[$Name]
    return ($null -ne $property -and $property.Value -is [bool] -and -not [bool]$property.Value)
}

function Get-CertaTriggerAgentState {
    param([Parameter(Mandatory=$true)][int]$SessionId)

    $queryFilter = "Name = 'TRIGGERcmdAgent.exe' AND SessionId = {0}" -f $SessionId
    $querySucceeded = $false
    $queryError = $null
    $sessionProcesses = @()
    try {
        $sessionProcesses = @(Get-CimInstance -ClassName Win32_Process -Filter $queryFilter -ErrorAction Stop)
        $querySucceeded = $true
    }
    catch {
        $queryError = [string]$_.Exception.Message
    }

    # Electron renderer, GPU, utility, and crash-handler processes use the
    # packaged executable too. Only the controller has no --type= argument.
    $electronChildProcesses = @($sessionProcesses | Where-Object { [string]$_.CommandLine -match '(?i)--type=' })
    $controllerProcesses = @($sessionProcesses | Where-Object { [string]$_.CommandLine -notmatch '(?i)--type=' })
    [pscustomobject][ordered]@{
        query_succeeded = $querySucceeded
        query_error = $queryError
        query_filter = $queryFilter
        controller_processes = $controllerProcesses
        electron_child_processes = $electronChildProcesses
    }
}

$requiredFolders = @('CONTROL','INBOX','QUEUE','PROJECT_LINKS','REPOS','WORKTREES','WORKING','ROUTER','SCRIPTS','OLLAMA','OUTPUTS','RECEIPTS','LOGS','STAGING','ARCHIVE','BACKUPS')
$folderStatus = @()
foreach ($name in $requiredFolders) {
    $path = Join-Path $ServerRoot $name
    $folderStatus += [pscustomobject]@{ name=$name; path=$path; exists=[bool](Test-Path -LiteralPath $path) }
}
$requiredComponents = @(
    'ROUTER\New-CertaTask.ps1',
    'ROUTER\Invoke-CertaRouter.ps1',
    'ROUTER\Invoke-CertaOllamaTask.ps1',
    'ROUTER\Get-CertaServerHealth.ps1',
    'ROUTER\Test-CertaServerEndToEnd.ps1',
    'ROUTER\Publish-CertaServerStatus.ps1',
    'ROUTER\Test-CertaTaskRecord.ps1',
    'SCRIPTS\Update-CertaCapabilityRegistry.ps1',
    'CONTROL\Install-CertaServer-TriggerCommands.ps1',
    'CONTROL\policies\task-routing-policy.json',
    'CONTROL\schemas\task.schema.json'
)
$componentStatus = @($requiredComponents | ForEach-Object {
    $componentPath = Join-Path $ServerRoot $_
    [pscustomobject]@{ relative_path=$_; path=$componentPath; exists=[bool](Test-Path -LiteralPath $componentPath -PathType Leaf) }
})

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
$listenerSource = $null
try {
    $listeners = @(Get-NetTCPConnection -LocalPort 11434 -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,OwningProcess)
    if ($listeners.Count -gt 0) { $listenerSource = 'Get-NetTCPConnection' }
}
catch {}
if ($listeners.Count -eq 0) {
    try {
        $netstatLines = @(& netstat.exe -ano -p TCP 2>$null)
        foreach ($line in $netstatLines) {
            $parts = @($line.Trim() -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            if ($parts.Count -lt 5 -or $parts[0] -ne 'TCP' -or $parts[3] -ne 'LISTENING') { continue }
            $localEndpoint = [string]$parts[1]
            $separator = $localEndpoint.LastIndexOf(':')
            if ($separator -lt 1 -or $localEndpoint.Substring($separator + 1) -ne '11434') { continue }
            $localAddress = $localEndpoint.Substring(0,$separator).Trim('[',']')
            $listeners += [pscustomobject]@{
                LocalAddress = $localAddress
                LocalPort = 11434
                OwningProcess = [int]$parts[4]
            }
        }
        if ($listeners.Count -gt 0) { $listenerSource = 'netstat' }
    }
    catch {}
}
$wildcardListener = @($listeners | Where-Object { $_.LocalAddress -in @('0.0.0.0','::') }).Count -gt 0
$nonLoopbackListeners = @($listeners | Where-Object { $_.LocalAddress -notin @('127.0.0.1','::1') })

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
        # Windows PowerShell 5.1 can preserve a JSON array as a nested pipeline
        # object. Assign first, then expand so each command is inspected alone.
        $parsedTriggerItems = Get-Content -LiteralPath $triggerConfig -Raw | ConvertFrom-Json
        $triggerItems = @($parsedTriggerItems)
        $triggerConfigValid = $true
    }
    catch {}
}
$expectedTriggerDefinitions = @(
    [pscustomobject]@{
        trigger='Certa Server Health'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}"' -f (Join-Path $ServerRoot 'ROUTER\Get-CertaServerHealth.ps1'),$ServerRoot)
        voice=''
    },
    [pscustomobject]@{
        trigger='Certa Server Smoke Test'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}"' -f (Join-Path $ServerRoot 'ROUTER\Test-CertaServerEndToEnd.ps1'),$ServerRoot)
        voice=''
    },
    [pscustomobject]@{
        trigger='Certa Beacon Refresh'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}"' -f (Join-Path $ServerRoot 'ROUTER\Publish-CertaServerStatus.ps1'),$ServerRoot)
        voice=''
    },
    [pscustomobject]@{
        trigger='Certa Server Route Once'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}"' -f (Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1'),$ServerRoot)
        voice=''
    },
    [pscustomobject]@{
        trigger='Certa Server Route All'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}" -All' -f (Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1'),$ServerRoot)
        voice=''
    },
    [pscustomobject]@{
        trigger='Certa Ollama Status'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}"' -f (Join-Path $ServerRoot 'ROUTER\Get-CertaServerHealth.ps1'),$ServerRoot)
        voice=''
    },
    [pscustomobject]@{
        trigger='Certa Open Server'
        command=('explorer.exe "{0}"' -f $ServerRoot)
        voice=''
    }
)
$requiredTriggerCommands = @($expectedTriggerDefinitions | ForEach-Object { [string]$_.trigger })
$triggerCommands = @($triggerItems | ForEach-Object { Get-CertaPropertyValue -InputObject $_ -Name 'trigger' } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$missingTriggerCommands = New-Object System.Collections.Generic.List[string]
$duplicateTriggerCommands = New-Object System.Collections.Generic.List[string]
$invalidTriggerCommands = New-Object System.Collections.Generic.List[string]
$unsafeTriggerCommands = New-Object System.Collections.Generic.List[string]
foreach ($definition in $expectedTriggerDefinitions) {
    $matches = @($triggerItems | Where-Object { (Get-CertaPropertyValue -InputObject $_ -Name 'trigger') -eq [string]$definition.trigger })
    if ($matches.Count -eq 0) {
        $missingTriggerCommands.Add([string]$definition.trigger)
        continue
    }
    if ($matches.Count -ne 1) {
        $duplicateTriggerCommands.Add([string]$definition.trigger)
        continue
    }
    $item = $matches[0]
    if (-not (Test-CertaBooleanFalseProperty -InputObject $item -Name 'allowParams')) {
        $unsafeTriggerCommands.Add([string]$definition.trigger)
    }
    if (
        -not [string]::Equals((Get-CertaPropertyValue -InputObject $item -Name 'command'),[string]$definition.command,[StringComparison]::OrdinalIgnoreCase) -or
        (Get-CertaPropertyValue -InputObject $item -Name 'ground') -ne 'foreground' -or
        (Get-CertaPropertyValue -InputObject $item -Name 'offCommand') -ne '' -or
        (Get-CertaPropertyValue -InputObject $item -Name 'voice') -ne '' -or
        (Get-CertaPropertyValue -InputObject $item -Name 'voiceReply') -ne ''
    ) {
        $invalidTriggerCommands.Add([string]$definition.trigger)
    }
}
$invalidCatalogItems = New-Object System.Collections.Generic.List[string]
for ($itemIndex = 0; $itemIndex -lt $triggerItems.Count; $itemIndex++) {
    $catalogName = Get-CertaPropertyValue -InputObject $triggerItems[$itemIndex] -Name 'trigger'
    $catalogCommand = Get-CertaPropertyValue -InputObject $triggerItems[$itemIndex] -Name 'command'
    if ([string]::IsNullOrWhiteSpace($catalogName) -or [string]::IsNullOrWhiteSpace($catalogCommand)) {
        $invalidCatalogItems.Add("index $itemIndex")
    }
}
$beaconPattern = '^Certa Beacon H-(PASS|ATTN|FAIL|ERROR|INIT) S-(PASS|FAIL|ERROR|INIT|STALE|RUNNING) U-([0-9]{8}T[0-9]{6}Z|00000000T000000Z) R-[A-F0-9]{8}$'
$beaconItems = @($triggerItems | Where-Object { (Get-CertaPropertyValue -InputObject $_ -Name 'trigger') -like 'Certa Beacon H-*' })
$invalidBeaconCommands = New-Object System.Collections.Generic.List[string]
foreach ($beaconItem in $beaconItems) {
    $beaconName = Get-CertaPropertyValue -InputObject $beaconItem -Name 'trigger'
    if (
        $beaconName -cnotmatch $beaconPattern -or
        (Get-CertaPropertyValue -InputObject $beaconItem -Name 'command') -ne 'cmd.exe /d /c exit /b 0' -or
        (Get-CertaPropertyValue -InputObject $beaconItem -Name 'ground') -ne 'foreground' -or
        -not (Test-CertaBooleanFalseProperty -InputObject $beaconItem -Name 'allowParams') -or
        (Get-CertaPropertyValue -InputObject $beaconItem -Name 'offCommand') -ne '' -or
        (Get-CertaPropertyValue -InputObject $beaconItem -Name 'voice') -ne '' -or
        (Get-CertaPropertyValue -InputObject $beaconItem -Name 'voiceReply') -ne ''
    ) {
        $invalidBeaconCommands.Add($beaconName)
    }
}
$unmanagedTriggerItems = @($triggerItems | Where-Object {
    $unmanagedName = Get-CertaPropertyValue -InputObject $_ -Name 'trigger'
    $unmanagedName -notin $requiredTriggerCommands -and $unmanagedName -notlike 'Certa Beacon H-*'
})
$unsafeUnmanagedCommands = @($unmanagedTriggerItems | Where-Object {
    -not (Test-CertaBooleanFalseProperty -InputObject $_ -Name 'allowParams')
} | ForEach-Object { Get-CertaPropertyValue -InputObject $_ -Name 'trigger' })
$currentSessionId = [int](Get-Process -Id $PID -ErrorAction Stop).SessionId
$triggerAgentState = Get-CertaTriggerAgentState -SessionId $currentSessionId
$triggerAgentProcesses = @($triggerAgentState.controller_processes)
$triggerAgentChildProcesses = @($triggerAgentState.electron_child_processes)
$triggerAgentRunning = [bool]$triggerAgentState.query_succeeded -and $triggerAgentProcesses.Count -eq 1
$requiredModelPresent = @($models | Where-Object { $_ -eq 'certard-local' -or $_ -like 'certard-local:*' }).Count -gt 0
$expectedModelsPath = Join-Path $ServerRoot 'OLLAMA\models'
$configuredModelsPath = [Environment]::GetEnvironmentVariable('OLLAMA_MODELS','User')
$configuredHost = [Environment]::GetEnvironmentVariable('OLLAMA_HOST','User')
$cloudDisabled = [Environment]::GetEnvironmentVariable('OLLAMA_NO_CLOUD','User')
$stagedRouterTasks = @(Get-ChildItem -LiteralPath (Join-Path $ServerRoot 'STAGING\router') -File -Filter '*.json' -ErrorAction SilentlyContinue).Count

$status = 'PASS'
$findings = New-Object System.Collections.Generic.List[string]
if (@($folderStatus | Where-Object { -not $_.exists }).Count -gt 0) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('One or more required server folders are missing.') }
if (@($componentStatus | Where-Object { -not $_.exists }).Count -gt 0) { $status='FAIL'; $findings.Add('One or more required server runtime components are missing.') }
if (-not $ollamaHealthy) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('Ollama local API is not healthy.') }
if ($wildcardListener) { $status='FAIL'; $findings.Add('Ollama is listening on a wildcard address; keep it on localhost only.') }
elseif ($nonLoopbackListeners.Count -gt 0) { $status='FAIL'; $findings.Add('Ollama has a non-loopback listener; keep it on localhost only.') }
if ($ollamaHealthy -and @($listeners).Count -eq 0) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('Ollama is healthy, but the listener address could not be verified.') }
if (-not $requiredModelPresent) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('The certard-local Ollama model alias is missing.') }
if (-not [string]::Equals($configuredModelsPath, $expectedModelsPath, [StringComparison]::OrdinalIgnoreCase)) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add("OLLAMA_MODELS does not point to $expectedModelsPath for this user.") }
if ($configuredHost -ne '127.0.0.1:11434') { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('OLLAMA_HOST is not explicitly set to localhost for this user.') }
if ($cloudDisabled -ne '1') { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('OLLAMA_NO_CLOUD is not enabled for this user.') }
if (-not (Test-Path -LiteralPath $triggerConfig)) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('TRIGGERcmd commands.json was not found for the current profile.') }
elseif (-not $triggerConfigValid) { $status='FAIL'; $findings.Add('TRIGGERcmd commands.json is invalid JSON.') }
if ($missingTriggerCommands.Count -gt 0) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add("Missing TRIGGERcmd commands: $($missingTriggerCommands -join ', ')") }
if ($duplicateTriggerCommands.Count -gt 0) { $status='FAIL'; $findings.Add("Duplicate TRIGGERcmd commands: $($duplicateTriggerCommands -join ', ')") }
if ($invalidTriggerCommands.Count -gt 0) { $status='FAIL'; $findings.Add("TRIGGERcmd commands have unexpected command text or execution mode: $($invalidTriggerCommands -join ', ')") }
if ($unsafeTriggerCommands.Count -gt 0) { $status='FAIL'; $findings.Add("TRIGGERcmd commands allow remote parameters: $($unsafeTriggerCommands -join ', ')") }
if ($invalidCatalogItems.Count -gt 0) { $status='FAIL'; $findings.Add("TRIGGERcmd catalog contains malformed entries: $($invalidCatalogItems -join ', ')") }
if ($beaconItems.Count -gt 1) { $status='FAIL'; $findings.Add('Multiple Certa status beacons are registered.') }
elseif ($beaconItems.Count -eq 0 -and -not $AllowMissingBeacon) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('No Certa status beacon is registered yet.') }
if ($invalidBeaconCommands.Count -gt 0) { $status='FAIL'; $findings.Add('A Certa status beacon has invalid or unsafe command metadata.') }
if ($unsafeUnmanagedCommands.Count -gt 0) { $status='FAIL'; $findings.Add("Retained TRIGGERcmd commands allow remote parameters: $($unsafeUnmanagedCommands -join ', ')") }
if (-not $triggerAgentState.query_succeeded) { $status='FAIL'; $findings.Add("TRIGGERcmd controller process query failed: $($triggerAgentState.query_error)") }
elseif ($triggerAgentProcesses.Count -eq 0) { if ($status -eq 'PASS') { $status='ATTENTION' }; $findings.Add('TRIGGERcmd foreground controller is not running for the current profile.') }
elseif ($triggerAgentProcesses.Count -gt 1) { $status='FAIL'; $findings.Add('Multiple TRIGGERcmd foreground controllers are running in the current session.') }
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
    components = $componentStatus
    drive_free_gib = if ($drive) { [math]::Round(($drive.Free / 1GB),2) } else { $null }
    ollama = [ordered]@{
        healthy = $ollamaHealthy
        version = $ollamaVersion
        models = $models
        required_model_present = $requiredModelPresent
        listeners = $listeners
        listener_source = $listenerSource
        wildcard_listener = $wildcardListener
        non_loopback_listeners = $nonLoopbackListeners
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
        duplicate_commands = $duplicateTriggerCommands
        invalid_commands = $invalidTriggerCommands
        unsafe_parameter_commands = $unsafeTriggerCommands
        invalid_catalog_items = $invalidCatalogItems
        beacon_count = $beaconItems.Count
        invalid_beacons = $invalidBeaconCommands
        unmanaged_commands = @($unmanagedTriggerItems | ForEach-Object { Get-CertaPropertyValue -InputObject $_ -Name 'trigger' })
        unsafe_unmanaged_commands = $unsafeUnmanagedCommands
        agent_running = $triggerAgentRunning
        session_id = $currentSessionId
        agent_query_succeeded = [bool]$triggerAgentState.query_succeeded
        agent_query_error = $triggerAgentState.query_error
        agent_query_filter = $triggerAgentState.query_filter
        agent_controller_process_count = $triggerAgentProcesses.Count
        agent_controller_process_ids = @($triggerAgentProcesses | ForEach-Object { [int]$_.ProcessId })
        agent_electron_child_process_count = $triggerAgentChildProcesses.Count
        agent_electron_child_process_ids = @($triggerAgentChildProcesses | ForEach-Object { [int]$_.ProcessId })
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
if ($status -eq 'FAIL' -and -not $NoExitCode) { exit 2 }
