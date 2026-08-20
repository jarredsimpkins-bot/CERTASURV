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

function Convert-CertaBearingToAzimuth {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Bearing)

    $text = $Bearing.Trim().ToUpperInvariant()
    $numericAzimuth = 0.0
    if ([double]::TryParse(
        $text,
        [Globalization.NumberStyles]::Float,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$numericAzimuth
    )) {
        $numericAzimuth = $numericAzimuth % 360.0
        if ($numericAzimuth -lt 0.0) { $numericAzimuth += 360.0 }
        return $numericAzimuth
    }

    if ($text.Length -lt 3) { throw "Invalid quadrant bearing: $Bearing" }
    $northSouth = $text.Substring(0,1)
    $eastWest = $text.Substring($text.Length - 1,1)
    if ($northSouth -notin @('N','S') -or $eastWest -notin @('E','W')) {
        throw "Bearing must be a numeric azimuth or quadrant bearing: $Bearing"
    }

    $middle = $text.Substring(1, $text.Length - 2)
    $middle = [regex]::Replace($middle, '[^0-9\.]+', ' ').Trim()
    $parts = @($middle -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($parts.Count -lt 1 -or $parts.Count -gt 3) {
        throw "Unable to parse quadrant bearing: $Bearing"
    }

    $degrees = ConvertTo-CertaDouble -Value $parts[0] -FieldName 'bearing degrees'
    $minutes = if ($parts.Count -ge 2) {
        ConvertTo-CertaDouble -Value $parts[1] -FieldName 'bearing minutes'
    } else { 0.0 }
    $seconds = if ($parts.Count -ge 3) {
        ConvertTo-CertaDouble -Value $parts[2] -FieldName 'bearing seconds'
    } else { 0.0 }

    if ($degrees -lt 0.0 -or $degrees -gt 90.0 -or $minutes -lt 0.0 -or $minutes -ge 60.0 -or $seconds -lt 0.0 -or $seconds -ge 60.0) {
        throw "Quadrant bearing is outside the valid range: $Bearing"
    }

    $angle = $degrees + ($minutes / 60.0) + ($seconds / 3600.0)
    if ($northSouth -eq 'N' -and $eastWest -eq 'E') { return $angle }
    if ($northSouth -eq 'N' -and $eastWest -eq 'W') { return (360.0 - $angle) % 360.0 }
    if ($northSouth -eq 'S' -and $eastWest -eq 'E') { return 180.0 - $angle }
    return 180.0 + $angle
}

function ConvertTo-CertaDxfText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Call,
        [Parameter(Mandatory)][object[]]$Point,
        [Parameter(Mandatory)][double]$TextHeight
    )

    $builder = New-Object Text.StringBuilder
    foreach ($line in @('0','SECTION','2','ENTITIES')) { [void]$builder.AppendLine($line) }

    foreach ($item in $Call) {
        foreach ($line in @(
            '0','LINE','8','DEED_RAW','62','3',
            '10',([double]$item.start_easting).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture),
            '20',([double]$item.start_northing).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture),
            '30','0',
            '11',([double]$item.end_easting).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture),
            '21',([double]$item.end_northing).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture),
            '31','0'
        )) { [void]$builder.AppendLine([string]$line) }

        $label = ('{0}: {1}  {2}' -f $item.sequence,$item.bearing_raw,([double]$item.distance).ToString('0.###',[Globalization.CultureInfo]::InvariantCulture))
        $midE = (([double]$item.start_easting + [double]$item.end_easting) / 2.0
        $midN = (([double]$item.start_northing + [double]$item.end_northing) / 2.0
        foreach ($line in @(
            '0','TEXT','8','DEED_LABELS','62','3',
            '10',$midE.ToString('0.########',[Globalization.CultureInfo]::InvariantCulture),
            '20',$midN.ToString('0.########',[Globalization.CultureInfo]::InvariantCulture),
            '30','0','40',$TextHeight.ToString('0.###',[Globalization.CultureInfo]::InvariantCulture),
            '1',$label.Replace("`r",' ').Replace("`n",' ')
        )) { [void]$builder.AppendLine([string]$line) }
    }

    foreach ($item in $Point) {
        foreach ($line in @(
            '0','POINT','8','DEED_POINTS','62','3',
            '10',([double]$item.E).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture),
            '20',([double]$item.N).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture),
            '30','0'
        )) { [void]$builder.AppendLine([string]$line) }
    }

    foreach ($line in @('0','ENDSEC','0','EOF')) { [void]$builder.AppendLine($line) }
    return $builder.ToString()
}

