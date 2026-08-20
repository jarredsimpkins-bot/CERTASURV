#requires -Version 5.1
Set-StrictMode -Version Latest

function Write-CertaTextFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Write-CertaJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Value,
        [ValidateRange(2,100)][int]$Depth = 20
    )

    Write-CertaTextFile -Path $Path -Content ($Value | ConvertTo-Json -Depth $Depth)
}

function Get-CertaPropertyValue {
    [CmdletBinding()]
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory)][string[]]$Name
    )

    if ($null -eq $Object) { return $null }
    foreach ($candidate in $Name) {
        $property = $Object.PSObject.Properties | Where-Object {
            $_.Name -eq $candidate
        } | Select-Object -First 1
        if ($property -and $null -ne $property.Value -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
            return $property.Value
        }

        $property = $Object.PSObject.Properties | Where-Object {
            $_.Name.Equals($candidate, [StringComparison]::OrdinalIgnoreCase)
        } | Select-Object -First 1
        if ($property -and $null -ne $property.Value -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
            return $property.Value
        }
    }
    return $null
}

function ConvertTo-CertaDouble {
    [CmdletBinding()]
    param(
        [AllowNull()]$Value,
        [Parameter(Mandatory)][string]$FieldName,
        [switch]$AllowNull
    )

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        if ($AllowNull) { return $null }
        throw "Required numeric field '$FieldName' is blank."
    }

    $number = 0.0
    if ([double]::TryParse(
        ([string]$Value).Trim(),
        [Globalization.NumberStyles]::Float -bor [Globalization.NumberStyles]::AllowThousands,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$number
    )) {
        return $number
    }

    if ([double]::TryParse([string]$Value, [ref]$number)) {
        return $number
    }

    throw "Field '$FieldName' is not numeric: $Value"
}

function ConvertTo-CertaSafeName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Value,
        [ValidateRange(8,200)][int]$MaximumLength = 80
    )

    $clean = $Value.Trim()
    foreach ($character in [IO.Path]::GetInvalidFileNameChars()) {
        $clean = $clean.Replace([string]$character, '_')
    }
    $clean = [regex]::Replace($clean, '\s+', '_')
    $clean = [regex]::Replace($clean, '_+', '_').Trim('_','.')
    if ([string]::IsNullOrWhiteSpace($clean)) { $clean = 'UNNAMED' }
    if ($clean.Length -gt $MaximumLength) { $clean = $clean.Substring(0, $MaximumLength) }
    return $clean
}

function Get-CertaTaskRecord {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$TaskPath)

    if (-not (Test-Path -LiteralPath $TaskPath)) {
        throw "Task file not found: $TaskPath"
    }

    try {
        $task = Get-Content -LiteralPath $TaskPath -Raw | ConvertFrom-Json
    }
    catch {
        throw "Task JSON is invalid: $TaskPath. $($_.Exception.Message)"
    }

    foreach ($required in @('task_id','request','inputs')) {
        if ($null -eq $task.PSObject.Properties[$required]) {
            throw "Task is missing required property '$required': $TaskPath"
        }
    }
    return $task
}

function Get-CertaProjectId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Task,
        [switch]$AllowGenerated
    )

    $value = [string](Get-CertaPropertyValue -Object $Task -Name @('project_id','projectId','ProjectId'))
    if ([string]::IsNullOrWhiteSpace($value)) {
        if (-not $AllowGenerated) { throw 'This capability requires task.project_id.' }
        $value = 'UNASSIGNED-' + ([string]$Task.task_id)
    }

    $value = $value.Trim().ToUpperInvariant()
    if ($value -notmatch '^[A-Z0-9][A-Z0-9_-]{1,79}$') {
        throw "Invalid project_id '$value'. Use letters, numbers, underscore, or hyphen."
    }
    return $value
}

