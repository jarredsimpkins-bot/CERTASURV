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
    $azimuth = 0.0
    if ([double]::TryParse(
        $text,
        [Globalization.NumberStyles]::Float,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$azimuth
    )) {
        $azimuth = $azimuth % 360.0
        if ($azimuth -lt 0) { $azimuth += 360.0 }
        return $azimuth
    }

    if ($text.Length -lt 3) { throw "Invalid quadrant bearing: $Bearing" }
    $northSouth = $text.Substring(0,1)
    $eastWest = $text.Substring($text.Length - 1,1)
    if ($northSouth -notin @('N','S') -or $eastWest -notin @('E','W')) {
        throw "Bearing must be numeric azimuth or quadrant bearing: $Bearing"
    }

    $middle = $text.Substring(1, $text.Length - 2)
    $middle = [regex]::Replace($middle, '[^0-9\.\-\+]+', ' ').Trim()
    $parts = @($middle -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($parts.Count -lt 1 -or $parts.Count -gt 3) {
        throw "Unable to parse bearing degrees/minutes/seconds: $Bearing"
    }

    $degrees = ConvertTo-CertaDouble -Value $parts[0] -FieldName 'bearing degrees'
    $minutes = if ($parts.Count -ge 2) { ConvertTo-CertaDouble -Value $parts[1] -FieldName 'bearing minutes' } else { 0.0 }
    $seconds = if ($parts.Count -ge 3) { ConvertTo-CertaDouble -Value $parts[2] -FieldName 'bearing seconds' } else { 0.0 }
    $angle = [math]::Abs($degrees) + ($minutes / 60.0) + ($seconds / 3600.0)
    if ($angle -gt 90.0 -or $minutes -ge 60.0 -or $seconds -ge 60.0) {
        throw "Quadrant bearing is outside valid range: $Bearing"
    }

    if ($northSouth -eq 'N' -and $eastWest -eq 'E') { return $angle }
    if ($northSouth -eq 'N' -and $eastWest -eq 'W') { return (360.0 - $angle) % 360.0 }
    if ($northSouth -eq 'S' -and $eastWest -eq 'E') { return 180.0 - $angle }
    return 180.0 + $angle
}