function ConvertTo-CertaSvgText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Point,
        [Parameter(Mandatory)][string]$Title
    )

    $eastings = @($Point | ForEach-Object { [double]$_.E })
    $northings = @($Point | ForEach-Object { [double]$_.N })
    $minE = [double](($eastings | Measure-Object -Minimum).Minimum)
    $maxE = [double](($eastings | Measure-Object -Maximum).Maximum)
    $minN = [double](($northings | Measure-Object -Minimum).Minimum)
    $maxN = [double](($northings | Measure-Object -Maximum).Maximum)
    $width = [math]::Max(1.0, $maxE - $minE)
    $height = [math]::Max(1.0, $maxN - $minN)
    $canvasWidth = 1100.0
    $canvasHeight = 850.0
    $padding = 60.0
    $scale = [math]::Min(($canvasWidth - 2.0*$padding)/$width, ($canvasHeight - 2.0*$padding)/$height)

    $coordinates = @()
    foreach ($item in $Point) {
        $x = $padding + (([double]$item.E - $minE) * $scale)
        $y = $canvasHeight - $padding - (([double]$item.N - $minN) * $scale)
        $coordinates += [pscustomobject]@{ X=$x; Y=$y; Name=[string]$item.P }
    }

    $builder = New-Object Text.StringBuilder
    [void]$builder.AppendLine(('<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="850" viewBox="0 0 1100 850">'))
    [void]$builder.AppendLine('  <rect width="100%" height="100%" fill="white"/>')
    [void]$builder.AppendLine(('  <text x="30" y="35" font-family="Arial" font-size="22" font-weight="bold">{0}</text>' -f (Escape-CertaXml -Value $Title)))
    $polyline = @($coordinates | ForEach-Object { '{0:0.##},{1:0.##}' -f $_.X,$_.Y }) -join ' '
    [void]$builder.AppendLine(('  <polyline points="{0}" fill="none" stroke="#138a2e" stroke-width="3"/>' -f $polyline))

    $index = 0
    foreach ($coordinate in $coordinates) {
        [void]$builder.AppendLine(('  <circle cx="{0:0.##}" cy="{1:0.##}" r="4" fill="#cc0000"/>' -f $coordinate.X,$coordinate.Y))
        [void]$builder.AppendLine(('  <text x="{0:0.##}" y="{1:0.##}" font-family="Arial" font-size="13">P{2}</text>' -f ($coordinate.X+6.0),($coordinate.Y-6.0),$index.ToString('000')))
        $index++
    }
    [void]$builder.AppendLine('</svg>')
    return $builder.ToString()
}

$task = Get-CertaTaskRecord -TaskPath $TaskPath
$projectId = Get-CertaProjectId -Task $task
$projectRoot = New-CertaProjectLayout -ServerRoot $ServerRoot -ProjectId $projectId
$taskId = [string]$task.task_id

$inputCsv = Get-CertaInputFiles -InputPath @($task.inputs) |
    Where-Object { $_.Extension -eq '.csv' } |
    Sort-Object @{Expression={ if ($_.Name -match '(?i)call|deed|course') { 0 } else { 1 } }}, FullName |
    Select-Object -First 1
if (-not $inputCsv) { throw 'deed-plot-v1 requires a structured calls CSV input.' }

$rows = @(Import-Csv -LiteralPath $inputCsv.FullName)
if ($rows.Count -lt 1) { throw 'The deed calls CSV is empty.' }

$startNorthing = ConvertTo-CertaDouble -Value (Get-CertaPropertyValue -Object $rows[0] -Name @('StartNorthing','StartN','BeginNorthing')) -FieldName 'StartNorthing' -AllowNull
$startEasting = ConvertTo-CertaDouble -Value (Get-CertaPropertyValue -Object $rows[0] -Name @('StartEasting','StartE','BeginEasting')) -FieldName 'StartEasting' -AllowNull
if ($null -eq $startNorthing) { $startNorthing = 0.0 }
if ($null -eq $startEasting) { $startEasting = 0.0 }
$units = [string](Get-CertaPropertyValue -Object $rows[0] -Name @('Units','Unit'))
if ([string]::IsNullOrWhiteSpace($units)) { $units = 'ftUS' }

