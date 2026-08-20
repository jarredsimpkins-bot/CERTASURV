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

function Get-CertaWorkmapDxf {
    param(
        [Parameter(Mandatory)][object[]]$Point,
        [double]$Radius,
        [double]$TextHeight,
        [switch]$LabelOverlayOnly
    )

    $builder = New-Object Text.StringBuilder
    [void]$builder.AppendLine('0')
    [void]$builder.AppendLine('SECTION')
    [void]$builder.AppendLine('2')
    [void]$builder.AppendLine('ENTITIES')

    foreach ($row in $Point) {
        $style = Get-CertaStatusLayer -Status ([string]$row.Status)
        $layer = if ($LabelOverlayOnly) { 'CS_SEARCH_LABELS' } else { [string]$style.layer }
        $color = if ($LabelOverlayOnly) { 3 } else { [int]$style.acad_color }

        [void]$builder.AppendLine('0')
        [void]$builder.AppendLine('CIRCLE')
        [void]$builder.AppendLine('8')
        [void]$builder.AppendLine($layer)
        [void]$builder.AppendLine('62')
        [void]$builder.AppendLine([string]$color)
        [void]$builder.AppendLine('10')
        [void]$builder.AppendLine(([double]$row.E).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.AppendLine('20')
        [void]$builder.AppendLine(([double]$row.N).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.AppendLine('30')
        [void]$builder.AppendLine('0')
        [void]$builder.AppendLine('40')
        [void]$builder.AppendLine($Radius.ToString('0.###', [Globalization.CultureInfo]::InvariantCulture))

        $label = if ([string]::IsNullOrWhiteSpace([string]$row.DESC)) {
            [string]$row.P
        }
        else {
            "{0} {1}" -f $row.P, $row.DESC
        }

        [void]$builder.AppendLine('0')
        [void]$builder.AppendLine('TEXT')
        [void]$builder.AppendLine('8')
        [void]$builder.AppendLine($layer)
        [void]$builder.AppendLine('62')
        [void]$builder.AppendLine([string]$color)
        [void]$builder.AppendLine('10')
        [void]$builder.AppendLine((([double]$row.E + ($Radius * 1.35)).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture)))
        [void]$builder.AppendLine('20')
        [void]$builder.AppendLine((([double]$row.N + ($Radius * 1.35)).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture)))
        [void]$builder.AppendLine('30')
        [void]$builder.AppendLine('0')
        [void]$builder.AppendLine('40')
        [void]$builder.AppendLine($TextHeight.ToString('0.###', [Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.AppendLine('1')
        [void]$builder.AppendLine($label.Replace("`r",' ').Replace("`n",' '))
    }

    [void]$builder.AppendLine('0')
    [void]$builder.AppendLine('ENDSEC')
    [void]$builder.AppendLine('0')
    [void]$builder.AppendLine('EOF')
    return $builder.ToString()
}

function Get-CertaWorkmapSvg {
    param(
        [Parameter(Mandatory)][object[]]$Point,
        [Parameter(Mandatory)][string]$Title
    )

    if ($Point.Count -eq 0) {
        return '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="700"><text x="20" y="40">No points selected.</text></svg>'
    }

    $eastings = @($Point | ForEach-Object { [double]$_.E })
    $northings = @($Point | ForEach-Object { [double]$_.N })
    $minE = ($eastings | Measure-Object -Minimum).Minimum
    $maxE = ($eastings | Measure-Object -Maximum).Maximum
    $minN = ($northings | Measure-Object -Minimum).Minimum
    $maxN = ($northings | Measure-Object -Maximum).Maximum
    $width = [math]::Max(1.0, $maxE - $minE)
    $height = [math]::Max(1.0, $maxN - $minN)
    $padding = 60.0
    $canvasWidth = 1100.0
    $canvasHeight = 850.0
    $scale = [math]::Min(($canvasWidth - 2*$padding) / $width, ($canvasHeight - 2*$padding) / $height)
    $escapedTitle = Escape-CertaXml -Value $Title

    $svg = @"
<svg xmlns=""http://www.w3.org/2000/svg"" width=""$([int]$canvasWidth)"" height=""$([int]$canvasHeight)"" viewBox=""0 0 $([int]$canvasWidth) $([int]$canvasHeight)"">
  <rect width=""100%"" height=""100%"" fill=""white""/>
  <text x=""25"" y=""35"" font-family=""Arial"" font-size=""22"" font-weight=""bold"">$escapedTitle</text>
"@
    foreach ($row in $Point) {
        $style = Get-CertaStatusLayer -Status ([string]$row.Status)
        $x = $padding + (([double]$row.E - $minE) * $scale)
        $y = $canvasHeight - $padding - (([double]$row.N - $minN) * $scale)
        $label = Escape-CertaXml -Value ("{0} {1}" -f $row.P,$row.DESC)
        $svg += "  <circle cx=""$([math]::Round($x,2))"" cy=""$([math]::Round($y,2))"" r=""6"" fill=""$($style.svg_color)""/>`n"
        $svg += "  <text x=""$([math]::Round($x+8,2))"" y=""$([math]::Round($y-8,2))"" font-family=""Arial"" font-size=""13"">$label</text>`n"
    }
    $svg += '</svg>'
    return $svg
}

function Get-CertaKml {
    param(
        [Parameter(Mandatory)][object[]]$Point,
        [Parameter(Mandatory)][string]$Title
    )

    $geoRows = @($Point | Where-Object {
        $null -ne $_.Latitude -and $null -ne $_.Longitude -and
        [double]$_.Latitude -ge -90 -and [double]$_.Latitude -le 90 -and
        [double]$_.Longitude -ge -180 -and [double]$_.Longitude -le 180
    })
    if ($geoRows.Count -eq 0) { return $null }

    $kml = @"
<?xml version=""1.0"" encoding=""UTF-8""?>
<kml xmlns=""http://www.opengis.net/kml/2.2"">
<Document>
<name>$(Escape-CertaXml -Value $Title)</name>
"@
    foreach ($status in @('SEARCH','FOUND','SET','CONTROL','FIELD','EXTRACT','RECORD')) {
        $style = Get-CertaStatusLayer -Status $status
        $styleId = $status.ToLowerInvariant()
        $kml += "<Style id=""$styleId""><IconStyle><color>$($style.kml_color)</color><scale>1.1</scale></IconStyle></Style>`n"
    }

    foreach ($row in $geoRows) {
        $styleId = ([string]$row.Status).ToLowerInvariant()
        $name = Escape-CertaXml -Value ([string]$row.P)
        $description = Escape-CertaXml -Value ([string]$row.DESC)
        $longitude = ([double]$row.Longitude).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture)
        $latitude = ([double]$row.Latitude).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture)
        $elevation = ([double]$row.EL).ToString('0.###', [Globalization.CultureInfo]::InvariantCulture)
        $kml += @"
<Placemark>
<name>$name</name>
<description>$description</description>
<styleUrl>#$styleId</styleUrl>
<Point><coordinates>$longitude,$latitude,$elevation</coordinates></Point>
</Placemark>
"@
    }
    $kml += '</Document></kml>'
    return $kml
}

$task = Get-CertaTaskRecord -TaskPath $TaskPath
$projectId = Get-CertaProjectId -Task $task
$projectRoot = New-CertaProjectLayout -ServerRoot $ServerRoot -ProjectId $projectId
$taskId = [string]$task.task_id

$inputCsv = @(Get-CertaInputFiles -InputPath @($task.inputs) | Where-Object { $_.Extension -eq '.csv' } | Select-Object -First 1)
if (-not $inputCsv) { throw 'workmap-build-v1 requires a point CSV input.' }
$sourceRows = @(Import-Csv -LiteralPath $inputCsv.FullName)
if ($sourceRows.Count -eq 0) { throw 'The point CSV is empty.' }

$points = New-Object System.Collections.Generic.List[object]
$index = 0
foreach ($row in $sourceRows) {
    $index++
    $points.Add((Get-CertaNormalizedPoint -Row $row -SourceName $inputCsv.Name -Index $index))
}

$rangeMatch = [regex]::Match([string]$task.request, '(?i)\bF\s*(?<start>\d+)\s*(?:-|–|TO)\s*F?\s*(?<end>\d+)\b')
$overlayMode = $rangeMatch.Success
$rangeStart = $null
$rangeEnd = $null
$selectedPoints = @($points)
if ($overlayMode) {
    $rangeStart = [int]$rangeMatch.Groups['start'].Value
    $rangeEnd = [int]$rangeMatch.Groups['end'].Value
    if ($rangeEnd -lt $rangeStart) {
        $temporary = $rangeStart
        $rangeStart = $rangeEnd
        $rangeEnd = $temporary
    }

    $selectedPoints = @($points | Where-Object {
        $match = [regex]::Match(([string]$_.P).Trim(), '(?i)^F(?<number>\d+)$')
        $match.Success -and
        [int]$match.Groups['number'].Value -ge $rangeStart -and
        [int]$match.Groups['number'].Value -le $rangeEnd
    })
    if ($selectedPoints.Count -eq 0) {
        throw "The requested F range F$rangeStart-F$rangeEnd contains no points."
    }
}

$outputRoot = Join-Path $projectRoot "03_FIELD_WORK\WORKMAPS\$taskId"
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$normalizedPath = Join-Path $outputRoot 'WORKMAP_POINTS.csv'
$controlPath = Join-Path $outputRoot 'CONTROL.csv'
$fieldPath = Join-Path $outputRoot 'FIELD.csv'
$stakeoutPath = Join-Path $outputRoot 'STAKEOUT.csv'
$actionPath = Join-Path $outputRoot 'FIELD_ACTION_REGISTER.csv'
$dxfName = if ($overlayMode) { "F${rangeStart}-F${rangeEnd}_LABEL_OVERLAY.dxf" } else { 'WORKMAP.dxf' }
$svgName = if ($overlayMode) { "F${rangeStart}-F${rangeEnd}_LABEL_OVERLAY.svg" } else { 'WORKMAP_PREVIEW.svg' }
$dxfPath = Join-Path $outputRoot $dxfName
$svgPath = Join-Path $outputRoot $svgName
$kmlPath = Join-Path $outputRoot 'WORKMAP.kml'
$manifestPath = Join-Path $outputRoot 'WORKMAP_PACKAGE.json'

$selectedPoints | Select-Object P,N,E,EL,DESC,Status,Source,ObservedAt,Latitude,Longitude |
    Export-Csv -LiteralPath $normalizedPath -NoTypeInformation -Encoding UTF8
@($selectedPoints | Where-Object { $_.Status -eq 'CONTROL' }) |
    Select-Object P,N,E,EL,DESC,Status,Source |
    Export-Csv -LiteralPath $controlPath -NoTypeInformation -Encoding UTF8
@($selectedPoints | Where-Object { $_.Status -in @('FOUND','SET','CONTROL','FIELD') }) |
    Select-Object P,N,E,EL,DESC,Status,Source |
    Export-Csv -LiteralPath $fieldPath -NoTypeInformation -Encoding UTF8
@($selectedPoints | Where-Object { $_.Status -eq 'SEARCH' }) |
    Select-Object P,N,E,EL,DESC,Status,Source |
    Export-Csv -LiteralPath $stakeoutPath -NoTypeInformation -Encoding UTF8

$actions = @($selectedPoints | Where-Object {
    $_.Status -eq 'SEARCH' -or ([string]$_.DESC -match '(?i)SHOOT\s+(ROAD|DRAIN)|SEARCH')
} | ForEach-Object {
    $actionType = if ([string]$_.DESC -match '(?i)SHOOT\s+ROAD') {
        'SHOOT_ROAD'
    }
    elseif ([string]$_.DESC -match '(?i)SHOOT\s+DRAIN') {
        'SHOOT_DRAIN'
    }
    else {
        'SEARCH'
    }
    [pscustomobject]@{
        point = $_.P
        action_type = $actionType
        northing = $_.N
        easting = $_.E
        description = $_.DESC
        status = 'OPEN'
        source = $_.Source
    }
})
$actions | Export-Csv -LiteralPath $actionPath -NoTypeInformation -Encoding UTF8

$eastings = @($selectedPoints | ForEach-Object { [double]$_.E })
$northings = @($selectedPoints | ForEach-Object { [double]$_.N })
$spread = [math]::Max(
    (($eastings | Measure-Object -Maximum).Maximum - ($eastings | Measure-Object -Minimum).Minimum),
    (($northings | Measure-Object -Maximum).Maximum - ($northings | Measure-Object -Minimum).Minimum)
)
$radius = [math]::Max(1.0, $spread / 150.0)
$textHeight = [math]::Max(1.0, $spread / 100.0)
Write-CertaTextFile -Path $dxfPath -Content (Get-CertaWorkmapDxf -Point $selectedPoints -Radius $radius -TextHeight $textHeight -LabelOverlayOnly:$overlayMode)
Write-CertaTextFile -Path $svgPath -Content (Get-CertaWorkmapSvg -Point $selectedPoints -Title "$projectId workmap")

$kml = Get-CertaKml -Point $selectedPoints -Title "$projectId workmap"
$kmlCreated = $false
if ($null -ne $kml) {
    Write-CertaTextFile -Path $kmlPath -Content $kml
    $kmlCreated = $true
}

$manifest = [ordered]@{
    schema_version = 1
    task_id = $taskId
    project_id = $projectId
    generated_at = (Get-Date).ToUniversalTime().ToString('o')
    source = $inputCsv.FullName
    source_point_count = $points.Count
    output_point_count = $selectedPoints.Count
    overlay_mode = $overlayMode
    requested_f_range = if ($overlayMode) { "F$rangeStart-F$rangeEnd" } else { $null }
    control_count = @($selectedPoints | Where-Object { $_.Status -eq 'CONTROL' }).Count
    found_count = @($selectedPoints | Where-Object { $_.Status -eq 'FOUND' }).Count
    set_count = @($selectedPoints | Where-Object { $_.Status -eq 'SET' }).Count
    search_count = @($selectedPoints | Where-Object { $_.Status -eq 'SEARCH' }).Count
    action_count = $actions.Count
    kml_created = $kmlCreated
    kml_reason = if ($kmlCreated) { 'Latitude/longitude fields were available.' } else { 'No valid Latitude/Longitude fields; local survey coordinates were not misrepresented as KML.' }
    authority = 'FIELD_PLANNING_PACKAGE_REVIEW_REQUIRED'
    color_rules = [ordered]@{
        search='GREEN'
        found='RED'
        set='BLUE'
        control='ORANGE'
        extract='GREY'
        working_boundary='YELLOW_PHANTOM_INPUT_ONLY'
    }
    status = 'PASS'
}
Write-CertaJsonFile -Path $manifestPath -Value $manifest

$outputs = @($normalizedPath,$controlPath,$fieldPath,$stakeoutPath,$actionPath,$dxfPath,$svgPath,$manifestPath)
if ($kmlCreated) { $outputs += $kmlPath }
$null = Test-CertaOutputPaths -Path $outputs
if ($overlayMode -and $selectedPoints.Count -ne @($selectedPoints | Where-Object { ([string]$_.P) -match '(?i)^F\d+$' }).Count) {
    throw 'F-range overlay validator failed: unrelated point family entered the overlay.'
}

[pscustomobject]@{
    status = 'PASS'
    output_paths = $outputs
    validator = 'PASS'
    project_id = $projectId
    point_count = $selectedPoints.Count
    overlay_mode = $overlayMode
    output_root = $outputRoot
}
