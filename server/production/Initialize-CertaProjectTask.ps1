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

$task = Get-CertaTaskRecord -TaskPath $TaskPath
$projectId = Get-CertaProjectId -Task $task
$projectRoot = New-CertaProjectLayout -ServerRoot $ServerRoot -ProjectId $projectId
$taskId = [string]$task.task_id
$runRoot = Join-Path $projectRoot "07_INTERNAL_LOGS\INTAKE\$taskId"
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null

$sourceFiles = @(Get-CertaInputFiles -InputPath @($task.inputs))
$stagingRoots = @(
    (Join-Path $ServerRoot 'STAGING'),
    (Join-Path $ServerRoot 'INBOX_FILES')
)
$evidenceFolder = Join-Path $projectRoot '01_INTAKE_SCOPE\SOURCE_EVIDENCE'
$registryRows = New-Object System.Collections.Generic.List[object]

foreach ($file in $sourceFiles) {
    $hash = Get-CertaSha256 -Path $file.FullName
    $copyEligible = $false
    foreach ($stagingRoot in $stagingRoots) {
        if (Test-Path -LiteralPath $stagingRoot) {
            if (Test-CertaPathUnderRoot -Path $file.FullName -Root $stagingRoot) {
                $copyEligible = $true
                break
            }
        }
    }

    $copyAction = 'REFERENCE_ONLY'
    $projectPath = $null
    if ($copyEligible) {
        $copy = Copy-CertaEvidenceFile -Source $file.FullName -DestinationFolder $evidenceFolder
        $copyAction = [string]$copy.action
        $projectPath = [string]$copy.path
        if (-not $hash.sha256) { $hash = [pscustomobject]@{ sha256=$copy.sha256; status='SHA256'; limit_bytes=$hash.limit_bytes } }
    }

    $registryRows.Add([pscustomobject]@{
        project_id = $projectId
        source_path = $file.FullName
        project_path = $projectPath
        filename = $file.Name
        extension = $file.Extension.ToLowerInvariant()
        size_bytes = [int64]$file.Length
        modified_utc = $file.LastWriteTimeUtc.ToString('o')
        sha256 = $hash.sha256
        hash_status = $hash.status
        copy_action = $copyAction
        authority = 'SOURCE_EVIDENCE'
        sensitivity = [string]$task.sensitivity
        task_id = $taskId
    })
}

$sourceRegistryPath = Join-Path $runRoot 'SOURCE_REGISTRY.csv'
$registryRows | Export-Csv -LiteralPath $sourceRegistryPath -NoTypeInformation -Encoding UTF8

$names = @($registryRows | ForEach-Object { $_.filename.ToUpperInvariant() })
$extensions = @($registryRows | ForEach-Object { $_.extension.ToLowerInvariant() })
$requirements = @(
    [pscustomobject]@{
        requirement='SCOPE_OR_INTAKE'
        present=[bool](@($names | Where-Object { $_ -match 'INTAKE|SCOPE|ESTIMATE|PROPOSAL' }).Count)
        detail='Intake/scope/estimate/proposal evidence'
    },
    [pscustomobject]@{
        requirement='LOCATION_CONTEXT'
        present=[bool](@($extensions | Where-Object { $_ -in @('.kml','.kmz','.shp','.gpkg','.geojson') }).Count)
        detail='KML/KMZ/GIS subject location context'
    },
    [pscustomobject]@{
        requirement='RECORD_SOURCE'
        present=[bool](@($names | Where-Object { $_ -match 'DEED|PLAT|MAP.?CARD|TAX.?MAP' }).Count)
        detail='Deed, plat, map card, or tax-map evidence'
    },
    [pscustomobject]@{
        requirement='PROJECT_ID'
        present=$true
        detail=$projectId
    }
)
$missingPath = Join-Path $runRoot 'MISSING_REQUIREMENTS.csv'
$requirements | Where-Object { -not $_.present } |
    Export-Csv -LiteralPath $missingPath -NoTypeInformation -Encoding UTF8

$manifestPath = Join-Path $projectRoot 'PROJECT_MANIFEST.json'
if (Test-Path -LiteralPath $manifestPath) {
    $historyFolder = Join-Path $projectRoot '07_INTERNAL_LOGS\MANIFEST_HISTORY'
    New-Item -ItemType Directory -Path $historyFolder -Force | Out-Null
    $historyPath = Join-Path $historyFolder ('PROJECT_MANIFEST-{0:yyyyMMdd-HHmmssfff}.json' -f (Get-Date))
    Copy-Item -LiteralPath $manifestPath -Destination $historyPath -Force
}

$manifest = [ordered]@{
    schema_version = 1
    project_id = $projectId
    server_root = $ServerRoot
    project_root = $projectRoot
    status = 'ACTIVE'
    current_stage = 'INTAKE'
    source_count = $registryRows.Count
    missing_requirement_count = @($requirements | Where-Object { -not $_.present }).Count
    last_intake_task = $taskId
    last_intake_at = (Get-Date).ToUniversalTime().ToString('o')
    authority = 'GOVERNED_PROJECT_RECORD'
    source_registry = $sourceRegistryPath
    original_sources_preserved = $true
}
Write-CertaJsonFile -Path $manifestPath -Value $manifest

$receiptPath = Join-Path $runRoot 'INTAKE_RECEIPT.json'
$receipt = [ordered]@{
    schema_version = 1
    task_id = $taskId
    project_id = $projectId
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
    source_count = $registryRows.Count
    copied_verified_count = @($registryRows | Where-Object { $_.copy_action -match 'COPIED|REUSED' }).Count
    reference_only_count = @($registryRows | Where-Object { $_.copy_action -eq 'REFERENCE_ONLY' }).Count
    manifest = $manifestPath
    source_registry = $sourceRegistryPath
    missing_requirements = $missingPath
    source_files_deleted = 0
    status = 'PASS'
}
Write-CertaJsonFile -Path $receiptPath -Value $receipt

$outputs = @($manifestPath, $sourceRegistryPath, $missingPath, $receiptPath)
$null = Test-CertaOutputPaths -Path $outputs

[pscustomobject]@{
    status = 'PASS'
    output_paths = $outputs
    validator = 'PASS'
    project_id = $projectId
    source_count = $registryRows.Count
    project_root = $projectRoot
}