$currentN = [double]$startNorthing
$currentE = [double]$startEasting
$totalLength = 0.0
$callRows = @()
$pointRows = @([pscustomobject]@{ P=1; N=$currentN; E=$currentE; EL=0.0; DESC='BEGIN DEED RAW PLOT' })
$warningRows = @()

$sequence = 0
foreach ($row in $rows) {
    $sequence++
    $bearingRaw = [string](Get-CertaPropertyValue -Object $row -Name @('Bearing','BRG','Course','ChordBearing'))
    $distanceValue = Get-CertaPropertyValue -Object $row -Name @('Distance','Dist','Length','ChordDistance')
    $curveIndicator = Get-CertaPropertyValue -Object $row -Name @('Radius','ArcLength','Delta','Curve')
    if ([string]::IsNullOrWhiteSpace($bearingRaw) -or $null -eq $distanceValue) {
        if ($null -ne $curveIndicator) {
            throw "Row $sequence is a curve without a verified chord bearing and chord distance. v1 will not invent curve geometry."
        }
        throw "Row $sequence requires Bearing and Distance."
    }

    $distance = ConvertTo-CertaDouble -Value $distanceValue -FieldName "Distance row $sequence"
    if ($distance -le 0.0) { throw "Distance must be greater than zero at row $sequence." }
    $azimuth = Convert-CertaBearingToAzimuth -Bearing $bearingRaw
    $radians = $azimuth * [math]::PI / 180.0
    $deltaN = [math]::Cos($radians) * $distance
    $deltaE = [math]::Sin($radians) * $distance
    $endN = $currentN + $deltaN
    $endE = $currentE + $deltaE
    $description = [string](Get-CertaPropertyValue -Object $row -Name @('Description','DESC','Call','Notes'))
    $source = [string](Get-CertaPropertyValue -Object $row -Name @('Source','Citation','BookPage'))

    $callRows += [pscustomobject]@{
        sequence=$sequence
        bearing_raw=$bearingRaw
        azimuth_degrees=$azimuth
        distance=$distance
        units=$units
        delta_northing=$deltaN
        delta_easting=$deltaE
        start_northing=$currentN
        start_easting=$currentE
        end_northing=$endN
        end_easting=$endE
        description=$description
        source=$source
        authority='RAW_UNADJUSTED_RECORD_CALL'
    }
    $pointRows += [pscustomobject]@{
        P=$sequence+1
        N=$endN
        E=$endE
        EL=0.0
        DESC=if ([string]::IsNullOrWhiteSpace($description)) { "DEED CALL $sequence" } else { $description }
    }
    if ($null -ne $curveIndicator) {
        $warningRows += [pscustomobject]@{
            code='CURVE_PLOTTED_AS_VERIFIED_CHORD'
            severity='REVIEW'
            sequence=$sequence
            detail='Curve fields were present; v1 plotted only the supplied bearing/distance chord.'
        }
    }
    $totalLength += $distance
    $currentN = $endN
    $currentE = $endE
}

$closureN = $currentN - [double]$startNorthing
$closureE = $currentE - [double]$startEasting
$linearMisclosure = [math]::Sqrt(($closureN*$closureN)+($closureE*$closureE))
$closureRatio = if ($linearMisclosure -le 0.000000001) { $null } else { $totalLength/$linearMisclosure }

$area2 = 0.0
for ($index=0; $index -lt $pointRows.Count; $index++) {
    $next = ($index+1) % $pointRows.Count
    $area2 += ([double]$pointRows[$index].E * [double]$pointRows[$next].N) - ([double]$pointRows[$next].E * [double]$pointRows[$index].N)
}
$areaSquareUnits = [math]::Abs($area2)/2.0
$areaAcres = if ($units -match '(?i)ft') { $areaSquareUnits/43560.0 } else { $null }
if ($linearMisclosure -gt 0.01) {
    $warningRows += [pscustomobject]@{
        code='OPEN_CLOSURE'
        severity='REVIEW'
        sequence=''
        detail=('Raw calls misclose by {0:0.####} {1}. No adjustment was applied.' -f $linearMisclosure,$units)
    }
}
if ($warningRows.Count -eq 0) {
    $warningRows = @([pscustomobject]@{ code='NONE'; severity='INFO'; sequence=''; detail='No structural warnings. Professional review is still required.' })
}

