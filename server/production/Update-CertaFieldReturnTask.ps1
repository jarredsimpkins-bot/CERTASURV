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
. (Join-Path $PSScriptRoot 'CertaServer.Common.ps1')

function Import-CertaPointEvents {
    param(
        [Parameter(Mandatory)][IO.FileInfo]$File,
        [Parameter(Mandatory)][string]$DatasetRole,
        [int]$SequenceOffset = 0
    )

    $events = New-Object System.Collections.Generic.List[object]
    $index = 0
    foreach ($row in @(Import-Csv -LiteralPath $File.FullName)) {
        $index++
        $point = Get-CertaNormalizedPoint -Row $row -SourceName $File.Name -Index ($SequenceOffset + $index)
        $recordKey = "{0}|{1}|{2:R}|{3:R}|{4:R}|{5}|{6}" -f
            $DatasetRole,$point.P,[double]$point.N,[double]$point.E,[double]$point.EL,$point.DESC,$index
        $events.Add([pscustomobject]@{
            record_id = Get-CertaRecordId -Value $recordKey
            dataset_role = $DatasetRole
            source_file = $File.FullName
            source_row = $index
            P = $point.P
            N = $point.N
            E = $point.E
            EL = $point.EL
            DESC = $point.DESC
            Status = $point.Status
            ObservedAt = $point.ObservedAt
            Latitude = $point.Latitude
            Longitude = $point.Longitude
        })
    }
    return @($events)
}

$task = Get-CertaTaskRecord -TaskPath $TaskPath
$projectId = Get-CertaProjectId -Task $task
$projectRoot = New-CertaProjectLayout -ServerRoot $ServerRoot -ProjectId $projectId
$taskId = [string]$task.task_id

$csvFiles = @(Get-CertaInputFiles -InputPath @($task.inputs) | Where-Object { $_.Extension -eq '.csv' })
if ($csvFiles.Count -lt 1) { throw 'field-return-v1 requires at least one CSV input.' }

$currentFile = if ($csvFiles.Count -ge 2) { $csvFiles[0] } else { $null }
$returnFile = if ($csvFiles.Count -ge 2) { $csvFiles[1] } else { $csvFiles[0] }

$allEvents = New-Object System.Collections.Generic.List[object]
if ($currentFile) {
    foreach ($event in @(Import-CertaPointEvents -File $currentFile -DatasetRole 'CURRENT_WORKMAP')) {
        $allEvents.Add($event)
    }
}
foreach ($event in @(Import-CertaPointEvents -File $returnFile -DatasetRole 'FIELD_RETURN' -SequenceOffset 1000000)) {
    $allEvents.Add($event)
}

$uniqueEvents = @($allEvents | Group-Object record_id | ForEach-Object { $_.Group | Select-Object -First 1 })
if ($uniqueEvents.Count -eq 0) { throw 'No point events were found in the supplied CSV files.' }

$latestByPoint = New-Object System.Collections.Generic.List[object]
foreach ($group in @($uniqueEvents | Group-Object P)) {
    $ordered = @($group.Group | Sort-Object @{
        Expression = { if ($_.dataset_role -eq 'FIELD_RETURN') { 1 } else { 0 } }
    }, @{
        Expression = { [int]$_.source_row }
    })
    $latest = $ordered | Select-Object -Last 1
    $latestByPoint.Add([pscustomobject]@{
        P = $latest.P
        N = $latest.N
        E = $latest.E
        EL = $latest.EL
        DESC = $latest.DESC
        Status = $latest.Status
        Source = [IO.Path]::GetFileName($latest.source_file)
        ObservedAt = $latest.ObservedAt
        Latitude = $latest.Latitude
        Longitude = $latest.Longitude
        latest_record_id = $latest.record_id
        event_count = $group.Count
    })
}

$tolerance = 5.0
$toleranceMatch = [regex]::Match([string]$task.request, '(?i)(?:within|tolerance)\s*(?<value>\d+(?:\.\d+)?)\s*(?:ft|feet)?')
if ($toleranceMatch.Success) {
    $tolerance = ConvertTo-CertaDouble -Value $toleranceMatch.Groups['value'].Value -FieldName 'field-return tolerance'
}

