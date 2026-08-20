#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ServerRoot = [IO.Path]::GetFullPath($ServerRoot).TrimEnd('\')
if ($ServerRoot -notmatch '^[A-Za-z]:\\' -or $ServerRoot.IndexOfAny([char[]]@('"',"`r","`n",'%','!')) -ge 0) {
    throw 'ServerRoot must be a fully qualified local drive path without shell-expansion characters.'
}

function Get-CertaCommandPropertyValue {
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

$commandsPath = Join-Path $env:USERPROFILE '.TRIGGERcmdData\commands.json'
if (-not (Test-Path -LiteralPath $commandsPath)) {
    throw "TRIGGERcmd commands file not found: $commandsPath. Open the foreground agent under this Windows profile, then rerun."
}
$commandsLockPath = Join-Path (Split-Path -Parent $commandsPath) '.certa-commands.lock'
$commandsLockStream = $null
try {
    $commandsLockStream = [IO.File]::Open($commandsLockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
}
catch {
    throw "Another Certa process is updating the TRIGGERcmd catalog: $([string]$_.Exception.Message)"
}

try {
$sourceHash = (Get-FileHash -LiteralPath $commandsPath -Algorithm SHA256).Hash

$backupDir = Join-Path $ServerRoot 'CONTROL\backups\triggercmd'
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$backupPath = Join-Path $backupDir ('commands-{0:yyyyMMdd-HHmmssfff}-{1}.json' -f (Get-Date), ([guid]::NewGuid().ToString('N').Substring(0,8)))
Copy-Item -LiteralPath $commandsPath -Destination $backupPath -Force

$items = @()
$raw = Get-Content -LiteralPath $commandsPath -Raw
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    # Windows PowerShell 5.1 can preserve a JSON array as one nested pipeline
    # object. Assign first, then expand it so each command is validated alone.
    $parsedItems = $raw | ConvertFrom-Json
    $items = @($parsedItems)
}

$definitions = @(
    [pscustomobject]@{
        trigger='Certa Server Health'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}"' -f (Join-Path $ServerRoot 'ROUTER\Get-CertaServerHealth.ps1'),$ServerRoot)
        offCommand=''
        ground='foreground'
        voice=''
        voiceReply=''
        allowParams=$false
    },
    [pscustomobject]@{
        trigger='Certa Server Smoke Test'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}"' -f (Join-Path $ServerRoot 'ROUTER\Test-CertaServerEndToEnd.ps1'),$ServerRoot)
        offCommand=''
        ground='foreground'
        voice=''
        voiceReply=''
        allowParams=$false
    },
    [pscustomobject]@{
        trigger='Certa Beacon Refresh'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}"' -f (Join-Path $ServerRoot 'ROUTER\Publish-CertaServerStatus.ps1'),$ServerRoot)
        offCommand=''
        ground='foreground'
        voice=''
        voiceReply=''
        allowParams=$false
    },
    [pscustomobject]@{
        trigger='Certa Server Route Once'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}"' -f (Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1'),$ServerRoot)
        offCommand=''
        ground='foreground'
        voice=''
        voiceReply=''
        allowParams=$false
    },
    [pscustomobject]@{
        trigger='Certa Server Route All'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}" -All' -f (Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1'),$ServerRoot)
        offCommand=''
        ground='foreground'
        voice=''
        voiceReply=''
        allowParams=$false
    },
    [pscustomobject]@{
        trigger='Certa Ollama Status'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -ServerRoot "{1}"' -f (Join-Path $ServerRoot 'ROUTER\Get-CertaServerHealth.ps1'),$ServerRoot)
        offCommand=''
        ground='foreground'
        voice=''
        voiceReply=''
        allowParams=$false
    },
    [pscustomobject]@{
        trigger='Certa Open Server'
        command=('explorer.exe "{0}"' -f $ServerRoot)
        offCommand=''
        ground='foreground'
        voice=''
        voiceReply=''
        allowParams=$false
    }
)

