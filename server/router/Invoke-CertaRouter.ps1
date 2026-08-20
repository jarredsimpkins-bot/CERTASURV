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
    if ($riskMatch -and $allowed -contains 'HUMAN') {
        return [ordered]@{ lane='HUMAN'; reason="Human-gated term matched: $riskMatch"; capability_id=$null; target_node=$null; risk=$riskMatch }
    }

    $specialistMatch = Test-TermMatch -Text $text -Terms @($Policy.risk_terms.SPECIALIST)
    if ($specialistMatch -and $allowed -contains 'SPECIALIST') {
        return [ordered]@{ lane='SPECIALIST'; reason="Specialist term matched: $specialistMatch"; capability_id=$null; target_node='MSI'; risk=$null }
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

    if ($Task.preferred_lane -and $allowed -contains [string]$Task.preferred_lane) {
        return [ordered]@{ lane=[string]$Task.preferred_lane; reason='Operator supplied an allowed preferred lane.'; capability_id=$null; target_node=$null; risk=$null }
    }

    $ollamaMatch = Test-TermMatch -Text $text -Terms @($Policy.risk_terms.OLLAMA)
    if ($ollamaMatch -and $allowed -contains 'OLLAMA') {
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
- Write outputs and an execution receipt under D:\SERVER.
- Do not make final professional survey, boundary, legal, credential, destructive, or production-release decisions.
"@
    Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

$policyRecord = Get-Policy -Root $ServerRoot
$capabilities = Get-Capabilities -Root $ServerRoot
$inbox = Join-Path $ServerRoot 'INBOX'
$receiptRoot = Join-Path $ServerRoot 'RECEIPTS\routing'
New-Item -ItemType Directory -Path $receiptRoot -Force | Out-Null

$taskFiles = @()
if ($PSCmdlet.ParameterSetName -eq 'Single') {
    if (-not (Test-Path -LiteralPath $TaskPath)) { throw "Task file not found: $TaskPath" }
    $taskFiles = @(Get-Item -LiteralPath $TaskPath)
}
else {
    if (-not (Test-Path -LiteralPath $inbox)) { New-Item -ItemType Directory -Path $inbox -Force | Out-Null }
    $taskFiles = @(Get-ChildItem -LiteralPath $inbox -Filter '*.json' -File | Sort-Object CreationTimeUtc)
    if (-not $All) { $taskFiles = @($taskFiles | Select-Object -First 1) }
}

$results = New-Object System.Collections.Generic.List[object]
foreach ($file in $taskFiles) {
    $task = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
    if ([string]$task.status -ne 'NEW') {
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

    if (-not $DryRun) {
        $task | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $destinationPath -Encoding UTF8
        if ($decision.lane -eq 'CODEX') {
            Write-CodexPrompt -Path ([IO.Path]::ChangeExtension($destinationPath, '.md')) -Task $task
        }
        Remove-Item -LiteralPath $file.FullName -Force
    }

    $receipt = [ordered]@{
        schema_version = 1
        timestamp = $routedAt
        task_id = [string]$task.task_id
        source = $file.FullName
        destination = $destinationPath
        dry_run = [bool]$DryRun
        lane = $decision.lane
        reason = $decision.reason
        capability_id = $decision.capability_id
        target_node = $decision.target_node
        status = 'PASS'
    }
    $receiptPath = Join-Path $receiptRoot "$($task.task_id)-route.json"
    if (-not $DryRun) { $receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $receiptPath -Encoding UTF8 }

    $results.Add([pscustomobject]@{
        task_id = $task.task_id
        lane = $decision.lane
        reason = $decision.reason
        destination = $destinationPath
        dry_run = [bool]$DryRun
    })
}

$results