function New-CertaProjectLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ServerRoot,
        [Parameter(Mandatory)][string]$ProjectId
    )

    $projectRoot = Join-Path $ServerRoot "PROJECTS\$ProjectId"
    $folders = @(
        '',
        '01_INTAKE_SCOPE',
        '01_INTAKE_SCOPE\SOURCE_EVIDENCE',
        '02_COURTHOUSE_RESEARCH',
        '02_COURTHOUSE_RESEARCH\PARCELS',
        '02_COURTHOUSE_RESEARCH\SOURCE_EVIDENCE',
        '03_FIELD_WORK',
        '03_FIELD_WORK\RAW',
        '03_FIELD_WORK\WORKMAPS',
        '03_FIELD_WORK\RETURNS',
        '04_PROCESSING_CALCS',
        '05_DRAFTING_QC',
        '06_DELIVERY_CLOSEOUT',
        '07_INTERNAL_LOGS',
        '07_INTERNAL_LOGS\RECEIPTS',
        '07_INTERNAL_LOGS\MANIFEST_HISTORY'
    )
    foreach ($relative in $folders) {
        $path = if ([string]::IsNullOrWhiteSpace($relative)) { $projectRoot } else { Join-Path $projectRoot $relative }
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    return $projectRoot
}

function Get-CertaInputFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$InputPath
    )

    $files = New-Object System.Collections.Generic.List[IO.FileInfo]
    foreach ($rawPath in @($InputPath)) {
        $path = [string]$rawPath
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Input path does not exist: $path"
        }

        $item = Get-Item -LiteralPath $path -Force
        if ($item.PSIsContainer) {
            foreach ($file in @(Get-ChildItem -LiteralPath $item.FullName -File -Recurse -Force -ErrorAction Stop |
                Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) })) {
                $files.Add($file)
            }
        }
        else {
            $files.Add([IO.FileInfo]$item)
        }
    }

    return @($files | Sort-Object FullName -Unique)
}

function Get-CertaSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [long]$MaximumBytes = 104857600
    )

    $item = Get-Item -LiteralPath $Path -Force
    if ($item.Length -gt $MaximumBytes) {
        return [pscustomobject]@{ sha256=$null; status='SKIPPED_LARGE'; limit_bytes=$MaximumBytes }
    }

    return [pscustomobject]@{
        sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
        status = 'SHA256'
        limit_bytes = $MaximumBytes
    }
}

function Test-CertaPathUnderRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Root
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    return $fullPath.StartsWith($fullRoot, [StringComparison]::OrdinalIgnoreCase)
}

function Copy-CertaEvidenceFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$DestinationFolder
    )

    New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
    $sourceItem = Get-Item -LiteralPath $Source -Force
    $safeName = ConvertTo-CertaSafeName -Value $sourceItem.Name -MaximumLength 140
    $destination = Join-Path $DestinationFolder $safeName

    if (Test-Path -LiteralPath $destination) {
        $sourceHash = (Get-FileHash -LiteralPath $sourceItem.FullName -Algorithm SHA256).Hash
        $destinationHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
        if ($sourceHash -eq $destinationHash) {
            return [pscustomobject]@{ path=$destination; action='REUSED_IDENTICAL'; sha256=$sourceHash }
        }

        $stem = [IO.Path]::GetFileNameWithoutExtension($safeName)
        $extension = [IO.Path]::GetExtension($safeName)
        $destination = Join-Path $DestinationFolder ("{0}_{1}{2}" -f $stem, $sourceHash.Substring(0,8), $extension)
    }

    Copy-Item -LiteralPath $sourceItem.FullName -Destination $destination -Force
    $copiedHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
    $originalHash = (Get-FileHash -LiteralPath $sourceItem.FullName -Algorithm SHA256).Hash
    if ($copiedHash -ne $originalHash) {
        Remove-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
        throw "Evidence-copy verification failed: $Source"
    }

    return [pscustomobject]@{ path=$destination; action='COPIED_VERIFIED'; sha256=$copiedHash }
}

function Get-CertaPointStatus {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$PointId,
        [AllowNull()][string]$Description,
        [AllowNull()][string]$ExplicitStatus
    )

    $id = ([string]$PointId).Trim().ToUpperInvariant()
    $description = ([string]$Description).Trim().ToUpperInvariant()
    $status = ([string]$ExplicitStatus).Trim().ToUpperInvariant()

    if ($status -in @('SEARCH','FOUND','SET','CONTROL','FIELD','RECORD','EXTRACT')) { return $status }
    if ($description -match '\b(FOUND|RECOVERED)\b') { return 'FOUND' }
    if ($description -match '\bSET\b' -or $id -match '^S\d+') { return 'SET' }
    if ($description -match '\b(BASE|NS|GNSS|TRV|TRAVERSE|CONTROL)\b' -or $id -match '^(BASE|NS|TRV)') { return 'CONTROL' }
    if ($description -match '\bSEARCH\b' -or $id -match '^(F|P|TM)\d+') { return 'SEARCH' }
    if ($description -match '\bEXTRACT\b') { return 'EXTRACT' }
    return 'FIELD'
}

