#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [ValidateRange(1,1440)]
    [int]$SmokeMaxAgeMinutes = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

$ServerRoot = [IO.Path]::GetFullPath($ServerRoot).TrimEnd('\')
$statusDirectory = Join-Path $ServerRoot 'CONTROL\status'
$receiptDirectory = Join-Path $ServerRoot 'RECEIPTS\beacon'
New-Item -ItemType Directory -Path $statusDirectory,$receiptDirectory -Force | Out-Null
$lockPath = Join-Path $statusDirectory 'beacon-refresh.lock'
$lockStream = $null
$commandsLockStream = $null
$smokeLockProbe = $null
try {
    try {
        $lockStream = [IO.File]::Open($lockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    }
    catch {
        throw 'Another Certa status beacon refresh is already running.'
    }

    # Bind the health snapshot to the exact catalog generation that will be
    # replaced. All Certa catalog writers honor this lock, and the hash check
    # immediately before replacement catches non-cooperating writers.
    $commandsPath = Join-Path $env:USERPROFILE '.TRIGGERcmdData\commands.json'
    if (-not (Test-Path -LiteralPath $commandsPath)) { throw "TRIGGERcmd commands file not found: $commandsPath" }
    $commandsLockPath = Join-Path (Split-Path -Parent $commandsPath) '.certa-commands.lock'
    try {
        $commandsLockStream = [IO.File]::Open($commandsLockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    }
    catch {
        throw "Another Certa process is updating the TRIGGERcmd catalog: $([string]$_.Exception.Message)"
    }
    $sourceHash = (Get-FileHash -LiteralPath $commandsPath -Algorithm SHA256).Hash

    $runId = [guid]::NewGuid().ToString('N').Substring(0,8).ToUpperInvariant()
    $publishedAt = [DateTimeOffset]::UtcNow
    $beaconStamp = $publishedAt.ToString('yyyyMMddTHHmmssZ')
    $healthStatus = 'ERROR'
    $healthFindings = @()
    $healthError = $null
    $healthScript = Join-Path $ServerRoot 'ROUTER\Get-CertaServerHealth.ps1'
    try {
        if (-not (Test-Path -LiteralPath $healthScript)) { throw "Health script not found: $healthScript" }
        $health = & $healthScript -ServerRoot $ServerRoot -NoReceipt -NoExitCode -AllowMissingBeacon
        $healthStatus = switch ([string]$health.status) {
            'PASS' { 'PASS' }
            'ATTENTION' { 'ATTN' }
            'FAIL' { 'FAIL' }
            default { 'ERROR' }
        }
        $healthFindings = @($health.findings)
    }
    catch {
        $healthStatus = 'ERROR'
        $healthError = [string]$_.Exception.Message
    }

    $smokePath = Join-Path $statusDirectory 'smoke-latest.json'
    $smokeStatus = 'INIT'
    $smokeRunId = $null
    $smokeCompletedAt = $null
    $smokeCompletedValue = $null
    $smokeAgeSeconds = $null
    $smokeError = $null
    $smokeLockPath = Join-Path $statusDirectory 'smoke-test.lock'
    $smokeLockHeld = $false
    try {
        # Hold the smoke lock through evidence classification and catalog commit
        # so the published run cannot change underneath this beacon.
        $smokeLockProbe = [IO.File]::Open($smokeLockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    }
    catch { $smokeLockHeld = $true }
    if ($smokeLockHeld) {
        $smokeStatus = 'RUNNING'
        $smokeError = 'A synthetic end-to-end smoke test is currently running.'
    }
    elseif (Test-Path -LiteralPath $smokePath) {
        try {
            $smoke = Get-Content -LiteralPath $smokePath -Raw | ConvertFrom-Json
            $smokeRunId = [string]$smoke.run_id
            if ([string]$smoke.status -eq 'RUNNING') {
                throw 'Smoke state says RUNNING but no process holds the smoke lock.'
            }
            elseif ([string]$smoke.status -eq 'FAIL') {
                if ([int]$smoke.schema_version -ne 1) { throw 'Failed smoke evidence has an unsupported schema version.' }
                if ([string]$smoke.authority -ne 'SYNTHETIC_TEST_ONLY') { throw 'Failed smoke evidence has unexpected authority.' }
                if ($smokeRunId -notmatch '^smoke-[0-9]{8}-[0-9]{9}-[a-fA-F0-9]{8}$') { throw 'Failed smoke run ID is invalid.' }
                if ([string]::IsNullOrWhiteSpace([string]$smoke.stage) -or [string]$smoke.stage -in @('INITIALIZE','COMPLETE')) {
                    throw 'Failed smoke evidence has an invalid terminal stage.'
                }
                if ([string]::IsNullOrWhiteSpace([string]$smoke.error)) { throw 'Failed smoke evidence has no error.' }
                $immutableFailedSmokeReceipt = Join-Path $ServerRoot "RECEIPTS\smoke\$smokeRunId.json"
                if (-not (Test-Path -LiteralPath $immutableFailedSmokeReceipt -PathType Leaf)) { throw 'Immutable failed-smoke receipt is missing.' }
                if ((Get-FileHash -LiteralPath $immutableFailedSmokeReceipt -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $smokePath -Algorithm SHA256).Hash) {
                    throw 'Latest failed-smoke state does not match its immutable receipt.'
                }
                [DateTimeOffset]$failedSmokeStarted = [DateTimeOffset]::MinValue
                [DateTimeOffset]$failedSmokeCompleted = [DateTimeOffset]::MinValue
                $failedTimestampStyle = [Globalization.DateTimeStyles]::RoundtripKind
                if (-not [DateTimeOffset]::TryParseExact([string]$smoke.started_at,'o',[Globalization.CultureInfo]::InvariantCulture,$failedTimestampStyle,[ref]$failedSmokeStarted)) {
                    throw 'Failed smoke start timestamp is invalid.'
                }
                if (-not [DateTimeOffset]::TryParseExact([string]$smoke.completed_at,'o',[Globalization.CultureInfo]::InvariantCulture,$failedTimestampStyle,[ref]$failedSmokeCompleted)) {
                    throw 'Failed smoke completion timestamp is invalid.'
                }
                if ($failedSmokeStarted.ToUniversalTime() -gt $failedSmokeCompleted.ToUniversalTime()) { throw 'Failed smoke timestamps are out of order.' }
                if (($failedSmokeCompleted.ToUniversalTime() - $failedSmokeStarted.ToUniversalTime()).TotalMinutes -gt 15) { throw 'Failed smoke execution exceeded the 15-minute evidence bound.' }
                $failedSmokeAge = [DateTimeOffset]::UtcNow - $failedSmokeCompleted.ToUniversalTime()
                if ($failedSmokeAge.TotalMinutes -lt -2) { throw 'Failed smoke completion timestamp is in the future.' }
                $smokeCompletedAt = $failedSmokeCompleted.ToUniversalTime().ToString('o')
                $smokeCompletedValue = $failedSmokeCompleted.ToUniversalTime()
                $smokeAgeSeconds = [math]::Round($failedSmokeAge.TotalSeconds,1)
                if ($failedSmokeAge.TotalMinutes -gt $SmokeMaxAgeMinutes) {
                    $smokeStatus = 'STALE'
                    $smokeError = "Latest failed smoke test is older than $SmokeMaxAgeMinutes minutes."
                }
                else {
                    $smokeStatus = 'FAIL'
                    $smokeError = [string]$smoke.error
                }
            }
            elseif ([string]$smoke.status -eq 'PASS') {
                if ([int]$smoke.schema_version -ne 1) { throw 'Smoke evidence has an unsupported schema version.' }
                if ([string]$smoke.stage -ne 'COMPLETE') { throw 'Smoke evidence is not at the COMPLETE stage.' }
                if ([string]$smoke.authority -ne 'SYNTHETIC_TEST_ONLY') { throw 'Smoke evidence has unexpected authority.' }
                if ($smokeRunId -notmatch '^smoke-[0-9]{8}-[0-9]{9}-[a-fA-F0-9]{8}$') { throw 'Smoke run ID is invalid.' }
                $smokeTaskId = [string]$smoke.task_id
                if ($smokeTaskId -notmatch '^task-[0-9]{8}-[0-9]{6}-[a-fA-F0-9]{8}$') { throw 'Smoke task ID is invalid.' }
                $expectedMarker = [string]$smoke.expected_marker
                if ($expectedMarker -cnotmatch '^CERTA_SMOKE_OK_[A-F0-9]{12}$') { throw 'Smoke marker is invalid.' }
                foreach ($booleanName in @('marker_observed','output_nonempty','queue_neutral')) {
                    $booleanProperty = $smoke.PSObject.Properties[$booleanName]
                    if ($null -eq $booleanProperty -or $booleanProperty.Value -isnot [bool] -or -not $booleanProperty.Value) {
                        throw "Smoke evidence does not prove $booleanName."
                    }
                }
                if (-not [string]::IsNullOrWhiteSpace((Get-CertaPropertyValue -InputObject $smoke -Name 'error'))) {
                    throw 'Smoke PASS evidence contains an error.'
                }

                [DateTimeOffset]$smokeStarted = [DateTimeOffset]::MinValue
                [DateTimeOffset]$smokeCompleted = [DateTimeOffset]::MinValue
                $timestampStyle = [Globalization.DateTimeStyles]::RoundtripKind
                if (-not [DateTimeOffset]::TryParseExact([string]$smoke.started_at,'o',[Globalization.CultureInfo]::InvariantCulture,$timestampStyle,[ref]$smokeStarted)) {
                    throw 'Smoke start timestamp is invalid.'
                }
                if (-not [DateTimeOffset]::TryParseExact([string]$smoke.completed_at,'o',[Globalization.CultureInfo]::InvariantCulture,$timestampStyle,[ref]$smokeCompleted)) {
                    throw 'Smoke completion timestamp is invalid.'
                }
                if ($smokeStarted.ToUniversalTime() -gt $smokeCompleted.ToUniversalTime()) { throw 'Smoke timestamps are out of order.' }
                if (($smokeCompleted.ToUniversalTime() - $smokeStarted.ToUniversalTime()).TotalMinutes -gt 15) { throw 'Smoke execution exceeded the 15-minute evidence bound.' }
                $smokeAge = $publishedAt - $smokeCompleted.ToUniversalTime()
                if ($smokeAge.TotalMinutes -lt -2) { throw 'Smoke completion timestamp is in the future.' }
                $smokeCompletedAt = $smokeCompleted.ToUniversalTime().ToString('o')
                $smokeCompletedValue = $smokeCompleted.ToUniversalTime()
                $smokeAgeSeconds = [math]::Round($smokeAge.TotalSeconds,1)

                $expectedEvidencePaths = [ordered]@{
                    output = (Join-Path $ServerRoot "OUTPUTS\ollama\$smokeTaskId.md")
                    routing_receipt = (Join-Path $ServerRoot "RECEIPTS\routing\$smokeTaskId-route.json")
                    ollama_receipt = (Join-Path $ServerRoot "RECEIPTS\ollama\$smokeTaskId-ollama.json")
                    archived_task = (Join-Path $ServerRoot "ARCHIVE\smoke\passed\$smokeTaskId.json")
                }
                foreach ($evidenceName in $expectedEvidencePaths.Keys) {
                    $actualEvidencePath = Get-CertaPropertyValue -InputObject $smoke -Name $evidenceName
                    if ([string]::IsNullOrWhiteSpace($actualEvidencePath)) { throw "Smoke evidence path is missing: $evidenceName" }
                    if (-not [string]::Equals([IO.Path]::GetFullPath($actualEvidencePath),[IO.Path]::GetFullPath([string]$expectedEvidencePaths[$evidenceName]),[StringComparison]::OrdinalIgnoreCase)) {
                        throw "Smoke evidence path is unexpected: $evidenceName"
                    }
                    if (-not (Test-Path -LiteralPath $actualEvidencePath -PathType Leaf)) { throw "Smoke evidence file is missing: $evidenceName" }
                }
                $evidenceHashes = $smoke.PSObject.Properties['evidence_sha256']
                if ($null -eq $evidenceHashes -or $null -eq $evidenceHashes.Value) { throw 'Smoke evidence hashes are missing.' }
                foreach ($evidenceName in $expectedEvidencePaths.Keys) {
                    $expectedEvidenceHash = Get-CertaPropertyValue -InputObject $evidenceHashes.Value -Name $evidenceName
                    if ($expectedEvidenceHash -cnotmatch '^[A-F0-9]{64}$') { throw "Smoke evidence hash is invalid: $evidenceName" }
                    if ((Get-FileHash -LiteralPath ([string]$expectedEvidencePaths[$evidenceName]) -Algorithm SHA256).Hash -cne $expectedEvidenceHash) {
                        throw "Smoke evidence hash does not match: $evidenceName"
                    }
                }
                $immutableSmokeReceipt = Join-Path $ServerRoot "RECEIPTS\smoke\$smokeRunId.json"
                if (-not (Test-Path -LiteralPath $immutableSmokeReceipt -PathType Leaf)) { throw 'Immutable smoke receipt is missing.' }
                if ((Get-FileHash -LiteralPath $immutableSmokeReceipt -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $smokePath -Algorithm SHA256).Hash) {
                    throw 'Latest smoke state does not match its immutable receipt.'
                }
                $outputPath = [string]$expectedEvidencePaths.output
                if ((Get-Item -LiteralPath $outputPath).Length -gt 8192) { throw 'Smoke output is larger than 8 KiB.' }
                $outputText = Get-Content -LiteralPath $outputPath -Raw
                if ([string]::IsNullOrWhiteSpace($outputText) -or $outputText.IndexOf($expectedMarker,[StringComparison]::Ordinal) -lt 0) {
                    throw 'Smoke output does not contain its unique marker.'
                }

                $expectedInboxPath = Join-Path $ServerRoot "INBOX\$smokeTaskId.json"
                $expectedQueuePath = Join-Path $ServerRoot "QUEUE\ollama\$smokeTaskId.json"
                $routingReceipt = Get-Content -LiteralPath ([string]$expectedEvidencePaths.routing_receipt) -Raw | ConvertFrom-Json
                if (
                    [int]$routingReceipt.schema_version -ne 1 -or
                    [string]$routingReceipt.task_id -ne $smokeTaskId -or
                    [string]$routingReceipt.status -ne 'PASS' -or
                    [string]$routingReceipt.lane -ne 'OLLAMA' -or
                    [string]$routingReceipt.reason -ne 'Local-model term matched: classify' -or
                    [string]$routingReceipt.target_node -ne 'CERTA-SERVER' -or
                    -not (Test-CertaBooleanFalseProperty -InputObject $routingReceipt -Name 'dry_run') -or
                    -not [string]::Equals([IO.Path]::GetFullPath([string]$routingReceipt.source),[IO.Path]::GetFullPath($expectedInboxPath),[StringComparison]::OrdinalIgnoreCase) -or
                    -not [string]::Equals([IO.Path]::GetFullPath([string]$routingReceipt.destination),[IO.Path]::GetFullPath($expectedQueuePath),[StringComparison]::OrdinalIgnoreCase)
                ) {
                    throw 'Routing receipt does not prove the expected synthetic OLLAMA route.'
                }

                $smokeModel = Get-CertaPropertyValue -InputObject $smoke -Name 'model'
                if ([string]::IsNullOrWhiteSpace($smokeModel)) { throw 'Smoke model identity is missing.' }
                $ollamaReceipt = Get-Content -LiteralPath ([string]$expectedEvidencePaths.ollama_receipt) -Raw | ConvertFrom-Json
                if (
                    [int]$ollamaReceipt.schema_version -ne 1 -or
                    [string]$ollamaReceipt.task_id -ne $smokeTaskId -or
                    [string]$ollamaReceipt.status -ne 'CANDIDATE_COMPLETE' -or
                    [string]$ollamaReceipt.authority -ne 'CANDIDATE_ONLY' -or
                    [string]$ollamaReceipt.model -ne $smokeModel -or
                    -not [string]::Equals([IO.Path]::GetFullPath([string]$ollamaReceipt.output),[IO.Path]::GetFullPath($outputPath),[StringComparison]::OrdinalIgnoreCase)
                ) {
                    throw 'Ollama receipt does not prove the expected candidate-only execution.'
                }

                $archivedTask = Get-Content -LiteralPath ([string]$expectedEvidencePaths.archived_task) -Raw | ConvertFrom-Json
                $historyEvents = @($archivedTask.history | ForEach-Object { [string]$_.event })
                if (
                    [int]$archivedTask.schema_version -ne 1 -or
                    [string]$archivedTask.task_id -ne $smokeTaskId -or
                    [string]$archivedTask.project_id -ne 'SYSTEM-SMOKE' -or
                    [string]$archivedTask.status -ne 'CANDIDATE_COMPLETE' -or
                    [string]$archivedTask.sensitivity -ne 'NORMAL' -or
                    @($archivedTask.inputs).Count -ne 0 -or
                    [int]$archivedTask.attempts -ne 1 -or
                    [string]$archivedTask.route.lane -ne 'OLLAMA' -or
                    ([string]$archivedTask.request).IndexOf($expectedMarker,[StringComparison]::Ordinal) -lt 0 -or
                    -not [string]::Equals([IO.Path]::GetFullPath([string]$archivedTask.candidate_output),[IO.Path]::GetFullPath($outputPath),[StringComparison]::OrdinalIgnoreCase) -or
                    ($historyEvents -join ',') -ne 'TASK_CREATED,TASK_ROUTED,OLLAMA_CANDIDATE_COMPLETE'
                ) {
                    throw 'Archived task does not prove the completed owned synthetic task.'
                }

                if ($smokeAge.TotalMinutes -gt $SmokeMaxAgeMinutes) {
                    $smokeStatus = 'STALE'
                    $smokeError = "Latest successful smoke test is older than $SmokeMaxAgeMinutes minutes."
                }
                else { $smokeStatus = 'PASS' }
            }
            else { throw "Smoke state is invalid: $($smoke.status)" }
        }
        catch {
            $smokeStatus = 'ERROR'
            $smokeError = [string]$_.Exception.Message
        }
    }

    $backupDirectory = Join-Path $ServerRoot 'CONTROL\backups\triggercmd-beacon'
    New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
    $backupPath = Join-Path $backupDirectory ('commands-{0:yyyyMMdd-HHmmssfff}-{1}.json' -f (Get-Date), $runId)
    Copy-Item -LiteralPath $commandsPath -Destination $backupPath -Force

    $raw = Get-Content -LiteralPath $commandsPath -Raw
    $parsed = $raw | ConvertFrom-Json
    $existingItems = @($parsed)
    $markerPattern = '^Certa Beacon H-(PASS|ATTN|FAIL|ERROR|INIT) S-(PASS|FAIL|ERROR|INIT|STALE|RUNNING) U-([0-9]{8}T[0-9]{6}Z|00000000T000000Z) R-[A-F0-9]{8}$'
    $retainedItems = @()
    $existingMarkers = 0
    foreach ($item in $existingItems) {
        $name = Get-CertaPropertyValue -InputObject $item -Name 'trigger'
        $command = Get-CertaPropertyValue -InputObject $item -Name 'command'
        if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($command)) {
            throw 'TRIGGERcmd catalog contains an invalid row; beacon refresh left the catalog unchanged.'
        }
        if ($name -like 'Certa Beacon H-*') {
            if ($name -cnotmatch $markerPattern) { throw "Invalid reserved Certa beacon command: $name" }
            if (
                $command -ne 'cmd.exe /d /c exit /b 0' -or
                (Get-CertaPropertyValue -InputObject $item -Name 'ground') -ne 'foreground' -or
                -not (Test-CertaBooleanFalseProperty -InputObject $item -Name 'allowParams') -or
                (Get-CertaPropertyValue -InputObject $item -Name 'offCommand') -ne '' -or
                (Get-CertaPropertyValue -InputObject $item -Name 'voice') -ne '' -or
                (Get-CertaPropertyValue -InputObject $item -Name 'voiceReply') -ne ''
            ) {
                throw "Unsafe reserved Certa beacon command: $name"
            }
            $existingMarkers++
            continue
        }
        $retainedItems += $item
    }
    if ($existingMarkers -gt 1) { throw 'Multiple Certa status beacons exist; beacon refresh left the catalog unchanged.' }

    # Stamp and re-evaluate freshness immediately before committing the catalog.
    $publishedAt = [DateTimeOffset]::UtcNow
    $beaconStamp = $publishedAt.ToString('yyyyMMddTHHmmssZ')
    if ($smokeStatus -in @('PASS','FAIL') -and $null -ne $smokeCompletedValue) {
        $finalSmokeAge = $publishedAt - $smokeCompletedValue
        $smokeAgeSeconds = [math]::Round($finalSmokeAge.TotalSeconds,1)
        if ($finalSmokeAge.TotalMinutes -gt $SmokeMaxAgeMinutes) {
            $smokeStatus = 'STALE'
            $smokeError = "Latest terminal smoke test is older than $SmokeMaxAgeMinutes minutes."
        }
    }
    $beaconName = "Certa Beacon H-$healthStatus S-$smokeStatus U-$beaconStamp R-$runId"
    if ($beaconName.Length -gt 64 -or $beaconName -cnotmatch $markerPattern) { throw "Generated beacon name is invalid: $beaconName" }
    $beacon = [pscustomobject][ordered]@{
        trigger = $beaconName
        command = 'cmd.exe /d /c exit /b 0'
        offCommand = ''
        ground = 'foreground'
        voice = ''
        voiceReply = ''
        allowParams = $false
    }
    $updatedItems = @($retainedItems) + @($beacon)
    $temporaryPath = Join-Path (Split-Path -Parent $commandsPath) ('.commands.beacon.{0}.tmp' -f [guid]::NewGuid().ToString('N'))
    $catalogChangeSignaled = $false
    try {
        ConvertTo-Json -InputObject @($updatedItems) -Depth 20 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
        $validatedJson = Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json
        $validatedItems = @($validatedJson)
        $matches = @($validatedItems | Where-Object {
            (Get-CertaPropertyValue -InputObject $_ -Name 'trigger') -cmatch $markerPattern
        })
        if ($matches.Count -ne 1 -or (Get-CertaPropertyValue -InputObject $matches[0] -Name 'trigger') -ne $beaconName) {
            throw 'Status beacon validation failed.'
        }
        if (-not (Test-CertaBooleanFalseProperty -InputObject $matches[0] -Name 'allowParams')) {
            throw 'Status beacon unexpectedly allows parameters.'
        }
        if ((Get-FileHash -LiteralPath $commandsPath -Algorithm SHA256).Hash -ne $sourceHash) {
            throw 'TRIGGERcmd commands changed during beacon refresh; retry instead of overwriting concurrent changes.'
        }
        if ($smokeStatus -eq 'PASS') {
            if ((Get-FileHash -LiteralPath $immutableSmokeReceipt -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $smokePath -Algorithm SHA256).Hash) {
                throw 'Smoke state changed during beacon validation; refresh again.'
            }
            foreach ($evidenceName in $expectedEvidencePaths.Keys) {
                $expectedEvidenceHash = Get-CertaPropertyValue -InputObject $evidenceHashes.Value -Name $evidenceName
                if ((Get-FileHash -LiteralPath ([string]$expectedEvidencePaths[$evidenceName]) -Algorithm SHA256).Hash -cne $expectedEvidenceHash) {
                    throw "Smoke evidence changed during beacon validation: $evidenceName"
                }
            }
        }
        if ($smokeStatus -in @('PASS','FAIL') -and ([DateTimeOffset]::UtcNow - $smokeCompletedValue).TotalMinutes -gt $SmokeMaxAgeMinutes) {
            throw 'Smoke evidence crossed the freshness bound during catalog validation; refresh again.'
        }
        $replacementHash = (Get-FileHash -LiteralPath $temporaryPath -Algorithm SHA256).Hash
        [IO.File]::Replace($temporaryPath,$commandsPath,$null)
        if ((Get-FileHash -LiteralPath $commandsPath -Algorithm SHA256).Hash -ne $replacementHash) {
            throw 'TRIGGERcmd catalog replacement hash verification failed.'
        }
        $writtenJson = Get-Content -LiteralPath $commandsPath -Raw | ConvertFrom-Json
        $writtenMatches = @(@($writtenJson) | Where-Object { (Get-CertaPropertyValue -InputObject $_ -Name 'trigger') -cmatch $markerPattern })
        if ($writtenMatches.Count -ne 1 -or (Get-CertaPropertyValue -InputObject $writtenMatches[0] -Name 'trigger') -ne $beaconName) {
            throw 'Written TRIGGERcmd catalog did not retain the expected status beacon.'
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

    $currentSessionId = [int](Get-Process -Id $PID -ErrorAction Stop).SessionId
    $agentState = Get-CertaTriggerAgentState -SessionId $currentSessionId
    $sessionAgents = @($agentState.controller_processes)
    $electronChildProcesses = @($agentState.electron_child_processes)
    $agent = if ($sessionAgents.Count -eq 1) { $sessionAgents[0] } else { $null }
    $agentProcessId = if ($agent) { [int]$agent.ProcessId } else { $null }

    $statusRecord = [ordered]@{
        schema_version = 1
        published_at = $publishedAt.ToString('o')
        run_id = $runId
        health = $healthStatus
        smoke = $smokeStatus
        smoke_run_id = $smokeRunId
        smoke_completed_at = $smokeCompletedAt
        smoke_age_seconds = $smokeAgeSeconds
        smoke_max_age_minutes = $SmokeMaxAgeMinutes
        beacon = $beaconName
        health_findings = $healthFindings
        health_error = $healthError
        smoke_error = $smokeError
        commands_path = $commandsPath
        commands_backup = $backupPath
        trigger_agent_running = ([bool]$agentState.query_succeeded -and $sessionAgents.Count -eq 1)
        trigger_agent_session_process_count = $sessionAgents.Count
        trigger_agent_process_id = $agentProcessId
        trigger_agent_session_id = $currentSessionId
        trigger_agent_query_succeeded = [bool]$agentState.query_succeeded
        trigger_agent_query_error = $agentState.query_error
        trigger_agent_query_filter = $agentState.query_filter
        trigger_agent_controller_process_ids = @($sessionAgents | ForEach-Object { [int]$_.ProcessId })
        trigger_agent_electron_child_process_count = $electronChildProcesses.Count
        trigger_agent_electron_child_process_ids = @($electronChildProcesses | ForEach-Object { [int]$_.ProcessId })
        catalog_change_signaled = $catalogChangeSignaled
        remote_sync = 'PENDING_REMOTE_BEACON_VERIFICATION'
    }
    $statusPath = Join-Path $statusDirectory 'server-status.json'
    $receiptPath = Join-Path $receiptDirectory ("beacon-$beaconStamp-$runId.json")
    Write-CertaAtomicJson -Value $statusRecord -Path $statusPath -Depth 12
    Write-CertaAtomicJson -Value $statusRecord -Path $receiptPath -Depth 12

    [pscustomobject]$statusRecord
}
finally {
    if ($smokeLockProbe) { $smokeLockProbe.Dispose() }
    if ($commandsLockStream) { $commandsLockStream.Dispose() }
    if ($lockStream) { $lockStream.Dispose() }
}
