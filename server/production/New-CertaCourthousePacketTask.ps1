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

function Get-DocumentType {
    param([Parameter(Mandatory)][IO.FileInfo]$File)

    $name = $File.Name.ToUpperInvariant()
    if ($name -match 'MAP.?CARD|ASSESS') { return 'MAP_CARD' }
    if ($name -match 'DEED|INSTRUMENT|\bDB\b') { return 'DEED' }
    if ($name -match 'PLAT|\bPB\b|SURVEY') { return 'PLAT' }
    if ($name -match 'IDX|INDEX|GRANTOR|GRANTEE') { return 'IDX' }
    if ($name -match 'TAX.?MAP|PARCEL.?MAP') { return 'TAX_MAP' }
    if ($name -match 'TITLE|CHAIN') { return 'TITLE' }
    if ($File.Extension -match '(?i)\.pdf|\.tif|\.tiff|\.jpg|\.jpeg|\.png|\.heic') { return 'DOCUMENT_IMAGE' }
    return 'MISC'
}

function Get-BookPageFromName {
    param([Parameter(Mandatory)][string]$Name)

    $upper = [IO.Path]::GetFileNameWithoutExtension($Name).ToUpperInvariant()
    $deed = [regex]::Match($upper, '(?:DB|DEED[\s_-]*BOOK)[\s_-]*(?<book>\d+).*?(?:PG|PAGE)[\s_-]*(?<page>\d+)')
    if ($deed.Success) {
        return [pscustomobject]@{ book_type='DB'; book=$deed.Groups['book'].Value; page=$deed.Groups['page'].Value }
    }

    $plat = [regex]::Match($upper, '(?:PB|PLAT[\s_-]*BOOK)[\s_-]*(?<book>\d+).*?(?:PG|PAGE)[\s_-]*(?<page>\d+)')
    if ($plat.Success) {
        return [pscustomobject]@{ book_type='PB'; book=$plat.Groups['book'].Value; page=$plat.Groups['page'].Value }
    }

    return [pscustomobject]@{ book_type=$null; book=$null; page=$null }
}

$task = Get-CertaTaskRecord -TaskPath $TaskPath
$projectId = Get-CertaProjectId -Task $task
$projectRoot = New-CertaProjectLayout -ServerRoot $ServerRoot -ProjectId $projectId
$taskId = [string]$task.task_id
$researchRoot = Join-Path $projectRoot '02_COURTHOUSE_RESEARCH'
$packetRoot = Join-Path $researchRoot "PACKETS\$taskId"
$parcelRoot = Join-Path $researchRoot 'PARCELS'
New-Item -ItemType Directory -Path $packetRoot,$parcelRoot -Force | Out-Null

$inputFiles = @(Get-CertaInputFiles -InputPath @($task.inputs))
$parcelCsv = $inputFiles | Where-Object {
    $_.Extension -eq '.csv' -and $_.Name -match '(?i)parcel|touching|adjoin'
} | Select-Object -First 1

$parcelRows = New-Object System.Collections.Generic.List[object]
if ($parcelCsv) {
    $index = 0
    foreach ($row in @(Import-Csv -LiteralPath $parcelCsv.FullName)) {
        $index++
        $parcelId = [string](Get-CertaPropertyValue -Object $row -Name @('ParcelId','Parcel_ID','GISPID','TaxParcelId','ID'))
        $taxMap = [string](Get-CertaPropertyValue -Object $row -Name @('TaxMap','Map','TM'))
        $parcel = [string](Get-CertaPropertyValue -Object $row -Name @('Parcel','ParcelNumber','P'))
        $district = [string](Get-CertaPropertyValue -Object $row -Name @('District','MagisterialDistrict'))
        $owner = [string](Get-CertaPropertyValue -Object $row -Name @('Owner','OwnerName'))
        $role = [string](Get-CertaPropertyValue -Object $row -Name @('Role','ParcelRole'))
        if ([string]::IsNullOrWhiteSpace($role)) { $role = if ($index -eq 1) { 'SUBJECT' } else { 'ADJOINER' } }

        if ([string]::IsNullOrWhiteSpace($parcelId)) {
            $parcelId = (@($taxMap,$parcel) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }) -join '-'
        }
        if ([string]::IsNullOrWhiteSpace($parcelId)) { $parcelId = "PARCEL-$index" }

        $parcelRows.Add([pscustomobject]@{
            parcel_id = $parcelId
            role = $role.ToUpperInvariant()
            tax_map = $taxMap
            parcel = $parcel
            district = $district
            owner = $owner
        })
    }
}

if ($parcelRows.Count -eq 0) {
    $parcelRows.Add([pscustomobject]@{
        parcel_id = 'SUBJECT'
        role = 'SUBJECT'
        tax_map = ''
        parcel = ''
        district = ''
        owner = ''
    })
}