function Get-CertaStatusLayer {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Status)

    switch ($Status.ToUpperInvariant()) {
        'SEARCH'  { return [pscustomobject]@{ layer='CS_SEARCH'; acad_color=3; svg_color='#008f00'; kml_color='ff00ff00' } }
        'FOUND'   { return [pscustomobject]@{ layer='CS_FOUND'; acad_color=1; svg_color='#cc0000'; kml_color='ff0000ff' } }
        'SET'     { return [pscustomobject]@{ layer='CS_SET'; acad_color=5; svg_color='#0066cc'; kml_color='ffff0000' } }
        'CONTROL' { return [pscustomobject]@{ layer='CS_CONTROL'; acad_color=30; svg_color='#ff8000'; kml_color='ff0080ff' } }
        'EXTRACT' { return [pscustomobject]@{ layer='EXTRACT_REFERENCE'; acad_color=8; svg_color='#777777'; kml_color='ff777777' } }
        'RECORD'  { return [pscustomobject]@{ layer='DEED_RECORD'; acad_color=3; svg_color='#228822'; kml_color='ff228822' } }
        default   { return [pscustomobject]@{ layer='CS_FIELD'; acad_color=7; svg_color='#222222'; kml_color='ff222222' } }
    }
}

function Get-CertaNormalizedPoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Row,
        [Parameter(Mandatory)][string]$SourceName,
        [int]$Index = 0
    )

    $pointId = [string](Get-CertaPropertyValue -Object $Row -Name @('P','Point','PointId','Point_ID','Name','Number'))
    if ([string]::IsNullOrWhiteSpace($pointId)) { $pointId = "ROW$Index" }

    $northingValue = Get-CertaPropertyValue -Object $Row -Name @('N','Northing','Y')
    $eastingValue = Get-CertaPropertyValue -Object $Row -Name @('E','Easting','X')
    $latitudeValue = Get-CertaPropertyValue -Object $Row -Name @('Latitude','Lat')
    $longitudeValue = Get-CertaPropertyValue -Object $Row -Name @('Longitude','Lon','Lng')
    if ($null -eq $northingValue -and $null -ne $latitudeValue) { $northingValue = $latitudeValue }
    if ($null -eq $eastingValue -and $null -ne $longitudeValue) { $eastingValue = $longitudeValue }

    $northing = ConvertTo-CertaDouble -Value $northingValue -FieldName "Northing row $Index"
    $easting = ConvertTo-CertaDouble -Value $eastingValue -FieldName "Easting row $Index"
    $elevation = ConvertTo-CertaDouble -Value (Get-CertaPropertyValue -Object $Row -Name @('EL','Elevation','Z')) -FieldName "Elevation row $Index" -AllowNull
    if ($null -eq $elevation) { $elevation = 0.0 }

    $description = [string](Get-CertaPropertyValue -Object $Row -Name @('DESC','Description','Code','Notes'))
    $explicitStatus = [string](Get-CertaPropertyValue -Object $Row -Name @('Status','State','PointStatus'))
    $status = Get-CertaPointStatus -PointId $pointId -Description $description -ExplicitStatus $explicitStatus
    $observedAt = [string](Get-CertaPropertyValue -Object $Row -Name @('ObservedAt','Observed_At','Timestamp','Date','Time'))
    $latitude = ConvertTo-CertaDouble -Value $latitudeValue -FieldName "Latitude row $Index" -AllowNull
    $longitude = ConvertTo-CertaDouble -Value $longitudeValue -FieldName "Longitude row $Index" -AllowNull

    return [pscustomobject]@{
        P = $pointId.Trim()
        N = [double]$northing
        E = [double]$easting
        EL = [double]$elevation
        DESC = $description
        Status = $status
        Source = $SourceName
        ObservedAt = $observedAt
        Latitude = $latitude
        Longitude = $longitude
    }
}

function Get-CertaRecordId {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Value)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Value)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')
    }
    finally {
        $sha.Dispose()
    }
}

function Escape-CertaXml {
    [CmdletBinding()]
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) { return '' }
    return [Security.SecurityElement]::Escape($Value)
}

function Test-CertaOutputPaths {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Path)

    foreach ($item in $Path) {
        if ([string]::IsNullOrWhiteSpace($item) -or -not (Test-Path -LiteralPath $item)) {
            throw "Expected output was not created: $item"
        }
    }
    return $true
}