$outputRoot = Join-Path $projectRoot "04_PROCESSING_CALCS\DEED_PLOTS\$taskId"
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$callsPath = Join-Path $outputRoot 'RAW_DEED_CALLS_COMPUTED.csv'
$pointsPath = Join-Path $outputRoot 'RAW_DEED_POINTS_PNEZD.csv'
$warningsPath = Join-Path $outputRoot 'PLOT_WARNINGS.csv'
$dxfPath = Join-Path $outputRoot 'RAW_DEED_PLOT.dxf'
$svgPath = Join-Path $outputRoot 'RAW_DEED_PLOT_PREVIEW.svg'
$closurePath = Join-Path $outputRoot 'RAW_CLOSURE_REPORT.json'
$receiptPath = Join-Path $outputRoot 'PLOT_RECEIPT.json'

$callRows | Export-Csv -LiteralPath $callsPath -NoTypeInformation -Encoding UTF8
$pointRows | Export-Csv -LiteralPath $pointsPath -NoTypeInformation -Encoding UTF8
$warningRows | Export-Csv -LiteralPath $warningsPath -NoTypeInformation -Encoding UTF8

$spread = [math]::Max(
    [double](($pointRows | Measure-Object E -Maximum).Maximum)-[double](($pointRows | Measure-Object E -Minimum).Minimum),
    [double](($pointRows | Measure-Object N -Maximum).Maximum)-[double](($pointRows | Measure-Object N -Minimum).Minimum)
)
$textHeight = [math]::Max(1.0,$spread/100.0)
Write-CertaTextFile -Path $dxfPath -Content (ConvertTo-CertaDxfText -Call $callRows -Point $pointRows -TextHeight $textHeight)
Write-CertaTextFile -Path $svgPath -Content (ConvertTo-CertaSvgText -Point $pointRows -Title "$projectId raw deed plot")

$closureReport = [ordered]@{
    schema_version=1
    task_id=$taskId
    project_id=$projectId
    source_calls=$inputCsv.FullName
    units=$units
    call_count=$callRows.Count
    total_distance=$totalLength
    closure_northing=$closureN
    closure_easting=$closureE
    linear_misclosure=$linearMisclosure
    closure_ratio=$closureRatio
    closure_ratio_text=if ($null -eq $closureRatio) { 'INFINITE_OR_EXACT_WITHIN_NUMERIC_TOLERANCE' } else { '1:'+[math]::Round($closureRatio,0) }
    area_square_units=$areaSquareUnits
    area_acres=$areaAcres
    adjustment_applied=$false
    authority='RAW_UNADJUSTED_CANDIDATE_GEOMETRY'
    review_required=$true
}
Write-CertaJsonFile -Path $closurePath -Value $closureReport
Write-CertaJsonFile -Path $receiptPath -Value ([ordered]@{
    schema_version=1
    timestamp=(Get-Date).ToUniversalTime().ToString('o')
    task_id=$taskId
    project_id=$projectId
    source=$inputCsv.FullName
    source_rows=$rows.Count
    plotted_calls=$callRows.Count
    output_root=$outputRoot
    closure_report=$closurePath
    adjustment_applied=$false
    source_modified=$false
    status='PASS'
})

$outputPaths = @($callsPath,$pointsPath,$warningsPath,$dxfPath,$svgPath,$closurePath,$receiptPath)
$null = Test-CertaOutputPaths -Path $outputPaths
if ($callRows.Count -ne $rows.Count) { throw 'Plot validator failed: plotted call count does not match input row count.' }

[pscustomobject]@{
    status='PASS'
    output_paths=$outputPaths
    validator='PASS'
    project_id=$projectId
    call_count=$callRows.Count
    linear_misclosure=$linearMisclosure
    area_square_units=$areaSquareUnits
    output_root=$outputRoot
}
