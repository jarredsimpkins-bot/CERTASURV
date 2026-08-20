#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [string]$Model = 'certard-local',

    [switch]$NoExitCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-CertaAtomicJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$Depth = 12
    )

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

$started = [DateTimeOffset]::UtcNow
$runId = 'smoke-{0:yyyyMMdd-HHmmssfff}-{1}' -f $started, ([guid]::NewGuid().ToString('N').Substring(0,8))
$expectedMarker = 'CERTA_SMOKE_OK_{0}' -f ([guid]::NewGuid().ToString('N').Substring(0,12).ToUpperInvariant())
$receiptDirectory = Join-Path $ServerRoot 'RECEIPTS\smoke'
$statusDirectory = Join-Path $ServerRoot 'CONTROL\status'
New-Item -ItemType Directory -Path $receiptDirectory,$statusDirectory -Force | Out-Null
$receiptPath = Join-Path $receiptDirectory "$runId.json"
$latestPath = Join-Path $statusDirectory 'smoke-latest.json'

$result = [ordered]@{
    schema_version = 1
    run_id = $runId
    started_at = $started.ToString('o')
    completed_at = $null
    status = 'RUNNING'
    stage = 'INITIALIZE'
    authority = 'SYNTHETIC_TEST_ONLY'
    model = $Model
    expected_marker = $expectedMarker
    task_id = $null
    route = $null
    output = $null
    ollama_receipt = $null
    routing_receipt = $null
    archived_task = $null
    evidence_sha256 = $null
    cleanup_artifacts = @()
    queue_neutral = $null
    output_nonempty = $false
    marker_observed = $false
    tokens_per_second = $null
    error = $null
}

