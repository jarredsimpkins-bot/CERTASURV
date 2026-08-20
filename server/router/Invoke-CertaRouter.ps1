#requires -Version 5.1
[CmdletBinding(DefaultParameterSetName='Inbox')]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [Parameter(ParameterSetName='Single')]
    [string]$TaskPath,

    [Parameter(ParameterSetName='Inbox')]
    [switch]$All,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Test-CertaTaskRecord.ps1')

function Get-NormalizedFullPath {
    param([Parameter(Mandatory)][string]$Path)
    return [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Path).Path).TrimEnd('\')
}

function Test-DirectChildPath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Directory
    )
    $filePath = Get-NormalizedFullPath -Path $Path
    $directoryPath = Get-NormalizedFullPath -Path $Directory
    return [string]::Equals([IO.Path]::GetDirectoryName($filePath), $directoryPath, [StringComparison]::OrdinalIgnoreCase)
}

function Write-AtomicJson {
    param([Parameter(Mandatory)]$Value, [Parameter(Mandatory)][string]$Path, [int]$Depth = 14)
    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $temporaryPath = Join-Path $parent ('.{0}.{1}.tmp' -f ([IO.Path]::GetFileName($Path)), [guid]::NewGuid().ToString('N'))
    try {
        $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
        $null = Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
    }
}

function Get-Policy {
    param([string]$Root)
    $candidates = @(
        (Join-Path $Root 'CONTROL\policies\task-routing-policy.json'),
        (Join-Path $PSScriptRoot '..\policies\task-routing-policy.json')
    )
    $path = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $path) { throw 'Task routing policy was not found.' }
    return [pscustomobject]@{
        Path = $path
        Policy = (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
    }
}

function Get-Capabilities {
    param([string]$Root)
    $path = Join-Path $Root 'CONTROL\registries\CAPABILITY_REGISTRY.csv'
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    return @(Import-Csv -LiteralPath $path)
}

