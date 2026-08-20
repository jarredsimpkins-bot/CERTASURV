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

function ConvertTo-CertaWorkmapDxf {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Point,
        [Parameter(Mandatory)][double]$Radius,
        [Parameter(Mandatory)][double]$TextHeight,
        [switch]$LabelOverlayOnly
    )

    $builder = New-Object Text.StringBuilder
    foreach ($line in @('0','SECTION','2','ENTITIES')) { [void]$builder.AppendLine($line) }

    foreach ($row in $Point) {
        $style = Get-CertaStatusLayer -Status ([string]$row.Status)
        $layer = if ($LabelOverlayOnly) { 'CS_SEARCH_LABELS' } else { [string]$style.layer }
        $color = if ($LabelOverlayOnly) { 3 } else { [int]$style.acad_color }
        foreach ($line in @(
            '0','CIRCLE','8',$layer,'62',[string]$color,
            '10',([double]$row.E).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture),
            '20',([double]$row.N).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture),
            '30','0','40',$Radius.ToString('0.###',[Globalization.CultureInfo]::InvariantCulture)
        )) { [void]$builder.AppendLine([string]$line) }

        $label = if ([string]::IsNullOrWhiteSpace([string]$row.DESC)) {
            [string]$row.P
        } else {
            '{0} {1}' -f $row.P,$row.DESC
        }
        foreach ($line in @(
            '0','TEXT','8',$layer,'62',[string]$color,
            '10',(([double]$row.E + $Radius*1.35).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)),
            '20',(([double]$row.N + $Radius*1.35).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)),
            '30','0','40',$TextHeight.ToString('0.###',[Globalization.CultureInfo]::InvariantCulture),
            '1',$label.Replace("`r",' ').Replace("`n",' ')
        )) { [void]$builder.AppendLine([string]$line) }
    }

    foreach ($line in @('0','ENDSEC','0','EOF')) { [void]$builder.AppendLine($line) }
    return $builder.ToString()
}

function ConvertTo-CertaWorkmapSvg {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Point,
        [Parameter(Mandatory)][string]$Title
    )

    if ($Point.Count -eq 0) {
        return '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="700"><text x="20" y="40">No points selected.</text></svg>'
    }

    $eastings = @($Point | ForEach-Object { [double]$_.E })
    $northings = @($Point | ForEach-Object { [double]$_.N })
    $minE = [double](($eastings | Measure-Object -Minimum).Minimum)
    $maxE = [double](($eastings | Measure-Object -Maximum).Maximum)
    $minN = [double](($northings | Measure-Object -Minimum).Minimum)
    $maxN = [double](($northings | Measure-Object -Maximum).Maximum)
    $width = [math]::Max(1.0,$maxE-$minE)
    $height = [math]::Max(1.0,$maxN-$minN)
    $canvasWidth = 1100.0
    $canvasHeight = 850.0
    $padding = 60.0
    $scale = [math]::Min(($canvasWidth-2.0*$padding)/$width,($canvasHeight-2.0*$padding)/$height)

    $builder = New-Object Text.StringBuilder
    [void]$builder.AppendLine('<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="850" viewBox="0 0 1100 850">')
    [void]$builder.AppendLine('  <rect width="100%" height="100%" fill="white"/>')
    [void]$builder.AppendLine(('  <text x="25" y="35" font-family="Arial" font-size="22" font-weight="bold">{0}</text>' -f (Escape-CertaXml -Value $Title)))

    foreach ($row in $Point) {
        $style = Get-CertaStatusLayer -Status ([string]$row.Status)
        $x = $padding + (([double]$row.E-$minE)*$scale)
        $y = $canvasHeight-$padding-(([double]$row.N-$minN)*$scale)
        $label = Escape-CertaXml -Value ('{0} {1}' -f $row.P,$row.DESC)
        [void]$builder.AppendLine(('  <circle cx="{0:0.##}" cy="{1:0.##}" r="6" fill="{2}"/>' -f $x,$y,$style.svg_color))
        [void]$builder.AppendLine(('  <text x="{0:0.##}" y="{1:0.##}" font-family="Arial" font-size="13">{2}</text>' -f ($x+8.0),($y-8.0),$label))
    }
    [void]$builder.AppendLine('</svg>')
    return $builder.ToString()
}