$names = @($definitions | ForEach-Object { $_.trigger })
$retainedItems = @()
$droppedInvalidItems = 0
$removedPreviousBeacons = 0
$hardenedUnmanagedCommands = New-Object System.Collections.Generic.List[string]
$beaconPattern = '^Certa Beacon H-(PASS|ATTN|FAIL|ERROR|INIT) S-(PASS|FAIL|ERROR|INIT|STALE|RUNNING) U-([0-9]{8}T[0-9]{6}Z|00000000T000000Z) R-[A-F0-9]{8}$'
foreach ($item in $items) {
    $triggerName = Get-CertaCommandPropertyValue -InputObject $item -Name 'trigger'
    $commandText = Get-CertaCommandPropertyValue -InputObject $item -Name 'command'
    if ([string]::IsNullOrWhiteSpace($triggerName) -or [string]::IsNullOrWhiteSpace($commandText)) {
        $droppedInvalidItems++
        continue
    }
    if ($triggerName -like 'Certa Beacon H-*') {
        if (
            $triggerName -cnotmatch $beaconPattern -or
            $commandText -ne 'cmd.exe /d /c exit /b 0' -or
            (Get-CertaCommandPropertyValue -InputObject $item -Name 'ground') -ne 'foreground' -or
            ((Get-CertaCommandPropertyValue -InputObject $item -Name 'allowParams') -notin @('false','0','')) -or
            (Get-CertaCommandPropertyValue -InputObject $item -Name 'offCommand') -ne '' -or
            (Get-CertaCommandPropertyValue -InputObject $item -Name 'voice') -ne '' -or
            (Get-CertaCommandPropertyValue -InputObject $item -Name 'voiceReply') -ne ''
        ) {
            throw "Existing reserved Certa beacon is invalid or unsafe: $triggerName"
        }
        $removedPreviousBeacons++
        continue
    }
    if ($triggerName -notin $names) {
        $allowProperty = $item.PSObject.Properties['allowParams']
        if ($null -eq $allowProperty -or $allowProperty.Value -in @($false,0,'0','false','')) {
            $item | Add-Member -NotePropertyName allowParams -NotePropertyValue $false -Force
        }
        elseif (
            ($triggerName -eq 'Calculator' -and $commandText -in @('calc','calc.exe')) -or
            ($triggerName -eq 'Notepad' -and $commandText -in @('notepad','notepad.exe'))
        ) {
            $item | Add-Member -NotePropertyName allowParams -NotePropertyValue $false -Force
            $hardenedUnmanagedCommands.Add($triggerName)
        }
        $retainedItems += $item
    }
}
if ($removedPreviousBeacons -gt 1) { throw 'Multiple existing Certa status beacons were found; registration left the catalog unchanged.' }
$items = @($retainedItems) + @($definitions)
$currentSessionId = [int](Get-Process -Id $PID -ErrorAction Stop).SessionId
$agentState = Get-CertaTriggerAgentState -SessionId $currentSessionId
if (-not $agentState.query_succeeded) {
    throw "Unable to query TRIGGERcmd controller processes; registration left the catalog unchanged. $($agentState.query_error)"
}
$sessionAgents = @($agentState.controller_processes)
$electronChildProcesses = @($agentState.electron_child_processes)
if ($sessionAgents.Count -gt 1) { throw 'Multiple TRIGGERcmd controller processes are running in the current Windows session.' }
$agent = $sessionAgents | Select-Object -First 1
$agentProcessId = if ($agent) { [int]$agent.ProcessId } else { $null }
$temporaryPath = Join-Path (Split-Path -Parent $commandsPath) ('.commands.{0}.tmp' -f [guid]::NewGuid().ToString('N'))
$catalogChangeSignaled = $false
try {
    ConvertTo-Json -InputObject @($items) -Depth 20 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
    $validatedJson = Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json
    $validatedItems = @($validatedJson)
    foreach ($definition in $definitions) {
        $match = @($validatedItems | Where-Object {
            (Get-CertaCommandPropertyValue -InputObject $_ -Name 'trigger') -eq [string]$definition.trigger
        })
        if ($match.Count -ne 1) { throw "Trigger command validation failed for '$($definition.trigger)'." }
        if (-not (Test-CertaBooleanFalseProperty -InputObject $match[0] -Name 'allowParams')) {
            throw "Trigger command unexpectedly allows parameters: $($definition.trigger)"
        }
        if (
            (Get-CertaCommandPropertyValue -InputObject $match[0] -Name 'command') -ne [string]$definition.command -or
            (Get-CertaCommandPropertyValue -InputObject $match[0] -Name 'ground') -ne 'foreground' -or
            (Get-CertaCommandPropertyValue -InputObject $match[0] -Name 'offCommand') -ne '' -or
            (Get-CertaCommandPropertyValue -InputObject $match[0] -Name 'voice') -ne '' -or
            (Get-CertaCommandPropertyValue -InputObject $match[0] -Name 'voiceReply') -ne ''
        ) {
            throw "Trigger command metadata validation failed for '$($definition.trigger)'."
        }
    }
    if ((Get-FileHash -LiteralPath $commandsPath -Algorithm SHA256).Hash -ne $sourceHash) {
        throw 'TRIGGERcmd commands changed during registration; retry instead of overwriting concurrent changes.'
    }
    $replacementHash = (Get-FileHash -LiteralPath $temporaryPath -Algorithm SHA256).Hash
    [IO.File]::Replace($temporaryPath,$commandsPath,$null)
    if ((Get-FileHash -LiteralPath $commandsPath -Algorithm SHA256).Hash -ne $replacementHash) {
        throw 'TRIGGERcmd command registration hash verification failed.'
    }
    [IO.File]::SetLastWriteTimeUtc($commandsPath,[DateTime]::UtcNow)
    if ((Get-FileHash -LiteralPath $commandsPath -Algorithm SHA256).Hash -ne $replacementHash) {
        throw 'TRIGGERcmd catalog changed while signaling its live file watcher.'
    }
    $catalogChangeSignaled = $true
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
}

[pscustomobject]@{
    status = 'PASS'
    commands_path = $commandsPath
    backup_path = $backupPath
    installed = $names
    agent_running = ($sessionAgents.Count -eq 1)
    agent_session_id = $currentSessionId
    agent_process_id = $agentProcessId
    agent_query_succeeded = [bool]$agentState.query_succeeded
    agent_query_error = $agentState.query_error
    agent_query_filter = $agentState.query_filter
    agent_controller_process_count = $sessionAgents.Count
    agent_electron_child_process_count = $electronChildProcesses.Count
    agent_electron_child_process_ids = @($electronChildProcesses | ForEach-Object { [int]$_.ProcessId })
    catalog_change_signaled = $catalogChangeSignaled
    retained_existing_commands = $retainedItems.Count
    dropped_invalid_commands = $droppedInvalidItems
    removed_previous_beacons = $removedPreviousBeacons
    hardened_unmanaged_commands = $hardenedUnmanagedCommands
    note = 'Foreground commands were registered atomically with boolean parameters disabled; the running agent file watcher was left in place.'
}
}
finally {
    if ($commandsLockStream) { $commandsLockStream.Dispose() }
}