$lockPath = Join-Path $statusDirectory 'smoke-test.lock'
$lockStream = $null
try {
    $lockStream = [IO.File]::Open($lockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
}
catch {
    $result.status = 'FAIL'
    $result.stage = 'LOCK'
    $result.error = 'Another Certa end-to-end smoke test is already running.'
    $result.completed_at = [DateTimeOffset]::UtcNow.ToString('o')
    Write-CertaAtomicJson -Value $result -Path $receiptPath -Depth 14
    [pscustomobject]$result
    if (-not $NoExitCode) { exit 2 }
    return
}

try {
    # Publish RUNNING while holding the exclusive smoke lock so a concurrent
    # beacon refresh cannot re-advertise an older PASS during model execution.
    Write-CertaAtomicJson -Value $result -Path $latestPath -Depth 14
    $result.stage = 'CHECK_COMPONENTS'
    foreach ($path in @(
        (Join-Path $ServerRoot 'ROUTER\New-CertaTask.ps1'),
        (Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1'),
        (Join-Path $ServerRoot 'ROUTER\Invoke-CertaOllamaTask.ps1')
    )) {
        if (-not (Test-Path -LiteralPath $path)) { throw "Required smoke-test component is missing: $path" }
    }

    $result.stage = 'CHECK_MODEL'
    $tags = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 10
    $models = @($tags.models | ForEach-Object { [string]$_.name })
    if (@($models | Where-Object { $_ -eq $Model -or $_ -like "$Model`:*" }).Count -eq 0) {
        throw "Required local model is not available: $Model"
    }

    $result.stage = 'CREATE_TASK'
    $created = & (Join-Path $ServerRoot 'ROUTER\New-CertaTask.ps1') `
        -ServerRoot $ServerRoot `
        -ProjectId 'SYSTEM-SMOKE' `
        -Request "Classify this synthetic router smoke check as TEST_ONLY and include the exact marker $expectedMarker in a short candidate response. Do not access files, change settings, or perform external actions." `
        -Sensitivity NORMAL

    $result.task_id = [string]$created.task_id
    $result.stage = 'ROUTE_TASK'
    $routeResults = @(& (Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1') -ServerRoot $ServerRoot -TaskPath ([string]$created.path))
    if ($routeResults.Count -ne 1) { throw 'Router smoke test did not return exactly one result.' }
    $route = $routeResults[0]
    $result.route = [ordered]@{
        lane = [string]$route.lane
        destination = [string]$route.destination
        reason = [string]$route.reason
    }
    if ([string]$route.lane -ne 'OLLAMA') { throw "Synthetic task routed to '$($route.lane)' instead of OLLAMA." }
    if ([string]$route.reason -ne 'Local-model term matched: classify') {
        throw "Router returned an unexpected reason: $($route.reason)"
    }
    $expectedQueuePath = Join-Path $ServerRoot "QUEUE\ollama\$($created.task_id).json"
    if (-not [string]::Equals([IO.Path]::GetFullPath([string]$route.destination),[IO.Path]::GetFullPath($expectedQueuePath),[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Router returned an unexpected OLLAMA queue destination.'
    }

    $routingReceiptPath = Join-Path $ServerRoot "RECEIPTS\routing\$($created.task_id)-route.json"
    $archivePath = Join-Path $ServerRoot "ARCHIVE\tasks\$($created.task_id).json"
    $inboxPath = Join-Path $ServerRoot "INBOX\$($created.task_id).json"
    $stagingPath = Join-Path $ServerRoot "STAGING\router\$($created.task_id).json"
    if (-not (Test-Path -LiteralPath $routingReceiptPath)) { throw 'Routing receipt was not created.' }
    if (-not (Test-Path -LiteralPath $archivePath)) { throw 'Original task was not archived.' }
    if (Test-Path -LiteralPath $inboxPath) { throw 'Synthetic task remained in the inbox after routing.' }
    if (Test-Path -LiteralPath $stagingPath) { throw 'Synthetic task remained claimed in router staging.' }
    $originalArchive = Get-Content -LiteralPath $archivePath -Raw | ConvertFrom-Json
    if (
        [int]$originalArchive.schema_version -ne 1 -or
        [string]$originalArchive.task_id -ne [string]$created.task_id -or
        [string]$originalArchive.project_id -ne 'SYSTEM-SMOKE' -or
        [string]$originalArchive.status -ne 'NEW' -or
        [string]$originalArchive.sensitivity -ne 'NORMAL' -or
        @($originalArchive.inputs).Count -ne 0 -or
        ([string]$originalArchive.request).IndexOf($expectedMarker,[StringComparison]::Ordinal) -lt 0
    ) {
        throw 'Original task archive does not match the owned synthetic task.'
    }
    $routingReceipt = Get-Content -LiteralPath $routingReceiptPath -Raw | ConvertFrom-Json
    $result.routing_receipt = $routingReceiptPath
    if ([int]$routingReceipt.schema_version -ne 1 -or [string]$routingReceipt.status -ne 'PASS' -or [string]$routingReceipt.lane -ne 'OLLAMA') {
        throw 'Routing receipt did not record a successful OLLAMA route.'
    }
    if ([string]$routingReceipt.task_id -ne [string]$created.task_id -or [bool]$routingReceipt.dry_run) {
        throw 'Routing receipt task identity or dry-run state is invalid.'
    }
    if (-not [string]::Equals([IO.Path]::GetFullPath([string]$routingReceipt.source),[IO.Path]::GetFullPath([string]$created.path),[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Routing receipt source does not match the synthetic inbox task.'
    }
    if (-not [string]::Equals([IO.Path]::GetFullPath([string]$routingReceipt.destination),[IO.Path]::GetFullPath([string]$route.destination),[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Routing receipt destination does not match the routed task.'
    }
    if ([string]$routingReceipt.reason -ne 'Local-model term matched: classify') {
        throw "Routing receipt recorded an unexpected reason: $($routingReceipt.reason)"
    }
    if ([string]$routingReceipt.target_node -ne 'CERTA-SERVER') { throw 'Routing receipt target node is not CERTA-SERVER.' }

    $result.stage = 'EXECUTE_OLLAMA'
    $execution = & (Join-Path $ServerRoot 'ROUTER\Invoke-CertaOllamaTask.ps1') `
        -ServerRoot $ServerRoot `
        -TaskPath ([string]$route.destination) `
        -Model $Model

    if ([string]$execution.status -ne 'CANDIDATE_COMPLETE') {
        throw "Ollama executor returned status '$($execution.status)'."
    }
    if ([string]$execution.task_id -ne [string]$created.task_id) { throw 'Ollama executor returned the wrong task identity.' }
    $expectedOutputPath = Join-Path $ServerRoot "OUTPUTS\ollama\$($created.task_id).md"
    $expectedOllamaReceiptPath = Join-Path $ServerRoot "RECEIPTS\ollama\$($created.task_id)-ollama.json"
    if (-not [string]::Equals([IO.Path]::GetFullPath([string]$execution.output),[IO.Path]::GetFullPath($expectedOutputPath),[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Ollama executor returned an unexpected output path.'
    }
    if (-not [string]::Equals([IO.Path]::GetFullPath([string]$execution.receipt),[IO.Path]::GetFullPath($expectedOllamaReceiptPath),[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Ollama executor returned an unexpected receipt path.'
    }
    if (-not (Test-Path -LiteralPath ([string]$execution.output))) { throw 'Ollama candidate output file was not created.' }
    if (-not (Test-Path -LiteralPath ([string]$execution.receipt))) { throw 'Ollama execution receipt was not created.' }

    $candidate = Get-Content -LiteralPath ([string]$execution.output) -Raw
    if ([string]::IsNullOrWhiteSpace($candidate)) { throw 'Ollama candidate output was empty.' }
    if ((Get-Item -LiteralPath ([string]$execution.output)).Length -gt 8192) { throw 'Ollama candidate output exceeded the 8 KiB smoke-test bound.' }
    if ($candidate.IndexOf($expectedMarker,[StringComparison]::Ordinal) -lt 0) {
        throw "Ollama candidate did not return the unique marker $expectedMarker."
    }
    $queuedTask = Get-Content -LiteralPath ([string]$route.destination) -Raw | ConvertFrom-Json
    if ([int]$queuedTask.schema_version -ne 1 -or [string]$queuedTask.task_id -ne [string]$created.task_id -or [string]$queuedTask.status -ne 'CANDIDATE_COMPLETE') {
        throw 'Queued task identity or completed status is invalid.'
    }
    if ([string]$queuedTask.route.lane -ne 'OLLAMA' -or @($queuedTask.inputs).Count -ne 0 -or [int]$queuedTask.attempts -ne 1) {
        throw 'Completed synthetic task has invalid route, inputs, or attempt count.'
    }
    if (-not [string]::Equals([IO.Path]::GetFullPath([string]$queuedTask.candidate_output),[IO.Path]::GetFullPath([string]$execution.output),[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Completed task candidate_output does not match the executor output.'
    }
    $historyEvents = @($queuedTask.history | ForEach-Object { [string]$_.event })
    $expectedEvents = @('TASK_CREATED','TASK_ROUTED','OLLAMA_CANDIDATE_COMPLETE')
    if (($historyEvents -join ',') -ne ($expectedEvents -join ',')) {
        throw "Queued task history order is invalid: $($historyEvents -join ',')"
    }
    $ollamaReceipt = Get-Content -LiteralPath ([string]$execution.receipt) -Raw | ConvertFrom-Json
    if ([int]$ollamaReceipt.schema_version -ne 1 -or [string]$ollamaReceipt.task_id -ne [string]$created.task_id -or [string]$ollamaReceipt.status -ne 'CANDIDATE_COMPLETE') {
        throw 'Ollama receipt does not match the synthetic task and completed status.'
    }
    if ([string]$ollamaReceipt.authority -ne 'CANDIDATE_ONLY') { throw 'Ollama receipt authority is not CANDIDATE_ONLY.' }
    if ([string]$ollamaReceipt.model -ne $Model) { throw 'Ollama receipt model does not match the smoke-test model.' }
    if (-not [string]::Equals([IO.Path]::GetFullPath([string]$ollamaReceipt.output),[IO.Path]::GetFullPath([string]$execution.output),[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Ollama receipt output does not match the executor output.'
    }

    $result.output = [string]$execution.output
    $result.ollama_receipt = [string]$execution.receipt
    $result.output_nonempty = $true
    $result.marker_observed = $true
    $result.tokens_per_second = $execution.tokens_per_second
    $result.stage = 'ARCHIVE_COMPLETED_TASK'
    $pendingArchiveDirectory = Join-Path $ServerRoot 'ARCHIVE\smoke\pending'
    $passedArchiveDirectory = Join-Path $ServerRoot 'ARCHIVE\smoke\passed'
    New-Item -ItemType Directory -Path $pendingArchiveDirectory,$passedArchiveDirectory -Force | Out-Null
    $pendingArchivePath = Join-Path $pendingArchiveDirectory "$($created.task_id).json"
    $smokeArchivePath = Join-Path $passedArchiveDirectory "$($created.task_id).json"
    if ((Test-Path -LiteralPath $pendingArchivePath) -or (Test-Path -LiteralPath $smokeArchivePath)) {
        throw "Smoke archive already exists for task $($created.task_id)."
    }
    Move-Item -LiteralPath ([string]$route.destination) -Destination $pendingArchivePath
    if (Test-Path -LiteralPath ([string]$route.destination)) { throw 'Completed smoke task remained in the OLLAMA queue after archival.' }
    if (-not (Test-Path -LiteralPath $pendingArchivePath)) { throw 'Pending smoke task archive was not created.' }
    $archivedTask = Get-Content -LiteralPath $pendingArchivePath -Raw | ConvertFrom-Json
    if ([int]$archivedTask.schema_version -ne 1 -or [string]$archivedTask.task_id -ne [string]$created.task_id -or [string]$archivedTask.status -ne 'CANDIDATE_COMPLETE') {
        throw 'Archived smoke task does not match the completed synthetic task.'
    }
    Move-Item -LiteralPath $pendingArchivePath -Destination $smokeArchivePath
    if ((Test-Path -LiteralPath $pendingArchivePath) -or -not (Test-Path -LiteralPath $smokeArchivePath)) {
        throw 'Validated smoke task was not committed to the passed archive.'
    }
    $result.archived_task = $smokeArchivePath
    $result.evidence_sha256 = [ordered]@{
        output = (Get-FileHash -LiteralPath ([string]$result.output) -Algorithm SHA256).Hash
        routing_receipt = (Get-FileHash -LiteralPath ([string]$result.routing_receipt) -Algorithm SHA256).Hash
        ollama_receipt = (Get-FileHash -LiteralPath ([string]$result.ollama_receipt) -Algorithm SHA256).Hash
        archived_task = (Get-FileHash -LiteralPath ([string]$result.archived_task) -Algorithm SHA256).Hash
    }
    $result.queue_neutral = $true
    $result.stage = 'COMPLETE'
    $result.status = 'PASS'
}
catch {
    $result.status = 'FAIL'
    $result.error = [string]$_.Exception.Message
    try {
        if (-not [string]::IsNullOrWhiteSpace([string]$result.task_id)) {
            $activeCandidates = @(
                [pscustomobject]@{ name='inbox'; path=(Join-Path $ServerRoot "INBOX\$($result.task_id).json") },
                [pscustomobject]@{ name='staging'; path=(Join-Path $ServerRoot "STAGING\router\$($result.task_id).json") },
                [pscustomobject]@{ name='script'; path=(Join-Path $ServerRoot "QUEUE\script\$($result.task_id).json") },
                [pscustomobject]@{ name='ollama'; path=(Join-Path $ServerRoot "QUEUE\ollama\$($result.task_id).json") },
                [pscustomobject]@{ name='codex'; path=(Join-Path $ServerRoot "QUEUE\codex\$($result.task_id).json") },
                [pscustomobject]@{ name='specialist'; path=(Join-Path $ServerRoot "QUEUE\specialist\$($result.task_id).json") },
                [pscustomobject]@{ name='review'; path=(Join-Path $ServerRoot "QUEUE\review\$($result.task_id).json") },
                [pscustomobject]@{ name='pending'; path=(Join-Path $ServerRoot "ARCHIVE\smoke\pending\$($result.task_id).json") },
                [pscustomobject]@{ name='passed'; path=(Join-Path $ServerRoot "ARCHIVE\smoke\passed\$($result.task_id).json") }
            )
            $cleanupWarnings = New-Object System.Collections.Generic.List[string]
            $failedArchiveDirectory = Join-Path $ServerRoot "ARCHIVE\smoke\failed\$($result.task_id)"
            if (Test-Path -LiteralPath $failedArchiveDirectory) {
                $failedArchiveDirectory = "$failedArchiveDirectory-$runId"
            }

            foreach ($candidateRecord in $activeCandidates) {
                $activePath = [string]$candidateRecord.path
                if ([string]$candidateRecord.name -eq 'staging' -and (Test-Path -LiteralPath $activePath)) {
                    $cleanupDeadline = (Get-Date).AddSeconds(5)
                    while ((Test-Path -LiteralPath $activePath) -and (Get-Date) -lt $cleanupDeadline) {
                        Start-Sleep -Milliseconds 250
                    }
                    if (Test-Path -LiteralPath $activePath) {
                        $cleanupWarnings.Add("Router staging remained active; it was not moved: $activePath")
                        continue
                    }
                }
                if (-not (Test-Path -LiteralPath $activePath)) { continue }
                try {
                    $failedTask = Get-Content -LiteralPath $activePath -Raw | ConvertFrom-Json
                    $isOwnedSyntheticTask = (
                        [string]$failedTask.task_id -eq [string]$result.task_id -and
                        [string]$failedTask.project_id -eq 'SYSTEM-SMOKE' -and
                        [string]$failedTask.sensitivity -eq 'NORMAL' -and
                        @($failedTask.inputs).Count -eq 0 -and
                        ([string]$failedTask.request).IndexOf($expectedMarker,[StringComparison]::Ordinal) -ge 0
                    )
                    if (-not $isOwnedSyntheticTask) {
                        $cleanupWarnings.Add("Refused to move an unverified smoke-test artifact: $activePath")
                        continue
                    }

                    New-Item -ItemType Directory -Path $failedArchiveDirectory -Force | Out-Null
                    $failedArchivePath = Join-Path $failedArchiveDirectory "$($candidateRecord.name).json"
                    Move-Item -LiteralPath $activePath -Destination $failedArchivePath
                    $result.cleanup_artifacts += $failedArchivePath
                    if (-not $result.archived_task) { $result.archived_task = $failedArchivePath }

                    if ([string]$candidateRecord.name -eq 'codex') {
                        $companionPath = [IO.Path]::ChangeExtension($activePath,'.md')
                        $companionArchivePath = Join-Path $failedArchiveDirectory 'codex.md'
                    }
                    if ([string]$candidateRecord.name -eq 'codex' -and (Test-Path -LiteralPath $companionPath)) {
                        Move-Item -LiteralPath $companionPath -Destination $companionArchivePath
                        $result.cleanup_artifacts += $companionArchivePath
                    }
                }
                catch {
                    $cleanupWarnings.Add("Cleanup failed for $activePath`: $([string]$_.Exception.Message)")
                }
            }

            $codexCompanionPath = Join-Path $ServerRoot "QUEUE\codex\$($result.task_id).md"
            if (Test-Path -LiteralPath $codexCompanionPath) {
                try {
                    $originalEvidencePath = Join-Path $ServerRoot "ARCHIVE\tasks\$($result.task_id).json"
                    if (-not (Test-Path -LiteralPath $originalEvidencePath)) {
                        throw 'The matching archived intake record is unavailable.'
                    }
                    $originalEvidence = Get-Content -LiteralPath $originalEvidencePath -Raw | ConvertFrom-Json
                    $isOwnedCompanion = (
                        [string]$originalEvidence.task_id -eq [string]$result.task_id -and
                        [string]$originalEvidence.project_id -eq 'SYSTEM-SMOKE' -and
                        [string]$originalEvidence.sensitivity -eq 'NORMAL' -and
                        @($originalEvidence.inputs).Count -eq 0 -and
                        ([string]$originalEvidence.request).IndexOf($expectedMarker,[StringComparison]::Ordinal) -ge 0
                    )
                    if (-not $isOwnedCompanion) { throw 'The matching archived intake record is not owned by this smoke run.' }
                    New-Item -ItemType Directory -Path $failedArchiveDirectory -Force | Out-Null
                    $companionArchivePath = Join-Path $failedArchiveDirectory 'codex.md'
                    Move-Item -LiteralPath $codexCompanionPath -Destination $companionArchivePath
                    $result.cleanup_artifacts += $companionArchivePath
                }
                catch {
                    $cleanupWarnings.Add("Cleanup failed for $codexCompanionPath`: $([string]$_.Exception.Message)")
                }
            }

            $remainingActivePaths = @($activeCandidates | ForEach-Object { [string]$_.path }) + @($codexCompanionPath)
            $remainingActivePaths = @($remainingActivePaths | Where-Object { Test-Path -LiteralPath $_ })
            $result.queue_neutral = ($remainingActivePaths.Count -eq 0)
            if ($cleanupWarnings.Count -gt 0) {
                $result.error = "$($result.error) Cleanup warning: $($cleanupWarnings -join ' ')"
            }
        }
        else { $result.queue_neutral = $true }
    }
    catch {
        $result.error = "$($result.error) Cleanup warning: $([string]$_.Exception.Message)"
    }
}
finally {
    try {
        $result.completed_at = [DateTimeOffset]::UtcNow.ToString('o')
        Write-CertaAtomicJson -Value $result -Path $receiptPath -Depth 14
        Write-CertaAtomicJson -Value $result -Path $latestPath -Depth 14
    }
    finally {
        if ($lockStream) { $lockStream.Dispose() }
    }
}

[pscustomobject]$result
if ($result.status -ne 'PASS' -and -not $NoExitCode) { exit 2 }