function Get-CertaDxfText {
    param(
        [Parameter(Mandatory)][object[]]$Calls,
        [Parameter(Mandatory)][object[]]$Points,
        [double]$TextHeight
    )

    $builder = New-Object Text.StringBuilder
    [void]$builder.AppendLine('0')
    [void]$builder.AppendLine('SECTION')
    [void]$builder.AppendLine('2')
    [void]$builder.AppendLine('ENTITIES')

    foreach ($call in $Calls) {
        [void]$builder.AppendLine('0')
        [void]$builder.AppendLine('LINE')
        [void]$builder.AppendLine('8')
        [void]$builder.AppendLine('DEED_RAW')
        [void]$builder.AppendLine('62')
        [void]$builder.AppendLine('3')
        [void]$builder.AppendLine('10')
        [void]$builder.AppendLine(([double]$call.start_easting).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.AppendLine('20')
        [void]$builder.AppendLine(([double]$call.start_northing).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.AppendLine('30')
        [void]$builder.AppendLine('0')
        [void]$builder.AppendLine('11')
        [void]$builder.AppendLine(([double]$call.end_easting).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.AppendLine('21')
        [void]$builder.AppendLine(([double]$call.end_northing).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.AppendLine('31')
        [void]$builder.AppendLine('0')

        $label = "{0}: {1}  {2}" -f $call.sequence, $call.bearing_raw, ([double]$call.distance).ToString('0.###', [Globalization.CultureInfo]::InvariantCulture)
        [void]$builder.AppendLine('0')
        [void]$builder.AppendLine('TEXT')
        [void]$builder.AppendLine('8')
        [void]$builder.AppendLine('DEED_LABELS')
        [void]$builder.AppendLine('62')
        [void]$builder.AppendLine('3')
        [void]$builder.AppendLine('10')
        [void]$builder.AppendLine(((([double]$call.start_easting + [double]$call.end_easting) / 2.0).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture)))
        [void]$builder.AppendLine('20')
        [void]$builder.AppendLine(((([double]$call.start_northing + [double]$call.end_northing) / 2.0).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture)))
        [void]$builder.AppendLine('30')
        [void]$builder.AppendLine('0')
        [void]$builder.AppendLine('40')
        [void]$builder.AppendLine($TextHeight.ToString('0.###', [Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.AppendLine('1')
        [void]$builder.AppendLine($label.Replace("`r",' ').Replace("`n",' '))
    }

    foreach ($point in $Points) {
        [void]$builder.AppendLine('0')
        [void]$builder.AppendLine('POINT')
        [void]$builder.AppendLine('8')
        [void]$builder.AppendLine('DEED_POINTS')
        [void]$builder.AppendLine('62')
        [void]$builder.AppendLine('3')
        [void]$builder.AppendLine('10')
        [void]$builder.AppendLine(([double]$point.E).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.AppendLine('20')
        [void]$builder.AppendLine(([double]$point.N).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture))
        [void]$builder.AppendLine('30')
        [void]$builder.AppendLine('0')
    }

    [void]$builder.AppendLine('0')
    [void]$builder.AppendLine('ENDSEC')
    [void]$builder.AppendLine('0')
    [void]$builder.AppendLine('EOF')
    return $builder.ToString()
}

function Get-CertaSvg {
    param(
        [Parameter(Mandatory)][object[]]$Calls,
        [Parameter(Mandatory)][object[]]$Points,
        [Parameter(Mandatory)][string]$Title
    )

    $eastings = @($Points | ForEach-Object { [double]$_.E })
    $northings = @($Points | ForEach-Object { [double]$_.N })
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

    $pointText = New-Object System.Collections.Generic.List[string]
    foreach ($point in $Points) {
        $x = $padding + (([double]$point.E - $minE) * $scale)
        $y = $canvasHeight - $padding - (([double]$point.N - $minN) * $scale)
        $pointText.Add(("{0:0.##},{1:0.##}" -f $x,$y))
    }

    $polyline = $pointText -join ' '
    $escapedTitle = Escape-CertaXml -Value $Title
    $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="$([int]$canvasWidth)" height="$([int]$canvasHeight)" viewBox="0 0 $([int]$canvasWidth) $([int]$canvasHeight)">
  <rect width="100%" height="100%" fill="white"/>
  <text x="30" y="35" font-family="Arial" font-size="22" font-weight="bold">$escapedTitle</text>
  <polyline points="$polyline" fill="none" stroke="#138a2e" stroke-width="3"/>
"@
    $index = 0
    foreach ($point in $Points) {
        $x = $padding + (([double]$point.E - $minE) * $scale)
        $y = $canvasHeight - $padding - (([double]$point.N - $minN) * $scale)
        $svg += ('  <circle cx="{0}" cy="{1}" r="4" fill="#cc0000"/>' -f [math]::Round($x,2),[math]::Round($y,2)) + "`n"
        $svg += ('  <text x="{0}" y="{1}" font-family="Arial" font-size="13">P{2}</text>' -f [math]::Round($x+6,2),[math]::Round($y-6,2),$index.ToString('000')) + "`n"
        $index++
    }
    $svg += '</svg>'
    return $svg
}

$task = Get-CertaTaskRecord -TaskPath $TaskPath
$projectId = Get-CertaProjectId -Task $task
$projectRoot = New-CertaProjectLayout -ServerRoot $ServerRoot -ProjectId $projectId
$taskId = [string]$task.task_id

$inputCsv = @(Get-CertaInputFiles -InputPath @($task.inputs) | Where-Object { $_.Extension -eq '.csv' } | Select-Object -First 1)
if (-not $inputCsv) { throw 'deed-plot-v1 requires a structured calls CSV input.' }

$rows = @(Import-Csv -LiteralPath $inputCsv.FullName)
if ($rows.Count -lt 1) { throw 'The deed calls CSV is empty.' }

$firstRow = $rows[0]
$startNorthing = ConvertTo-CertaDouble -Value (Get-CertaPropertyValue -Object $firstRow -Name @('StartNorthing','StartN','BeginNorthing')) -FieldName 'StartNorthing' -AllowNull
$startEasting = ConvertTo-CertaDouble -Value (Get-CertaPropertyValue -Object $firstRow -Name @('StartEasting','StartE','BeginEasting')) -FieldName 'StartEasting' -AllowNull
if ($null -eq $startNorthing) { $startNorthing = 0.0 }
if ($null -eq $startEasting) { $startEasting = 0.0 }
$units = [string](Get-CertaPropertyValue -Object $firstRow -Name @('Units','Unit'))
if ([string]::IsNullOrWhiteSpace($units)) { $units = 'ftUS' }

$currentN = [double]$startNorthing
$currentE = [double]$startEasting
$totalLength = 0.0
$callRows = New-Object System.Collections.Generic.List[object]
$pointRows = New-Object System.Collections.Generic.List[object]
$warningRows = New-Object System.Collections.Generic.List[object]
$pointRows.Add([pscustomobject]@{ P=1; N=$currentN; E=$currentE; EL=0.0; DESC='BEGIN DEED RAW PLOT' })

$sequence = 0
foreach ($row in $rows) {
    $sequence++
    $bearingRaw = [string](Get-CertaPropertyValue -Object $row -Name @('Bearing','BRG','Course','ChordBearing'))
    $distanceValue = Get-CertaPropertyValue -Object $row -Name @('Distance','Dist','Length','ChordDistance')
    $curveIndicator = Get-CertaPropertyValue -Object $row -Name @('Radius','ArcLength','Delta','Curve')

    if ([string]::IsNullOrWhiteSpace($bearingRaw) -or $null -eq $distanceValue) {
        if ($null -ne $curveIndicator) {
            throw "Row $sequence is a curve without a usable chord bearing and chord distance. Route it to normalization/review; v1 will not invent curve geometry."
        }
        throw "Row $sequence requires Bearing and Distance."
    }

    $distance = ConvertTo-CertaDouble -Value $distanceValue -FieldName "Distance row $sequence"
    if ($distance -le 0) { throw "Distance must be greater than zero at row $sequence." }
    $azimuth = Convert-CertaBearingToAzimuth -Bearing $bearingRaw
    $radians = $azimuth * [math]::PI / 180.0
    $deltaN = [math]::Cos($radians) * $distance
    $deltaE = [math]::Sin($radians) * $distance
    $endN = $currentN + $deltaN
    $endE = $currentE + $deltaE
    $description = [string](Get-CertaPropertyValue -Object $row -Name @('Description','DESC','Call','Notes'))
    $source = [string](Get-CertaPropertyValue -Object $row -Name @('Source','Citation','BookPage'))

    $callRows.Add([pscustomobject]@{
        sequence = $sequence
        bearing_raw = $bearingRaw
        azimuth_degrees = $azimuth
        distance = $distance
        units = $units
        delta_northing = $deltaN
        delta_easting = $deltaE
        start_northing = $currentN
        start_easting = $currentE
        end_northing = $endN
        end_easting = $endE
        description = $description
        source = $source
        authority = 'RAW_UNADJUSTED_RECORD_CALL'
    })
    $pointRows.Add([pscustomobject]@{
        P = $sequence + 1
        N = $endN
        E = $endE
        EL = 0.0
        DESC = if ([string]::IsNullOrWhiteSpace($description)) { "DEED CALL $sequence" } else { $description }
    })
    $totalLength += $distance
    $currentN = $endN
    $currentE = $endE
}

$closureN = $currentN - $startNorthing
$closureE = $currentE - $startEasting
$linearMisclosure = [math]::Sqrt(($closureN*$closureN) + ($closureE*$closureE))
$closureRatio = if ($linearMisclosure -le 0.000000001) { $null } else { $totalLength / $linearMisclosure }

$area2 = 0.0
for ($i=0; $i -lt $pointRows.Count; $i++) {
    $j = ($i + 1) % $pointRows.Count
    $area2 += ([double]$pointRows[$i].E * [double]$pointRows[$j].N) -
              ([double]$pointRows[$j].E * [double]$pointRows[$i].N)
}
$areaSquareUnits = [math]::Abs($area2) / 2.0
$areaAcres = if ($units -match '(?i)ft') { $areaSquareUnits / 43560.0 } else { $null }

if ($linearMisclosure -gt 0.01) {
    $warningRows.Add([pscustomobject]@{
        code='OPEN_CLOSURE'
        severity='REVIEW'
        sequence=''
        detail=("Raw calls misclose by {0:0.####} {1}. No adjustment was applied." -f $linearMisclosure,$units)
    })
}
if ($warningRows.Count -eq 0) {
    $warningRows.Add([pscustomobject]@{ code='NONE'; severity='INFO'; sequence=''; detail='No structural warnings. Professional review is still required.' })
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
    (($pointRows | Measure-Object -Property E -Maximum).Maximum - ($pointRows | Measure-Object -Property E -Minimum).Minimum),
    (($pointRows | Measure-Object -Property N -Maximum).Maximum - ($pointRows | Measure-Object -Property N -Minimum).Minimum)
)
$textHeight = [math]::Max(1.0, $spread / 100.0)
Write-CertaTextFile -Path $dxfPath -Content (Get-CertaDxfText -Calls @($callRows) -Points @($pointRows) -TextHeight $textHeight)
Write-CertaTextFile -Path $svgPath -Content (Get-CertaSvg -Calls @($callRows) -Points @($pointRows) -Title "$projectId raw deed plot")

$closureReport = [ordered]@{
    schema_version = 1
    task_id = $taskId
    project_id = $projectId
    source_calls = $inputCsv.FullName
    units = $units
    call_count = $callRows.Count
    total_distance = $totalLength
    closure_northing = $closureN
    closure_easting = $closureE
    linear_misclosure = $linearMisclosure
    closure_ratio = $closureRatio
    closure_ratio_text = if ($null -eq $closureRatio) { 'INFINITE_OR_EXACT_WITHIN_NUMERIC_TOLERANCE' } else { '1:' + ([math]::Round($closureRatio,0)).ToString([Globalization.CultureInfo]::InvariantCulture) }
    area_square_units = $areaSquareUnits
    area_acres = $areaAcres
    adjustment_applied = $false
    authority = 'RAW_UNADJUSTED_CANDIDATE_GEOMETRY'
    review_required = $true
}
Write-CertaJsonFile -Path $closurePath -Value $closureReport

$receipt = [ordered]@{
    schema_version = 1
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
    task_id = $taskId
    project_id = $projectId
    source = $inputCsv.FullName
    source_rows = $rows.Count
    plotted_calls = $callRows.Count
    output_root = $outputRoot
    closure_report = $closurePath
    adjustment_applied = $false
    source_modified = $false
    status = 'PASS'
}
Write-CertaJsonFile -Path $receiptPath -Value $receipt

$outputs = @($callsPath,$pointsPath,$warningsPath,$dxfPath,$svgPath,$closurePath,$receiptPath)
$null = Test-CertaOutputPaths -Path $outputs
if ($callRows.Count -ne $rows.Count) { throw 'Plot validator failed: plotted call count does not match input row count.' }

[pscustomobject]@{
    status = 'PASS'
    output_paths = $outputs
    validator = 'PASS'
    project_id = $projectId
    call_count = $callRows.Count
    linear_misclosure = $linearMisclosure
    area_square_units = $areaSquareUnits
    output_root = $outputRoot
}