$parcelFolderMap = @{}
foreach ($parcelRow in $parcelRows) {
    $labelParts = @()
    if (-not [string]::IsNullOrWhiteSpace([string]$parcelRow.tax_map)) { $labelParts += "TM_$($parcelRow.tax_map)" }
    if (-not [string]::IsNullOrWhiteSpace([string]$parcelRow.parcel)) { $labelParts += "P_$($parcelRow.parcel)" }
    if ($labelParts.Count -eq 0) { $labelParts += [string]$parcelRow.parcel_id }
    $folderName = ConvertTo-CertaSafeName -Value ($labelParts -join '_') -MaximumLength 100
    $folder = Join-Path $parcelRoot $folderName
    foreach ($subfolder in @('MAP_CARD','DEEDS','PLATS','IDX','OCR','PLOT_SOURCE','MISC')) {
        New-Item -ItemType Directory -Path (Join-Path $folder $subfolder) -Force | Out-Null
    }
    $parcelFolderMap[[string]$parcelRow.parcel_id] = $folder
}

$researchRows = New-Object System.Collections.Generic.List[object]
$evidenceRows = New-Object System.Collections.Generic.List[object]
$documentCounts = @{}

foreach ($file in $inputFiles) {
    if ($parcelCsv -and $file.FullName -eq $parcelCsv.FullName) { continue }

    $documentType = Get-DocumentType -File $file
    if (-not $documentCounts.ContainsKey($documentType)) { $documentCounts[$documentType] = 0 }
    $documentCounts[$documentType]++

    $assignedParcel = $parcelRows | Where-Object {
        $tokens = @($_.parcel_id,$_.tax_map,$_.parcel) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
        @($tokens | Where-Object { $file.Name.IndexOf([string]$_, [StringComparison]::OrdinalIgnoreCase) -ge 0 }).Count -gt 0
    } | Select-Object -First 1
    if (-not $assignedParcel) { $assignedParcel = $parcelRows | Where-Object { $_.role -eq 'SUBJECT' } | Select-Object -First 1 }
    if (-not $assignedParcel) { $assignedParcel = $parcelRows[0] }

    $destinationCategory = switch ($documentType) {
        'MAP_CARD' { 'MAP_CARD' }
        'DEED' { 'DEEDS' }
        'PLAT' { 'PLATS' }
        'IDX' { 'IDX' }
        default { 'MISC' }
    }

    $destinationFolder = Join-Path $parcelFolderMap[[string]$assignedParcel.parcel_id] $destinationCategory
    $copyAction = 'REFERENCE_ONLY_LARGE'
    $copiedPath = $null
    $sha256 = $null
    if ($file.Length -le 524288000) {
        $copy = Copy-CertaEvidenceFile -Source $file.FullName -DestinationFolder $destinationFolder
        $copyAction = [string]$copy.action
        $copiedPath = [string]$copy.path
        $sha256 = [string]$copy.sha256
    }
    else {
        $hash = Get-CertaSha256 -Path $file.FullName
        $sha256 = $hash.sha256
    }

    $bookPage = Get-BookPageFromName -Name $file.Name
    $researchRows.Add([pscustomobject]@{
        project_id = $projectId
        parcel_id = [string]$assignedParcel.parcel_id
        parcel_role = [string]$assignedParcel.role
        document_type = $documentType
        source_file = $file.FullName
        packet_file = $copiedPath
        book_type = $bookPage.book_type
        book = $bookPage.book
        page = $bookPage.page
        instrument_number = ''
        grantor = ''
        grantee = ''
        execution_date = ''
        recording_date = ''
        acreage = ''
        back_reference = ''
        prior_survey_reference = ''
        plot_source_status = if ($documentType -in @('DEED','PLAT')) { 'CANDIDATE_SOURCE_PRESENT' } else { 'NOT_EVALUATED' }
        extraction_status = 'PENDING_REVIEW_OR_OCR'
        notes = ''
    })

    $evidenceRows.Add([pscustomobject]@{
        parcel_id = [string]$assignedParcel.parcel_id
        document_type = $documentType
        source_path = $file.FullName
        packet_path = $copiedPath
        size_bytes = [int64]$file.Length
        modified_utc = $file.LastWriteTimeUtc.ToString('o')
        sha256 = $sha256
        copy_action = $copyAction
        authority = 'SOURCE_EVIDENCE'
    })
}

$parcelRegisterPath = Join-Path $packetRoot 'PARCEL_REGISTER.csv'
$parcelRows | Export-Csv -LiteralPath $parcelRegisterPath -NoTypeInformation -Encoding UTF8

$researchLogPath = Join-Path $packetRoot 'MASTER_RESEARCH_LOG.csv'
$researchRows | Export-Csv -LiteralPath $researchLogPath -NoTypeInformation -Encoding UTF8

$evidenceRegisterPath = Join-Path $packetRoot 'COURTHOUSE_SOURCE_REGISTER.csv'
$evidenceRows | Export-Csv -LiteralPath $evidenceRegisterPath -NoTypeInformation -Encoding UTF8