function ConvertTo-CertaWorkmapKml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Point,
        [Parameter(Mandatory)][string]$Title
    )

    $geoRows = @($Point | Where-Object {
        $null -ne $_.Latitude -and $null -ne $_.Longitude -and
        [double]$_.Latitude -ge -90.0 -and [double]$_.Latitude -le 90.0 -and
        [double]$_.Longitude -ge -180.0 -and [double]$_.Longitude -le 180.0
    })
    if ($geoRows.Count -eq 0) { return $null }

    $builder = New-Object Text.StringBuilder
    [void]$builder.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
    [void]$builder.AppendLine('<kml xmlns="http://www.opengis.net/kml/2.2">')
    [void]$builder.AppendLine('<Document>')
    [void]$builder.AppendLine(('<name>{0}</name>' -f (Escape-CertaXml -Value $Title)))

    foreach ($status in @('SEARCH','FOUND','SET','CONTROL','FIELD','EXTRACT','RECORD')) {
        $style = Get-CertaStatusLayer -Status $status
        [void]$builder.AppendLine(('<Style id="{0}"><IconStyle><color>{1}</color><scale>1.1</scale></IconStyle></Style>' -f $status.ToLowerInvariant(),$style.kml_color))
    }

    foreach ($row in $geoRows) {
        $longitude = ([double]$row.Longitude).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)
        $latitude = ([double]$row.Latitude).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)
        $elevation = ([double]$row.EL).ToString('0.###',[Globalization.CultureInfo]::InvariantCulture)
        [void]$builder.AppendLine('<Placemark>')
        [void]$builder.AppendLine(('<name>{0}</name>' -f (Escape-CertaXml -Value ([string]$row.P))))
        [void]$builder.AppendLine(('<description>{0}</description>' -f (Escape-CertaXml -Value ([string]$row.DESC))))
        [void]$builder.AppendLine(('<styleUrl>#{0}</styleUrl>' -f ([string]$row.Status).ToLowerInvariant()))
        [void]$builder.AppendLine(('<Point><coordinates>{0},{1},{2}</coordinates></Point>' -f $longitude,$latitude,$elevation))
        [void]$builder.AppendLine('</Placemark>')
    }

    [void]$builder.AppendLine('</Document>')
    [void]$builder.AppendLine('</kml>')
    return $builder.ToString()
}

$task = Get-CertaTaskRecord -TaskPath $TaskPath
$projectId = Get-CertaProjectId -Task $task
$projectRoot = New-CertaProjectLayout -ServerRoot $ServerRoot -ProjectId $projectId
$taskId = [string]$task.task_id

$inputCsv = Get-CertaInputFiles -InputPath @($task.inputs) |
    Where-Object { $_.Extension -eq '.csv' } |
    Sort-Object @{Expression={ if ($_.Name -match '(?i)point|workmap|field|stakeout') { 0 } else { 1 } }},FullName |
    Select-Object -First 1
if (-not $inputCsv) { throw 'workmap-build-v1 requires a point CSV input.' }

$sourceRows = @(Import-Csv -LiteralPath $inputCsv.FullName)
if ($sourceRows.Count -eq 0) { throw 'The point CSV is empty.' }

$points = @()
$index = 0
foreach ($row in $sourceRows) {
    $index++
    $points += Get-CertaNormalizedPoint -Row $row -SourceName $inputCsv.Name -Index $index
}

$rangeMatch = [regex]::Match([string]$task.request,'(?i)\bF\s*(?<start>\d+)\s*(?:-|–|TO)\s*F?\s*(?<end>\d+)\b')
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
        $match.Success -and [int]$match.Groups['number'].Value -ge $rangeStart -and [int]$match.Groups['number'].Value -le $rangeEnd
    })
    if ($selectedPoints.Count -eq 0) { throw "The requested F range F$rangeStart-F$rangeEnd contains no points." }
}

$outputRoot = Join-Path $projectRoot "03_FIELD_WORK\WORKMAPS\$taskId"
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$normalizedPath = Join-Path $outputRoot 'WORKMAP_POINTS.csv'
$controlPath = Join-Path $outputRoot 'CONTROL.csv'
$fieldPath = Join-Path $outputRoot 'FIELD.csv'
$stakeoutPath = Join-Path $outputRoot 'STAKEOUT.csv'
$actionPath = Join-Path $outputRoot 'FIELD_ACTION_REGISTER.csv'
$dxfPath = Join-Path $outputRoot $(if ($overlayMode) { "F${rangeStart}-F${rangeEnd}_LABEL_OVERLAY.dxf" } else { 'WORKMAP.dxf' })
$svgPath = Join-Path $outputRoot $(if ($overlayMode) { "F${rangeStart}-F${rangeEnd}_LABEL_OVERLAY.svg" } else { 'WORKMAP_PREVIEW.svg' })
$kmlPath = Join-Path $outputRoot 'WORKMAP.kml'
$manifestPath = Join-Path $outputRoot 'WORKMAP_PACKAGE.json'