$searchEvents = @($uniqueEvents | Where-Object { $_.Status -eq 'SEARCH' })
$resolutionCandidates = @($uniqueEvents | Where-Object {
    $_.dataset_role -eq 'FIELD_RETURN' -and $_.Status -in @('FOUND','SET')
})
$resolutionRows = New-Object System.Collections.Generic.List[object]
foreach ($search in $searchEvents) {
    $nearest = $null
    $nearestDistance = [double]::PositiveInfinity
    foreach ($candidate in $resolutionCandidates) {
        $deltaN = [double]$candidate.N - [double]$search.N
        $deltaE = [double]$candidate.E - [double]$search.E
        $distance = [math]::Sqrt(($deltaN*$deltaN) + ($deltaE*$deltaE))
        if ($distance -lt $nearestDistance) {
            $nearestDistance = $distance
            $nearest = $candidate
        }
    }

    $resolved = $null -ne $nearest -and $nearestDistance -le $tolerance
    $resolutionRows.Add([pscustomobject]@{
        search_record_id = $search.record_id
        search_point = $search.P
        search_northing = $search.N
        search_easting = $search.E
        search_description = $search.DESC
        nearest_field_record_id = if ($nearest) { $nearest.record_id } else { '' }
        nearest_field_point = if ($nearest) { $nearest.P } else { '' }
        nearest_field_status = if ($nearest) { $nearest.Status } else { '' }
        distance = if ($nearest) { $nearestDistance } else { $null }
        tolerance = $tolerance
        resolved = $resolved
        resolution_status = if ($resolved) { 'CANDIDATE_RESOLVED_REVIEW_REQUIRED' } else { 'UNRESOLVED' }
    })
}

$outputRoot = Join-Path $projectRoot "03_FIELD_WORK\RETURNS\$taskId"
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$eventsPath = Join-Path $outputRoot 'POINT_EVENT_REGISTER.csv'
$currentStatePath = Join-Path $outputRoot 'CURRENT_POINT_STATE.csv'
$resolutionPath = Join-Path $outputRoot 'SEARCH_RESOLUTION.csv'
$unresolvedPath = Join-Path $outputRoot 'UNRESOLVED_STAKEOUT.csv'
$manifestPath = Join-Path $outputRoot 'FIELD_RETURN_RECEIPT.json'

$uniqueEvents | Sort-Object dataset_role,source_file,source_row |
    Export-Csv -LiteralPath $eventsPath -NoTypeInformation -Encoding UTF8
$latestByPoint | Sort-Object P |
    Export-Csv -LiteralPath $currentStatePath -NoTypeInformation -Encoding UTF8
$resolutionRows | Export-Csv -LiteralPath $resolutionPath -NoTypeInformation -Encoding UTF8
@($resolutionRows | Where-Object { -not $_.resolved } | ForEach-Object {
    [pscustomobject]@{
        P = $_.search_point
        N = $_.search_northing
        E = $_.search_easting
        EL = 0
        DESC = $_.search_description
        Status = 'SEARCH'
        Source = 'FIELD_RETURN_RECONCILIATION'
    }
}) | Export-Csv -LiteralPath $unresolvedPath -NoTypeInformation -Encoding UTF8

$nestedTaskPath = Join-Path $outputRoot 'UPDATED_WORKMAP_TASK.json'
$nestedTask = [ordered]@{
    schema_version = 1
    task_id = "$taskId-workmap"
    project_id = $projectId
    request = 'Build updated workmap from current point state after field return.'
    inputs = @($currentStatePath)
    sensitivity = [string]$task.sensitivity
}
Write-CertaJsonFile -Path $nestedTaskPath -Value $nestedTask

$workmapScript = Join-Path $PSScriptRoot 'New-CertaWorkmapTask.ps1'
if (-not (Test-Path -LiteralPath $workmapScript)) { throw "Workmap capability is missing: $workmapScript" }
$workmapResult = & $workmapScript -ServerRoot $ServerRoot -TaskPath $nestedTaskPath
if (-not $workmapResult -or [string]$workmapResult.status -ne 'PASS') {
    throw 'Updated workmap generation failed.'
}

$manifest = [ordered]@{
    schema_version = 1
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
    task_id = $taskId
    project_id = $projectId
    current_source = if ($currentFile) { $currentFile.FullName } else { $null }
    field_return_source = $returnFile.FullName
    event_count = $uniqueEvents.Count
    current_point_count = $latestByPoint.Count
    search_event_count = $searchEvents.Count
    candidate_resolved_count = @($resolutionRows | Where-Object { $_.resolved }).Count
    unresolved_count = @($resolutionRows | Where-Object { -not $_.resolved }).Count
    tolerance = $tolerance
    workmap_outputs = @($workmapResult.output_paths)
    original_files_modified = $false
    unique_point_event_lineage_preserved = $true
    authority = 'FIELD_RETURN_RECONCILIATION_REVIEW_REQUIRED'
    status = 'PASS'
}
Write-CertaJsonFile -Path $manifestPath -Value $manifest

$outputs = @($eventsPath,$currentStatePath,$resolutionPath,$unresolvedPath,$nestedTaskPath,$manifestPath) + @($workmapResult.output_paths)
$null = Test-CertaOutputPaths -Path $outputs

[pscustomobject]@{
    status = 'PASS'
    output_paths = $outputs
    validator = 'PASS'
    project_id = $projectId
    event_count = $uniqueEvents.Count
    unresolved_count = @($resolutionRows | Where-Object { -not $_.resolved }).Count
    output_root = $outputRoot
}