function Test-TermMatch {
    param([string]$Text, [object[]]$Terms)
    foreach ($term in @($Terms)) {
        if ([string]::IsNullOrWhiteSpace([string]$term)) { continue }
        if ($Text.IndexOf([string]$term, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return [string]$term
        }
    }
    return $null
}

function Get-RouteDecision {
    param(
        [Parameter(Mandatory)]$Task,
        [Parameter(Mandatory)]$Policy,
        [object[]]$Capabilities
    )

    $text = [string]$Task.request
    $allowed = @($Task.allowed_lanes)
    $riskMatch = Test-TermMatch -Text $text -Terms @($Policy.risk_terms.HUMAN)
    if ($riskMatch) {
        return [ordered]@{ lane='HUMAN'; reason="Mandatory human-gated term matched: $riskMatch"; capability_id=$null; target_node=$null; risk=$riskMatch }
    }

    $specialistMatch = Test-TermMatch -Text $text -Terms @($Policy.risk_terms.SPECIALIST)
    if ($specialistMatch) {
        if ($allowed -contains 'SPECIALIST') {
            return [ordered]@{ lane='SPECIALIST'; reason="Specialist term matched: $specialistMatch"; capability_id=$null; target_node='MSI'; risk=$null }
        }
        return [ordered]@{ lane='HUMAN'; reason="Required specialist lane was disallowed; human review is mandatory: $specialistMatch"; capability_id=$null; target_node=$null; risk=$specialistMatch }
    }

    foreach ($capability in @($Capabilities)) {
        if ([string]$capability.status -ne 'VERIFIED') { continue }
        if ([string]::IsNullOrWhiteSpace([string]$capability.intent_regex)) { continue }
        if ($text -match [string]$capability.intent_regex) {
            if ($allowed -contains 'SCRIPT') {
                return [ordered]@{
                    lane='SCRIPT'
                    reason="Verified capability matched: $($capability.capability_id)"
                    capability_id=[string]$capability.capability_id
                    target_node=if ([string]::IsNullOrWhiteSpace([string]$capability.node)) { 'CERTA-SERVER' } else { [string]$capability.node }
                    risk=$null
                }
            }
        }
    }

    $hasInputs = @($Task.inputs).Count -gt 0
    if ([string]$Task.preferred_lane -eq 'OLLAMA' -and $hasInputs) {
        if ($allowed -contains 'CODEX') {
            return [ordered]@{ lane='CODEX'; reason='OLLAMA v1 does not ingest file inputs; routed to CODEX for bounded input handling.'; capability_id=$null; target_node='CERTA-SERVER'; risk=$null }
        }
        return [ordered]@{ lane='HUMAN'; reason='OLLAMA v1 does not ingest file inputs and CODEX is disallowed; human review is mandatory.'; capability_id=$null; target_node=$null; risk='UNSUPPORTED_INPUTS' }
    }

    if ($Task.preferred_lane -and $allowed -contains [string]$Task.preferred_lane) {
        return [ordered]@{ lane=[string]$Task.preferred_lane; reason='Operator supplied an allowed preferred lane.'; capability_id=$null; target_node=$null; risk=$null }
    }

    $ollamaMatch = Test-TermMatch -Text $text -Terms @($Policy.risk_terms.OLLAMA)
    if ($ollamaMatch -and $allowed -contains 'OLLAMA') {
        if ($hasInputs) {
            if ($allowed -contains 'CODEX') {
                return [ordered]@{ lane='CODEX'; reason='OLLAMA v1 does not ingest file inputs; routed to CODEX for bounded input handling.'; capability_id=$null; target_node='CERTA-SERVER'; risk=$null }
            }
            return [ordered]@{ lane='HUMAN'; reason='OLLAMA v1 does not ingest file inputs and CODEX is disallowed; human review is mandatory.'; capability_id=$null; target_node=$null; risk='UNSUPPORTED_INPUTS' }
        }
        return [ordered]@{ lane='OLLAMA'; reason="Local-model term matched: $ollamaMatch"; capability_id=$null; target_node='CERTA-SERVER'; risk=$null }
    }

    $codexMatch = Test-TermMatch -Text $text -Terms @($Policy.risk_terms.CODEX)
    if ($codexMatch -and $allowed -contains 'CODEX') {
        return [ordered]@{ lane='CODEX'; reason="Codex term matched: $codexMatch"; capability_id=$null; target_node='CERTA-SERVER'; risk=$null }
    }

    $defaultLane = [string]$Policy.default_lane
    if (-not ($allowed -contains $defaultLane)) {
        $defaultLane = @('HUMAN','CODEX','OLLAMA','SPECIALIST','SCRIPT') | Where-Object { $allowed -contains $_ } | Select-Object -First 1
    }
    if (-not $defaultLane) { throw "Task $($Task.task_id) has no permitted routing lane." }
    return [ordered]@{ lane=$defaultLane; reason='No verified capability or explicit term matched; using policy default.'; capability_id=$null; target_node='CERTA-SERVER'; risk=$null }
}

function Write-CodexPrompt {
    param([string]$Path, $Task)
    $inputLines = if (@($Task.inputs).Count -gt 0) { @($Task.inputs) | ForEach-Object { "- $_" } } else { @('- None supplied') }
    $content = @"
# CertaSurv Codex Task $($Task.task_id)

**Project:** $($Task.project_id)  
**Sensitivity:** $($Task.sensitivity)  
**Requested outcome:**

$($Task.request)

## Inputs

$($inputLines -join "`n")

## Operating contract

- Work from the server repository/worktree assigned for this task.
- Preserve source evidence and Git history.
- Do not expose secrets.
- Use deterministic scripts for repeatable calculations and conversions.
- Add tests and a validator for new capabilities.
- Write outputs and an execution receipt under $ServerRoot.
- Do not make final professional survey, boundary, legal, credential, destructive, or production-release decisions.
"@
    Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

$policyRecord = Get-Policy -Root $ServerRoot
$capabilities = Get-Capabilities -Root $ServerRoot
$inbox = Join-Path $ServerRoot 'INBOX'
$receiptRoot = Join-Path $ServerRoot 'RECEIPTS\routing'
$claimRoot = Join-Path $ServerRoot 'STAGING\router'
$archiveRoot = Join-Path $ServerRoot 'ARCHIVE\tasks'
New-Item -ItemType Directory -Path $inbox,$receiptRoot,$claimRoot,$archiveRoot -Force | Out-Null

$taskFiles = @()
if ($PSCmdlet.ParameterSetName -eq 'Single') {
    if (-not (Test-Path -LiteralPath $TaskPath)) { throw "Task file not found: $TaskPath" }
    if (-not (Test-DirectChildPath -Path $TaskPath -Directory $inbox)) {
        throw "TaskPath must be a direct child of the Certa inbox: $inbox"
    }
    $taskFiles = @(Get-Item -LiteralPath $TaskPath)
}
else {
    $taskFiles = @(Get-ChildItem -LiteralPath $inbox -Filter '*.json' -File | Sort-Object CreationTimeUtc)
    if (-not $All) { $taskFiles = @($taskFiles | Select-Object -First 1) }
}

$results = New-Object System.Collections.Generic.List[object]
foreach ($file in $taskFiles) {
    $originalPath = $file.FullName
    $workingPath = $originalPath
    $claimed = $false
    $task = $null
    $taskId = [IO.Path]::GetFileNameWithoutExtension($file.Name)

    if (-not $DryRun) {
        $claimPath = Join-Path $claimRoot $file.Name
        try {
            Move-Item -LiteralPath $originalPath -Destination $claimPath -ErrorAction Stop
            $workingPath = $claimPath
            $claimed = $true
        }
        catch {
            $results.Add([pscustomobject]@{ task_id=$taskId; status='SKIPPED'; detail='Task was already claimed by another router process.' })
            continue
        }
    }

    try {
        $task = Get-Content -LiteralPath $workingPath -Raw | ConvertFrom-Json
        $null = Assert-CertaTaskRecord -Task $task -SourcePath $workingPath
        $taskId = [string]$task.task_id
        if ([string]$task.status -ne 'NEW') {
            if ($claimed) { Move-Item -LiteralPath $workingPath -Destination $originalPath -Force }
            $results.Add([pscustomobject]@{ task_id=$task.task_id; status='SKIPPED'; detail="Task status is $($task.status)." })
            continue
        }

        $decision = Get-RouteDecision -Task $task -Policy $policyRecord.Policy -Capabilities $capabilities
        $routedAt = (Get-Date).ToUniversalTime().ToString('o')
        $task.status = if ($decision.lane -eq 'HUMAN') { 'REVIEW_REQUIRED' } else { 'ROUTED' }
        $task.route = [pscustomobject]@{
            lane = $decision.lane
            reason = $decision.reason
            capability_id = $decision.capability_id
            target_node = $decision.target_node
            routed_at = $routedAt
            policy_path = $policyRecord.Path
        }
        $task.attempts = [int]$task.attempts + 1
        $history = @($task.history)
        $history += [pscustomobject]@{ timestamp=$routedAt; event='TASK_ROUTED'; lane=$decision.lane; reason=$decision.reason }
        $task.history = $history

        $laneFolderName = switch ($decision.lane) {
            'SCRIPT' { 'script' }
            'OLLAMA' { 'ollama' }
            'CODEX' { 'codex' }
            'SPECIALIST' { 'specialist' }
            'HUMAN' { 'review' }
            default { throw "Unsupported lane: $($decision.lane)" }
        }
        $destination = Join-Path $ServerRoot "QUEUE\$laneFolderName"
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        $destinationPath = Join-Path $destination $file.Name
        $archivePath = Join-Path $archiveRoot $file.Name
        if (-not $DryRun -and (Test-Path -LiteralPath $destinationPath)) {
            throw "Routed task destination already exists: $destinationPath"
        }
        if (-not $DryRun -and (Test-Path -LiteralPath $archivePath)) {
            throw "Task archive already exists: $archivePath"
        }

        if (-not $DryRun) {
            Write-AtomicJson -Value $task -Path $destinationPath
            if ($decision.lane -eq 'CODEX') {
                Write-CodexPrompt -Path ([IO.Path]::ChangeExtension($destinationPath, '.md')) -Task $task
            }
            Move-Item -LiteralPath $workingPath -Destination $archivePath
            $claimed = $false
        }

        $receipt = [ordered]@{
            schema_version = 1
            timestamp = $routedAt
            task_id = [string]$task.task_id
            source = $originalPath
            destination = $destinationPath
            dry_run = [bool]$DryRun
            lane = $decision.lane
            reason = $decision.reason
            capability_id = $decision.capability_id
            target_node = $decision.target_node
            status = 'PASS'
        }
        $receiptPath = Join-Path $receiptRoot "$($task.task_id)-route.json"
        if (-not $DryRun) { Write-AtomicJson -Value $receipt -Path $receiptPath -Depth 8 }

        $results.Add([pscustomobject]@{
            task_id = $task.task_id
            lane = $decision.lane
            reason = $decision.reason
            destination = $destinationPath
            dry_run = [bool]$DryRun
        })
    }
    catch {
        $failure = $_
        if ($claimed -and (Test-Path -LiteralPath $workingPath) -and -not (Test-Path -LiteralPath $originalPath)) {
            Move-Item -LiteralPath $workingPath -Destination $originalPath -Force
        }
        $failureReceipt = [ordered]@{
            schema_version = 1
            timestamp = (Get-Date).ToUniversalTime().ToString('o')
            task_id = $taskId
            source = $originalPath
            status = 'FAILED'
            error = [string]$failure.Exception.Message
        }
        $failurePath = Join-Path $receiptRoot ("{0}-route-failed-{1:yyyyMMdd-HHmmssfff}.json" -f $taskId, (Get-Date))
        Write-AtomicJson -Value $failureReceipt -Path $failurePath -Depth 8
        if ($PSCmdlet.ParameterSetName -eq 'Single') { throw $failure }
        $results.Add([pscustomobject]@{ task_id=$taskId; status='FAILED'; detail=[string]$failure.Exception.Message })
    }
}

$results