$selectedPoints | Select-Object P,N,E,EL,DESC,Status,Source,ObservedAt,Latitude,Longitude | Export-Csv -LiteralPath $normalizedPath -NoTypeInformation -Encoding UTF8
@($selectedPoints | Where-Object { $_.Status -eq 'CONTROL' }) | Select-Object P,N,E,EL,DESC,Status,Source | Export-Csv -LiteralPath $controlPath -NoTypeInformation -Encoding UTF8
@($selectedPoints | Where-Object { $_.Status -in @('FOUND','SET','CONTROL','FIELD') }) | Select-Object P,N,E,EL,DESC,Status,Source | Export-Csv -LiteralPath $fieldPath -NoTypeInformation -Encoding UTF8
@($selectedPoints | Where-Object { $_.Status -eq 'SEARCH' }) | Select-Object P,N,E,EL,DESC,Status,Source | Export-Csv -LiteralPath $stakeoutPath -NoTypeInformation -Encoding UTF8

$actions = @($selectedPoints | Where-Object {
    $_.Status -eq 'SEARCH' -or ([string]$_.DESC -match '(?i)SHOOT\s+(ROAD|DRAIN)|SEARCH')
} | ForEach-Object {
    $actionType = if ([string]$_.DESC -match '(?i)SHOOT\s+ROAD') { 'SHOOT_ROAD' }
        elseif ([string]$_.DESC -match '(?i)SHOOT\s+DRAIN') { 'SHOOT_DRAIN' }
        else { 'SEARCH' }
    [pscustomobject]@{
        point=$_.P
        action_type=$actionType
        northing=$_.N
        easting=$_.E
        description=$_.DESC
        status='OPEN'
        source=$_.Source
    }
})
$actions | Export-Csv -LiteralPath $actionPath -NoTypeInformation -Encoding UTF8

$eastings = @($selectedPoints | ForEach-Object { [double]$_.E })
$northings = @($selectedPoints | ForEach-Object { [double]$_.N })
$spread = [math]::Max(
    [double](($eastings | Measure-Object -Maximum).Maximum)-[double](($eastings | Measure-Object -Minimum).Minimum),
    [double](($northings | Measure-Object -Maximum).Maximum)-[double](($northings | Measure-Object -Minimum).Minimum)
)
$radius = [math]::Max(1.0,$spread/150.0)
$textHeight = [math]::Max(1.0,$spread/100.0)
Write-CertaTextFile -Path $dxfPath -Content (ConvertTo-CertaWorkmapDxf -Point $selectedPoints -Radius $radius -TextHeight $textHeight -LabelOverlayOnly:$overlayMode)
Write-CertaTextFile -Path $svgPath -Content (ConvertTo-CertaWorkmapSvg -Point $selectedPoints -Title "$projectId workmap")

$kmlText = ConvertTo-CertaWorkmapKml -Point $selectedPoints -Title "$projectId workmap"
$kmlCreated = $false
if ($null -ne $kmlText) {
    Write-CertaTextFile -Path $kmlPath -Content $kmlText
    $kmlCreated = $true
}

$manifest = [ordered]@{
    schema_version=1
    task_id=$taskId
    project_id=$projectId
    generated_at=(Get-Date).ToUniversalTime().ToString('o')
    source=$inputCsv.FullName
    source_point_count=$points.Count
    output_point_count=$selectedPoints.Count
    overlay_mode=$overlayMode
    requested_f_range=if ($overlayMode) { "F$rangeStart-F$rangeEnd" } else { $null }
    control_count=@($selectedPoints | Where-Object { $_.Status -eq 'CONTROL' }).Count
    found_count=@($selectedPoints | Where-Object { $_.Status -eq 'FOUND' }).Count
    set_count=@($selectedPoints | Where-Object { $_.Status -eq 'SET' }).Count
    search_count=@($selectedPoints | Where-Object { $_.Status -eq 'SEARCH' }).Count
    action_count=$actions.Count
    kml_created=$kmlCreated
    kml_reason=if ($kmlCreated) { 'Latitude/longitude fields were available.' } else { 'No valid Latitude/Longitude fields; local survey coordinates were not misrepresented as KML.' }
    authority='FIELD_PLANNING_PACKAGE_REVIEW_REQUIRED'
    color_rules=[ordered]@{
        search='GREEN'
        found='RED'
        set='BLUE'
        control='ORANGE'
        extract='GREY'
        working_boundary='YELLOW_PHANTOM_INPUT_ONLY'
    }
    status='PASS'
}
Write-CertaJsonFile -Path $manifestPath -Value $manifest

$outputPaths = @($normalizedPath,$controlPath,$fieldPath,$stakeoutPath,$actionPath,$dxfPath,$svgPath,$manifestPath)
if ($kmlCreated) { $outputPaths += $kmlPath }
$null = Test-CertaOutputPaths -Path $outputPaths
if ($overlayMode -and $selectedPoints.Count -ne @($selectedPoints | Where-Object { ([string]$_.P) -match '(?i)^F\d+$' }).Count) {
    throw 'F-range overlay validator failed: unrelated point family entered the overlay.'
}

[pscustomobject]@{
    status='PASS'
    output_paths=$outputPaths
    validator='PASS'
    project_id=$projectId
    point_count=$selectedPoints.Count
    overlay_mode=$overlayMode
    output_root=$outputRoot
}