$chainRows = New-Object System.Collections.Generic.List[object]
$gateRows = New-Object System.Collections.Generic.List[object]
$gapRows = New-Object System.Collections.Generic.List[object]
foreach ($parcelRow in $parcelRows) {
    $parcelDocuments = @($researchRows | Where-Object { $_.parcel_id -eq $parcelRow.parcel_id })
    $deedCount = @($parcelDocuments | Where-Object { $_.document_type -eq 'DEED' }).Count
    $platCount = @($parcelDocuments | Where-Object { $_.document_type -eq 'PLAT' }).Count
    $mapCardCount = @($parcelDocuments | Where-Object { $_.document_type -eq 'MAP_CARD' }).Count

    $chainRows.Add([pscustomobject]@{
        parcel_id = [string]$parcelRow.parcel_id
        sequence = ''
        grantor = ''
        grantee = ''
        instrument = ''
        book = ''
        page = ''
        execution_date = ''
        recording_date = ''
        acreage = ''
        parent_tract = ''
        exceptions_reservations = ''
        back_reference = ''
        source_file = ''
        verification_status = 'PENDING'
    })

    $gateRows.Add([pscustomobject]@{
        parcel_id = [string]$parcelRow.parcel_id
        candidate_deed_count = $deedCount
        candidate_plat_count = $platCount
        gate_status = if (($deedCount + $platCount) -gt 0) { 'CANDIDATE_SOURCE_PRESENT_REVIEW_REQUIRED' } else { 'BLOCKED_NO_CANDIDATE_SOURCE' }
        plot_ready = $false
        verified_source = ''
        reviewer = ''
        reviewed_at = ''
        reason = if (($deedCount + $platCount) -gt 0) { 'A deed or plat candidate exists, but plottability is not yet verified.' } else { 'No deed or plat candidate was found in the supplied evidence.' }
    })

    if ($mapCardCount -eq 0) {
        $gapRows.Add([pscustomobject]@{ parcel_id=$parcelRow.parcel_id; gap='MAP_CARD'; priority='NORMAL'; detail='No map card candidate supplied.' })
    }
    if ($deedCount -eq 0) {
        $gapRows.Add([pscustomobject]@{ parcel_id=$parcelRow.parcel_id; gap='CURRENT_DEED'; priority='HIGH'; detail='No deed candidate supplied.' })
    }
    if (($deedCount + $platCount) -eq 0) {
        $gapRows.Add([pscustomobject]@{ parcel_id=$parcelRow.parcel_id; gap='PLOT_SOURCE'; priority='HIGH'; detail='No candidate plottable deed or plat source.' })
    }
}

$chainPath = Join-Path $packetRoot 'CHAIN_OF_TITLE.csv'
$chainRows | Export-Csv -LiteralPath $chainPath -NoTypeInformation -Encoding UTF8

$gatePath = Join-Path $packetRoot 'PLOT_SOURCE_GATE.csv'
$gateRows | Export-Csv -LiteralPath $gatePath -NoTypeInformation -Encoding UTF8

$gapsPath = Join-Path $packetRoot 'RESEARCH_GAPS.csv'
$gapRows | Export-Csv -LiteralPath $gapsPath -NoTypeInformation -Encoding UTF8

$packetManifestPath = Join-Path $packetRoot 'COURTHOUSE_PACKET.json'
$packetManifest = [ordered]@{
    schema_version = 1
    task_id = $taskId
    project_id = $projectId
    generated_at = (Get-Date).ToUniversalTime().ToString('o')
    parcel_count = $parcelRows.Count
    source_count = $evidenceRows.Count
    copied_or_reused_count = @($evidenceRows | Where-Object { $_.copy_action -match 'COPIED|REUSED' }).Count
    candidate_deed_count = @($researchRows | Where-Object { $_.document_type -eq 'DEED' }).Count
    candidate_plat_count = @($researchRows | Where-Object { $_.document_type -eq 'PLAT' }).Count
    packet_root = $packetRoot
    authority = 'RESEARCH_PACKET_SOURCE_PRESERVED'
    plot_source_gate_rule = 'AI/OCR confidence alone cannot mark plot_ready=true.'
    status = 'PASS'
}
Write-CertaJsonFile -Path $packetManifestPath -Value $packetManifest

$outputs = @(
    $parcelRegisterPath,
    $researchLogPath,
    $evidenceRegisterPath,
    $chainPath,
    $gatePath,
    $gapsPath,
    $packetManifestPath
)
$null = Test-CertaOutputPaths -Path $outputs

[pscustomobject]@{
    status = 'PASS'
    output_paths = $outputs
    validator = 'PASS'
    project_id = $projectId
    parcel_count = $parcelRows.Count
    source_count = $evidenceRows.Count
    packet_root = $packetRoot
}
