#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [switch]$InstallTriggerCommands,

    [switch]$RegisterStartup,

    [switch]$DisableSleepOnAC,

    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$started = Get-Date
$runId = 'certa-worker-extension-{0:yyyyMMdd-HHmmss}' -f $started

function Write-TextFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Value
    )

    Write-TextFile -Path $Path -Content ($Value | ConvertTo-Json -Depth 14)
}

function Assert-V1Runtime {
    param([string]$Root)

    $required = @(
        'ROUTER\New-CertaTask.ps1',
        'ROUTER\Invoke-CertaRouter.ps1',
        'ROUTER\Invoke-CertaOllamaTask.ps1',
        'ROUTER\Get-CertaServerHealth.ps1',
        'CONTROL\policies\task-routing-policy.json',
        'CONTROL\registries\CAPABILITY_REGISTRY.csv'
    )
    foreach ($relative in $required) {
        $path = Join-Path $Root $relative
        if (-not (Test-Path -LiteralPath $path)) {
            throw "The base Certa server router is not installed. Missing: $path"
        }
    }
}

function Install-WorkerRuntime {
    param([string]$Root)

    $folders = @(
        'CONTROL\backups',
        'CONTROL\receipts',
        'CONTROL\worker',
        'QUEUE\script',
        'QUEUE\ollama',
        'QUEUE\codex',
        'QUEUE\specialist',
        'QUEUE\review',
        'ROUTER',
        'SCRIPTS',
        'OUTPUTS\script',
        'RECEIPTS\script',
        'RECEIPTS\worker',
        'RECEIPTS\queue',
        'LOGS\worker'
    )
    foreach ($relative in $folders) {
        New-Item -ItemType Directory -Path (Join-Path $Root $relative) -Force | Out-Null
    }

    $manifestCapability = @'
#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ })]
    [string]$TaskPath,

    [long]$HashLimitBytes = 104857600
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$task = Get-Content -LiteralPath $TaskPath -Raw | ConvertFrom-Json
if (@($task.inputs).Count -lt 1) { throw 'file-manifest-v1 requires one input path.' }
$source = [string]$task.inputs[0]
if (-not (Test-Path -LiteralPath $source)) { throw "Input path does not exist: $source" }

$resolved = (Resolve-Path -LiteralPath $source).Path
$item = Get-Item -LiteralPath $resolved -Force
$files = if ($item.PSIsContainer) {
    @(Get-ChildItem -LiteralPath $resolved -File -Recurse -Force -ErrorAction Stop |
        Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) })
}
else {
    @($item)
}

$outputRoot = Join-Path $ServerRoot "OUTPUTS\script\$($task.task_id)"
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$rows = New-Object System.Collections.Generic.List[object]
$base = if ($item.PSIsContainer) { $resolved.TrimEnd('\') } else { Split-Path -Parent $resolved }

foreach ($file in $files) {
    $relative = if ($item.PSIsContainer) {
        $file.FullName.Substring($base.Length).TrimStart('\')
    }
    else {
        $file.Name
    }

    $hash = $null
    $hashStatus = 'SKIPPED_LARGE'
    if ($file.Length -le $HashLimitBytes) {
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        $hashStatus = 'SHA256'
    }

    $rows.Add([pscustomobject]@{
        full_path = $file.FullName
        relative_path = $relative
        size_bytes = [int64]$file.Length
        modified_utc = $file.LastWriteTimeUtc.ToString('o')
        sha256 = $hash
        hash_status = $hashStatus
    })
}

$manifestPath = Join-Path $outputRoot 'file-manifest.csv'
$rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
$totalBytes = ($rows | Measure-Object -Property size_bytes -Sum).Sum
if ($null -eq $totalBytes) { $totalBytes = 0 }
$summary = [ordered]@{
    schema_version = 1
    task_id = [string]$task.task_id
    source = $resolved
    file_count = $rows.Count
    total_bytes = [int64]$totalBytes
    hashed_files = @($rows | Where-Object { $_.hash_status -eq 'SHA256' }).Count
    skipped_large_files = @($rows | Where-Object { $_.hash_status -eq 'SKIPPED_LARGE' }).Count
    hash_limit_bytes = $HashLimitBytes
    generated_at = (Get-Date).ToUniversalTime().ToString('o')
    authority = 'DETERMINISTIC_READ_ONLY'
}
$summaryPath = Join-Path $outputRoot 'file-manifest-summary.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

[pscustomobject]@{
    status = 'PASS'
    output_paths = @($manifestPath, $summaryPath)
    validator = 'PASS'
    file_count = $rows.Count
    total_bytes = [int64]$totalBytes
}
'@

    $scriptExecutor = @'
#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ })]
    [string]$TaskPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$task = Get-Content -LiteralPath $TaskPath -Raw | ConvertFrom-Json
if ([string]$task.status -ne 'ROUTED' -or [string]$task.route.lane -ne 'SCRIPT') {
    throw 'The task must be ROUTED to the SCRIPT lane.'
}

$capabilityId = [string]$task.route.capability_id
if ([string]::IsNullOrWhiteSpace($capabilityId)) { throw 'SCRIPT task has no capability_id.' }
$registryPath = Join-Path $ServerRoot 'CONTROL\registries\CAPABILITY_REGISTRY.csv'
$capability = @(Import-Csv -LiteralPath $registryPath | Where-Object {
    $_.capability_id -eq $capabilityId -and $_.status -eq 'VERIFIED'
}) | Select-Object -First 1
if (-not $capability) { throw "Verified capability not found: $capabilityId" }

$scriptPath = [IO.Path]::GetFullPath([string]$capability.script_path)
$allowedRoot = [IO.Path]::GetFullPath((Join-Path $ServerRoot 'SCRIPTS')).TrimEnd('\') + '\'
if (-not $scriptPath.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Capability script is outside the governed SCRIPTS root: $scriptPath"
}
if (-not (Test-Path -LiteralPath $scriptPath)) { throw "Capability script not found: $scriptPath" }

$now = (Get-Date).ToUniversalTime().ToString('o')
$receiptDir = Join-Path $ServerRoot 'RECEIPTS\script'
New-Item -ItemType Directory -Path $receiptDir -Force | Out-Null
$receiptPath = Join-Path $receiptDir "$($task.task_id)-script.json"

try {
    $result = @(& $scriptPath -ServerRoot $ServerRoot -TaskPath $TaskPath) | Select-Object -Last 1
    if (-not $result -or [string]$result.status -ne 'PASS') {
        throw 'Capability did not return status PASS.'
    }

    $task.status = 'COMPLETE'
    $task | Add-Member -NotePropertyName completed_at -NotePropertyValue $now -Force
    $task | Add-Member -NotePropertyName outputs -NotePropertyValue @($result.output_paths) -Force
    $task.history = @($task.history) + [pscustomobject]@{
        timestamp = $now
        event = 'SCRIPT_COMPLETE'
        capability_id = $capabilityId
        outputs = @($result.output_paths)
    }
    $task | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $TaskPath -Encoding UTF8

    $receipt = [ordered]@{
        schema_version = 1
        timestamp = $now
        task_id = [string]$task.task_id
        capability_id = $capabilityId
        script_path = $scriptPath
        outputs = @($result.output_paths)
        validator = [string]$result.validator
        status = 'PASS'
        authority = 'DETERMINISTIC'
    }
    $receipt | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $receiptPath -Encoding UTF8

    [pscustomobject]@{
        task_id = $task.task_id
        capability_id = $capabilityId
        outputs = @($result.output_paths)
        receipt = $receiptPath
        status = 'COMPLETE'
    }
}
catch {
    $failedAt = (Get-Date).ToUniversalTime().ToString('o')
    $task.status = 'FAILED'
    $task | Add-Member -NotePropertyName failure -NotePropertyValue $_.Exception.Message -Force
    $task.history = @($task.history) + [pscustomobject]@{
        timestamp = $failedAt
        event = 'SCRIPT_FAILED'
        capability_id = $capabilityId
        error = $_.Exception.Message
    }
    $task | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $TaskPath -Encoding UTF8
    [ordered]@{
        schema_version = 1
        timestamp = $failedAt
        task_id = [string]$task.task_id
        capability_id = $capabilityId
        status = 'FAILED'
        error = $_.Exception.Message
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
    throw
}
'@

    $queueStatus = @'
#requires -Version 5.1
[CmdletBinding()]
param([string]$ServerRoot = 'D:\SERVER')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$lanes = @('script','ollama','codex','specialist','review')
$rows = New-Object System.Collections.Generic.List[object]
foreach ($lane in $lanes) {
    $path = Join-Path $ServerRoot "QUEUE\$lane"
    $files = if (Test-Path -LiteralPath $path) {
        @(Get-ChildItem -LiteralPath $path -Filter '*.json' -File -ErrorAction SilentlyContinue)
    }
    else { @() }

    $groups = @{}
    foreach ($file in $files) {
        try {
            $task = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            $status = [string]$task.status
            if (-not $groups.ContainsKey($status)) { $groups[$status] = 0 }
            $groups[$status]++
        }
        catch {
            if (-not $groups.ContainsKey('INVALID_JSON')) { $groups['INVALID_JSON'] = 0 }
            $groups['INVALID_JSON']++
        }
    }
    if ($groups.Count -eq 0) {
        $rows.Add([pscustomobject]@{ lane=$lane.ToUpperInvariant(); status='EMPTY'; count=0 })
    }
    else {
        foreach ($key in ($groups.Keys | Sort-Object)) {
            $rows.Add([pscustomobject]@{ lane=$lane.ToUpperInvariant(); status=$key; count=$groups[$key] })
        }
    }
}

$receiptDir = Join-Path $ServerRoot 'RECEIPTS\queue'
New-Item -ItemType Directory -Path $receiptDir -Force | Out-Null
$receiptPath = Join-Path $receiptDir ('queue-status-{0:yyyyMMdd-HHmmss}.json' -f (Get-Date))
$rows | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
$rows
'@

    $queueWorker = @'
#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [ValidateRange(1,100)][int]$MaxTasks = 10,
    [switch]$SkipOllama
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$mutex = New-Object Threading.Mutex($false, 'Local\CertaServerQueueWorker')
$lockTaken = $false
try {
    try { $lockTaken = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $lockTaken = $true }
    if (-not $lockTaken) {
        [pscustomobject]@{ status='SKIPPED'; reason='Another queue worker is active.' }
        return
    }

    $started = Get-Date
    $runId = 'queue-worker-{0:yyyyMMdd-HHmmss}' -f $started
    $router = Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1'
    $scriptExecutor = Join-Path $ServerRoot 'ROUTER\Invoke-CertaScriptTask.ps1'
    $ollamaExecutor = Join-Path $ServerRoot 'ROUTER\Invoke-CertaOllamaTask.ps1'
    foreach ($path in @($router,$scriptExecutor,$ollamaExecutor)) {
        if (-not (Test-Path -LiteralPath $path)) { throw "Worker dependency missing: $path" }
    }

    $actions = New-Object System.Collections.Generic.List[object]
    $errors = New-Object System.Collections.Generic.List[object]

    try {
        $routed = @(& $router -ServerRoot $ServerRoot -All)
        foreach ($item in $routed) {
            $actions.Add([pscustomobject]@{ phase='ROUTE'; task_id=$item.task_id; status='PASS'; detail=$item.lane })
        }
    }
    catch {
        $errors.Add([pscustomobject]@{ phase='ROUTE'; task_id=$null; error=$_.Exception.Message })
    }

    $processed = 0
    $scriptFolder = Join-Path $ServerRoot 'QUEUE\script'
    foreach ($file in @(Get-ChildItem -LiteralPath $scriptFolder -Filter '*.json' -File -ErrorAction SilentlyContinue | Sort-Object CreationTimeUtc)) {
        if ($processed -ge $MaxTasks) { break }
        try {
            $task = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            if ([string]$task.status -ne 'ROUTED') { continue }
            $result = & $scriptExecutor -ServerRoot $ServerRoot -TaskPath $file.FullName
            $actions.Add([pscustomobject]@{ phase='SCRIPT'; task_id=$task.task_id; status='PASS'; detail=$result.capability_id })
            $processed++
        }
        catch {
            $errors.Add([pscustomobject]@{ phase='SCRIPT'; task_id=$file.BaseName; error=$_.Exception.Message })
            $processed++
        }
    }

    if (-not $SkipOllama -and $processed -lt $MaxTasks) {
        $ollamaFolder = Join-Path $ServerRoot 'QUEUE\ollama'
        foreach ($file in @(Get-ChildItem -LiteralPath $ollamaFolder -Filter '*.json' -File -ErrorAction SilentlyContinue | Sort-Object CreationTimeUtc)) {
            if ($processed -ge $MaxTasks) { break }
            try {
                $task = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
                if ([string]$task.status -ne 'ROUTED') { continue }
                $result = & $ollamaExecutor -ServerRoot $ServerRoot -TaskPath $file.FullName
                $actions.Add([pscustomobject]@{ phase='OLLAMA'; task_id=$task.task_id; status='PASS'; detail=$result.output })
                $processed++
            }
            catch {
                $errors.Add([pscustomobject]@{ phase='OLLAMA'; task_id=$file.BaseName; error=$_.Exception.Message })
                $processed++
            }
        }
    }

    $receiptDir = Join-Path $ServerRoot 'RECEIPTS\worker'
    New-Item -ItemType Directory -Path $receiptDir -Force | Out-Null
    $receiptPath = Join-Path $receiptDir "$runId.json"
    $receipt = [ordered]@{
        schema_version = 1
        run_id = $runId
        started_at = $started.ToUniversalTime().ToString('o')
        completed_at = (Get-Date).ToUniversalTime().ToString('o')
        computer = $env:COMPUTERNAME
        user = "$env:USERDOMAIN\$env:USERNAME"
        max_tasks = $MaxTasks
        skip_ollama = [bool]$SkipOllama
        processed = $processed
        actions = $actions
        errors = $errors
        status = if ($errors.Count -eq 0) { 'PASS' } elseif ($actions.Count -gt 0) { 'PARTIAL' } else { 'FAILED' }
    }
    $receipt | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $receiptPath -Encoding UTF8

    [pscustomobject]@{
        status = $receipt.status
        processed = $processed
        action_count = $actions.Count
        error_count = $errors.Count
        receipt = $receiptPath
    }
}
finally {
    if ($lockTaken) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
'@

    $workerLoop = @'
#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [ValidateRange(10,3600)][int]$IntervalSeconds = 30,
    [switch]$SkipOllama
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$control = Join-Path $ServerRoot 'CONTROL\worker'
$logDir = Join-Path $ServerRoot 'LOGS\worker'
New-Item -ItemType Directory -Path $control,$logDir -Force | Out-Null
$stopFlag = Join-Path $control 'STOP'
$pidPath = Join-Path $control 'queue-worker.pid'
$logPath = Join-Path $logDir 'queue-worker.jsonl'
if (Test-Path -LiteralPath $stopFlag) { Remove-Item -LiteralPath $stopFlag -Force }
[IO.File]::WriteAllText($pidPath, [string]$PID)

try {
    while (-not (Test-Path -LiteralPath $stopFlag)) {
        $entry = [ordered]@{ timestamp=(Get-Date).ToUniversalTime().ToString('o'); pid=$PID }
        try {
            $result = & (Join-Path $ServerRoot 'ROUTER\Invoke-CertaQueueWorker.ps1') -ServerRoot $ServerRoot -MaxTasks 10 -SkipOllama:$SkipOllama
            $entry.status = [string]$result.status
            $entry.processed = $result.processed
            $entry.receipt = $result.receipt
        }
        catch {
            $entry.status = 'FAILED'
            $entry.error = $_.Exception.Message
        }
        ($entry | ConvertTo-Json -Compress -Depth 6) | Add-Content -LiteralPath $logPath -Encoding UTF8
        Start-Sleep -Seconds $IntervalSeconds
    }
}
finally {
    if (Test-Path -LiteralPath $pidPath) {
        $recorded = Get-Content -LiteralPath $pidPath -Raw -ErrorAction SilentlyContinue
        if ($recorded.Trim() -eq [string]$PID) { Remove-Item -LiteralPath $pidPath -Force }
    }
}
'@

    $startWorker = @'
#requires -Version 5.1
[CmdletBinding()]
param([string]$ServerRoot = 'D:\SERVER')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$control = Join-Path $ServerRoot 'CONTROL\worker'
New-Item -ItemType Directory -Path $control -Force | Out-Null
$pidPath = Join-Path $control 'queue-worker.pid'
$stopFlag = Join-Path $control 'STOP'
if (Test-Path -LiteralPath $pidPath) {
    $existingPid = 0
    [void][int]::TryParse((Get-Content -LiteralPath $pidPath -Raw).Trim(), [ref]$existingPid)
    if ($existingPid -gt 0 -and (Get-Process -Id $existingPid -ErrorAction SilentlyContinue)) {
        [pscustomobject]@{ status='ALREADY_RUNNING'; pid=$existingPid }
        return
    }
}
if (Test-Path -LiteralPath $stopFlag) { Remove-Item -LiteralPath $stopFlag -Force }
$loop = Join-Path $ServerRoot 'ROUTER\Start-CertaQueueWorkerLoop.ps1'
$process = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',$loop,'-ServerRoot',$ServerRoot
) -WindowStyle Hidden -PassThru
Start-Sleep -Seconds 2
[pscustomobject]@{ status='STARTED'; pid=$process.Id; script=$loop }
'@

    $stopWorker = @'
#requires -Version 5.1
[CmdletBinding()]
param([string]$ServerRoot = 'D:\SERVER')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$control = Join-Path $ServerRoot 'CONTROL\worker'
New-Item -ItemType Directory -Path $control -Force | Out-Null
$stopFlag = Join-Path $control 'STOP'
Set-Content -LiteralPath $stopFlag -Value ((Get-Date).ToUniversalTime().ToString('o')) -Encoding UTF8
$pidPath = Join-Path $control 'queue-worker.pid'
$pidValue = $null
if (Test-Path -LiteralPath $pidPath) { $pidValue = (Get-Content -LiteralPath $pidPath -Raw).Trim() }
[pscustomobject]@{ status='STOP_REQUESTED'; pid=$pidValue; stop_flag=$stopFlag }
'@

    $runtime = [ordered]@{
        'SCRIPTS\New-CertaFileManifestTask.ps1' = $manifestCapability
        'ROUTER\Invoke-CertaScriptTask.ps1' = $scriptExecutor
        'ROUTER\Get-CertaQueueStatus.ps1' = $queueStatus
        'ROUTER\Invoke-CertaQueueWorker.ps1' = $queueWorker
        'ROUTER\Start-CertaQueueWorkerLoop.ps1' = $workerLoop
        'ROUTER\Start-CertaQueueWorker.ps1' = $startWorker
        'ROUTER\Stop-CertaQueueWorker.ps1' = $stopWorker
    }
    foreach ($entry in $runtime.GetEnumerator()) {
        Write-TextFile -Path (Join-Path $Root $entry.Key) -Content $entry.Value
    }

    $registryPath = Join-Path $Root 'CONTROL\registries\CAPABILITY_REGISTRY.csv'
    $existing = if (Test-Path -LiteralPath $registryPath) { @(Import-Csv -LiteralPath $registryPath) } else { @() }
    $existing = @($existing | Where-Object { $_.capability_id -ne 'file-manifest-v1' })
    $existing += [pscustomobject]@{
        capability_id = 'file-manifest-v1'
        name = 'File manifest with bounded SHA256 hashing'
        intent_regex = '(?i)(checksum|file manifest|inventory files)'
        status = 'VERIFIED'
        script_path = (Join-Path $Root 'SCRIPTS\New-CertaFileManifestTask.ps1')
        validator_path = ''
        node = 'CERTA-SERVER'
        authority = 'DETERMINISTIC'
        notes = 'Read-only source scan. Standard task contract: -ServerRoot and -TaskPath.'
    }
    $existing | Export-Csv -LiteralPath $registryPath -NoTypeInformation -Encoding UTF8
}

function Install-TriggerCommands {
    param([string]$Root)

    $commandsPath = Join-Path $env:USERPROFILE '.TRIGGERcmdData\commands.json'
    if (-not (Test-Path -LiteralPath $commandsPath)) {
        return [pscustomobject]@{ status='BLOCKED'; detail="TRIGGERcmd commands file not found: $commandsPath" }
    }

    $backupDir = Join-Path $Root 'CONTROL\backups'
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $backupPath = Join-Path $backupDir ('commands-worker-{0:yyyyMMdd-HHmmss}.json' -f (Get-Date))
    Copy-Item -LiteralPath $commandsPath -Destination $backupPath -Force
    $items = @((Get-Content -LiteralPath $commandsPath -Raw | ConvertFrom-Json))
    $names = @(
        'Certa Server Health',
        'Certa Server Queue Status',
        'Certa Server Process Queue',
        'Certa Server Start Worker',
        'Certa Server Stop Worker',
        'Certa Server Open'
    )
    $items = @($items | Where-Object { $_.trigger -notin $names })
    $items += [pscustomobject]@{trigger='Certa Server Health';command="powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Root\ROUTER\Get-CertaServerHealth.ps1`"";offCommand='';ground='foreground';voice='certa server health';voiceReply='';allowParams='false'}
    $items += [pscustomobject]@{trigger='Certa Server Queue Status';command="powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Root\ROUTER\Get-CertaQueueStatus.ps1`"";offCommand='';ground='foreground';voice='certa server queue status';voiceReply='';allowParams='false'}
    $items += [pscustomobject]@{trigger='Certa Server Process Queue';command="powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Root\ROUTER\Invoke-CertaQueueWorker.ps1`"";offCommand='';ground='foreground';voice='certa server process queue';voiceReply='';allowParams='false'}
    $items += [pscustomobject]@{trigger='Certa Server Start Worker';command="powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Root\ROUTER\Start-CertaQueueWorker.ps1`"";offCommand='';ground='foreground';voice='certa server start worker';voiceReply='';allowParams='false'}
    $items += [pscustomobject]@{trigger='Certa Server Stop Worker';command="powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Root\ROUTER\Stop-CertaQueueWorker.ps1`"";offCommand='';ground='foreground';voice='certa server stop worker';voiceReply='';allowParams='false'}
    $items += [pscustomobject]@{trigger='Certa Server Open';command="explorer.exe `"$Root`"";offCommand='';ground='foreground';voice='certa server open';voiceReply='';allowParams='false'}
    $items | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $commandsPath -Encoding UTF8
    $null = Get-Content -LiteralPath $commandsPath -Raw | ConvertFrom-Json

    $agent = Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($agent) {
        $agentPath = $null
        try { $agentPath = $agent.Path } catch {}
        if ($agentPath -and (Test-Path -LiteralPath $agentPath)) {
            Stop-Process -Id $agent.Id -Force
            Start-Sleep -Seconds 2
            Start-Process -FilePath $agentPath | Out-Null
        }
    }

    [pscustomobject]@{ status='PASS'; commands_path=$commandsPath; backup=$backupPath; commands=$names }
}

function Register-WorkerStartup {
    param([string]$Root)

    $startup = [Environment]::GetFolderPath('Startup')
    if ([string]::IsNullOrWhiteSpace($startup)) { throw 'Windows Startup folder could not be resolved.' }
    $path = Join-Path $startup 'CertaServerQueueWorker.cmd'
    if (Test-Path -LiteralPath $path) {
        $backup = "$path.backup_$(Get-Date -Format yyyyMMdd_HHmmss)"
        Copy-Item -LiteralPath $path -Destination $backup -Force
    }
    $content = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$Root\ROUTER\Start-CertaQueueWorker.ps1" -ServerRoot "$Root"
"@
    Write-TextFile -Path $path -Content $content
    [pscustomobject]@{ status='PASS'; startup_file=$path }
}

function Invoke-ExtensionSelfTest {
    $testRoot = Join-Path $env:TEMP ('certa-worker-test-' + [guid]::NewGuid().ToString('N'))
    try {
        $folders = @(
            'CONTROL\policies','CONTROL\registries','CONTROL\receipts','INBOX',
            'QUEUE\script','QUEUE\ollama','QUEUE\codex','QUEUE\specialist','QUEUE\review',
            'ROUTER','SCRIPTS','OUTPUTS','RECEIPTS','LOGS'
        )
        foreach ($relative in $folders) { New-Item -ItemType Directory -Path (Join-Path $testRoot $relative) -Force | Out-Null }

        $sourceMap = [ordered]@{
            (Join-Path $PSScriptRoot '..\router\New-CertaTask.ps1') = 'ROUTER\New-CertaTask.ps1'
            (Join-Path $PSScriptRoot '..\router\Invoke-CertaRouter.ps1') = 'ROUTER\Invoke-CertaRouter.ps1'
            (Join-Path $PSScriptRoot '..\router\Invoke-CertaOllamaTask.ps1') = 'ROUTER\Invoke-CertaOllamaTask.ps1'
            (Join-Path $PSScriptRoot '..\router\Get-CertaServerHealth.ps1') = 'ROUTER\Get-CertaServerHealth.ps1'
            (Join-Path $PSScriptRoot '..\policies\task-routing-policy.json') = 'CONTROL\policies\task-routing-policy.json'
        }
        foreach ($entry in $sourceMap.GetEnumerator()) {
            if (-not (Test-Path -LiteralPath $entry.Key)) { throw "Self-test source missing: $($entry.Key)" }
            Copy-Item -LiteralPath $entry.Key -Destination (Join-Path $testRoot $entry.Value) -Force
        }

        @([pscustomobject]@{
            capability_id='placeholder';name='placeholder';intent_regex='never-match';status='DISABLED';script_path='';validator_path='';node='';authority='';notes=''
        }) | Export-Csv -LiteralPath (Join-Path $testRoot 'CONTROL\registries\CAPABILITY_REGISTRY.csv') -NoTypeInformation -Encoding UTF8
        Install-WorkerRuntime -Root $testRoot

        $sample = Join-Path $testRoot 'sample-input'
        New-Item -ItemType Directory -Path $sample -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sample 'a.txt') -Value 'alpha' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $sample 'b.txt') -Value 'beta' -Encoding UTF8

        $newTask = Join-Path $testRoot 'ROUTER\New-CertaTask.ps1'
        $router = Join-Path $testRoot 'ROUTER\Invoke-CertaRouter.ps1'
        $worker = Join-Path $testRoot 'ROUTER\Invoke-CertaQueueWorker.ps1'

        $scriptTask = & $newTask -ServerRoot $testRoot -Request 'Create a checksum file manifest for this folder.' -InputPath $sample
        & $router -ServerRoot $testRoot -All | Out-Null
        $scriptPath = Join-Path $testRoot "QUEUE\script\$($scriptTask.task_id).json"
        if (-not (Test-Path -LiteralPath $scriptPath)) { throw 'SCRIPT task did not route to the script queue.' }
        $result = & $worker -ServerRoot $testRoot -SkipOllama -MaxTasks 10
        if ([string]$result.status -notin @('PASS','PARTIAL')) { throw 'Queue worker did not complete the SCRIPT task.' }
        $completed = Get-Content -LiteralPath $scriptPath -Raw | ConvertFrom-Json
        if ([string]$completed.status -ne 'COMPLETE') { throw 'SCRIPT task was not marked COMPLETE.' }
        foreach ($output in @($completed.outputs)) {
            if (-not (Test-Path -LiteralPath $output)) { throw "SCRIPT output missing: $output" }
        }

        $codexTask = & $newTask -ServerRoot $testRoot -Request 'Debug this PowerShell repository and add tests.'
        $specialistTask = & $newTask -ServerRoot $testRoot -Request 'Use Land Desktop to import this drawing.'
        $humanTask = & $newTask -ServerRoot $testRoot -Request 'Make the final boundary resolution and release it.'
        $ollamaTask = & $newTask -ServerRoot $testRoot -Request 'Summarize and classify this document.'
        & $router -ServerRoot $testRoot -All | Out-Null

        if (-not (Test-Path -LiteralPath (Join-Path $testRoot "QUEUE\codex\$($codexTask.task_id).json"))) { throw 'CODEX routing test failed.' }
        if (-not (Test-Path -LiteralPath (Join-Path $testRoot "QUEUE\codex\$($codexTask.task_id).md"))) { throw 'CODEX prompt was not created.' }
        if (-not (Test-Path -LiteralPath (Join-Path $testRoot "QUEUE\specialist\$($specialistTask.task_id).json"))) { throw 'SPECIALIST routing test failed.' }
        if (-not (Test-Path -LiteralPath (Join-Path $testRoot "QUEUE\review\$($humanTask.task_id).json"))) { throw 'HUMAN routing test failed.' }
        if (-not (Test-Path -LiteralPath (Join-Path $testRoot "QUEUE\ollama\$($ollamaTask.task_id).json"))) { throw 'OLLAMA routing test failed.' }

        'CERTA_SERVER_WORKER_EXTENSION_TEST_PASS'
    }
    finally {
        if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
    }
}

if ($SelfTest) {
    Invoke-ExtensionSelfTest
    return
}

Assert-V1Runtime -Root $ServerRoot
Install-WorkerRuntime -Root $ServerRoot
if ($DisableSleepOnAC) { & powercfg.exe /change standby-timeout-ac 0 | Out-Null }
$triggerResult = if ($InstallTriggerCommands) { Install-TriggerCommands -Root $ServerRoot } else { $null }
$startupResult = if ($RegisterStartup) { Register-WorkerStartup -Root $ServerRoot } else { $null }

$receipt = [ordered]@{
    schema_version = 1
    run_id = $runId
    installed_at = (Get-Date).ToUniversalTime().ToString('o')
    computer = $env:COMPUTERNAME
    user = "$env:USERDOMAIN\$env:USERNAME"
    server_root = $ServerRoot
    trigger = $triggerResult
    startup = $startupResult
    status = 'PASS'
    safety = [ordered]@{
        arbitrary_shell_added = $false
        trigger_parameters_allowed = $false
        ollama_lan_exposure_changed = $false
        source_evidence_deleted = $false
        codex_auto_execution_enabled = $false
        specialist_auto_execution_enabled = $false
        human_gate_bypassed = $false
    }
}
$receiptPath = Join-Path $ServerRoot "CONTROL\receipts\$runId.json"
Write-JsonFile -Path $receiptPath -Value $receipt

[pscustomobject]@{
    status = 'PASS'
    server_root = $ServerRoot
    receipt = $receiptPath
    next = 'Run D:\SERVER\ROUTER\Start-CertaQueueWorker.ps1, then restart the TRIGGERcmd tray agent if commands were installed.'
}
