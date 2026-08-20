#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$SourceRoot = $PSScriptRoot,
    [switch]$KeepTestRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-TestJson {
    param([string]$Path,$Value)
    $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Assert-TestPath {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Expected test output missing: $Path" }
}

$required = @(
    'CertaServer.Common.ps1',
    'Initialize-CertaProjectTask.ps1',
    'New-CertaCourthousePacketTask.ps1',
    'New-CertaDeedPlotTask.ps1',
    'New-CertaWorkmapTask.ps1',
    'Update-CertaFieldReturnTask.ps1'
)
foreach ($name in $required) {
    Assert-TestPath -Path (Join-Path $SourceRoot $name)
}

$testRoot = Join-Path $env:TEMP ('certa-production-test-' + [guid]::NewGuid().ToString('N'))
$serverRoot = Join-Path $testRoot 'SERVER'
$stagingRoot = Join-Path $serverRoot 'STAGING'
New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null

try {
    $sampleScope = Join-Path $stagingRoot 'INTAKE_SCOPE.txt'
    Set-Content -LiteralPath $sampleScope -Value 'Boundary survey intake test' -Encoding UTF8
    $sampleKml = Join-Path $stagingRoot 'SUBJECT.kml'
    Set-Content -LiteralPath $sampleKml -Value '<kml></kml>' -Encoding UTF8
    $intakeTask = Join-Path $testRoot 'intake-task.json'
    Write-TestJson -Path $intakeTask -Value ([ordered]@{
        schema_version=1
        task_id='test-intake'
        project_id='SSD-TEST-001'
        request='Create governed project intake.'
        inputs=@($sampleScope,$sampleKml)
        sensitivity='COMPANY'
    })
    $intakeResult = & (Join-Path $SourceRoot 'Initialize-CertaProjectTask.ps1') -ServerRoot $serverRoot -TaskPath $intakeTask
    if ([string]$intakeResult.status -ne 'PASS') { throw 'Project intake test failed.' }
    foreach ($path in @($intakeResult.output_paths)) { Assert-TestPath -Path $path }

    $parcelCsv = Join-Path $stagingRoot 'parcel-register.csv'
    @(
        [pscustomobject]@{ ParcelId='SUBJECT'; TaxMap='15'; Parcel='32'; District='Carroll'; Owner='Test Owner'; Role='SUBJECT' },
        [pscustomobject]@{ ParcelId='ADJ-1'; TaxMap='15'; Parcel='31'; District='Carroll'; Owner='Adjoiner'; Role='ADJOINER' }
    ) | Export-Csv -LiteralPath $parcelCsv -NoTypeInformation -Encoding UTF8
    $deedFile = Join-Path $stagingRoot 'SUBJECT_DB_100_PG_200_DEED.pdf'
    Set-Content -LiteralPath $deedFile -Value 'Synthetic deed evidence' -Encoding UTF8
    $mapCardFile = Join-Path $stagingRoot 'SUBJECT_MAP_CARD.png'
    Set-Content -LiteralPath $mapCardFile -Value 'Synthetic map card evidence' -Encoding UTF8
    $courthouseTask = Join-Path $testRoot 'courthouse-task.json'
    Write-TestJson -Path $courthouseTask -Value ([ordered]@{
        schema_version=1
        task_id='test-courthouse'
        project_id='SSD-TEST-001'
        request='Build courthouse research packet.'
        inputs=@($parcelCsv,$deedFile,$mapCardFile)
        sensitivity='COMPANY'
    })
    $courthouseResult = & (Join-Path $SourceRoot 'New-CertaCourthousePacketTask.ps1') -ServerRoot $serverRoot -TaskPath $courthouseTask
    if ([string]$courthouseResult.status -ne 'PASS') { throw 'Courthouse packet test failed.' }
    foreach ($path in @($courthouseResult.output_paths)) { Assert-TestPath -Path $path }

    $callsCsv = Join-Path $stagingRoot 'square-deed-calls.csv'
    @(
        [pscustomobject]@{ Sequence=1; Bearing='90'; Distance='100'; Description='East'; Source='DB 100 PG 200'; StartNorthing=0; StartEasting=0; Units='ftUS' },
        [pscustomobject]@{ Sequence=2; Bearing='180'; Distance='100'; Description='South'; Source='DB 100 PG 200'; StartNorthing=''; StartEasting=''; Units='ftUS' },
        [pscustomobject]@{ Sequence=3; Bearing='270'; Distance='100'; Description='West'; Source='DB 100 PG 200'; StartNorthing=''; StartEasting=''; Units='ftUS' },
        [pscustomobject]@{ Sequence=4; Bearing='0'; Distance='100'; Description='North'; Source='DB 100 PG 200'; StartNorthing=''; StartEasting=''; Units='ftUS' }
    ) | Export-Csv -LiteralPath $callsCsv -NoTypeInformation -Encoding UTF8
    $plotTask = Join-Path $testRoot 'plot-task.json'
    Write-TestJson -Path $plotTask -Value ([ordered]@{
        schema_version=1
        task_id='test-deed-plot'
        project_id='SSD-TEST-001'
        request='Create raw deed auto plot and closure report.'
        inputs=@($callsCsv)
        sensitivity='COMPANY'
    })
    $plotResult = & (Join-Path $SourceRoot 'New-CertaDeedPlotTask.ps1') -ServerRoot $serverRoot -TaskPath $plotTask
    if ([string]$plotResult.status -ne 'PASS') { throw 'Deed plot test failed.' }
    foreach ($path in @($plotResult.output_paths)) { Assert-TestPath -Path $path }
    $closurePath = @($plotResult.output_paths | Where-Object { $_ -like '*RAW_CLOSURE_REPORT.json' }) | Select-Object -First 1
    $closure = Get-Content -LiteralPath $closurePath -Raw | ConvertFrom-Json
    if ([math]::Abs([double]$closure.linear_misclosure) -gt 0.000001) { throw "Unexpected synthetic closure: $($closure.linear_misclosure)" }
    if ([math]::Abs([double]$closure.area_square_units - 10000.0) -gt 0.001) { throw "Unexpected synthetic area: $($closure.area_square_units)" }

    $pointsCsv = Join-Path $stagingRoot 'workmap-points.csv'
    @(
        [pscustomobject]@{ P='F300'; N=1000; E=1000; EL=100; DESC='SEARCH MON'; Status='SEARCH'; Latitude=38.10; Longitude=-81.10 },
        [pscustomobject]@{ P='F301'; N=1010; E=1000; EL=101; DESC='SHOOT ROAD'; Status='SEARCH'; Latitude=38.1001; Longitude=-81.10 },
        [pscustomobject]@{ P='101'; N=1001; E=1001; EL=100.2; DESC='1 IN IRON PIPE FOUND'; Status='FOUND'; Latitude=38.10001; Longitude=-81.09999 },
        [pscustomobject]@{ P='S500'; N=1020; E=1005; EL=102; DESC='5/8 IN REBAR SET'; Status='SET'; Latitude=38.1002; Longitude=-81.0999 },
        [pscustomobject]@{ P='BASE1'; N=990; E=990; EL=99; DESC='BASE'; Status='CONTROL'; Latitude=38.0999; Longitude=-81.1001 }
    ) | Export-Csv -LiteralPath $pointsCsv -NoTypeInformation -Encoding UTF8
    $workmapTask = Join-Path $testRoot 'workmap-task.json'
    Write-TestJson -Path $workmapTask -Value ([ordered]@{
        schema_version=1
        task_id='test-workmap'
        project_id='SSD-TEST-001'
        request='Build workmap package.'
        inputs=@($pointsCsv)
        sensitivity='COMPANY'
    })
    $workmapResult = & (Join-Path $SourceRoot 'New-CertaWorkmapTask.ps1') -ServerRoot $serverRoot -TaskPath $workmapTask
    if ([string]$workmapResult.status -ne 'PASS') { throw 'Workmap test failed.' }
    foreach ($path in @($workmapResult.output_paths)) { Assert-TestPath -Path $path }

    $overlayTask = Join-Path $testRoot 'overlay-task.json'
    Write-TestJson -Path $overlayTask -Value ([ordered]@{
        schema_version=1
        task_id='test-overlay'
        project_id='SSD-TEST-001'
        request='Create F300-F301 label overlay only.'
        inputs=@($pointsCsv)
        sensitivity='COMPANY'
    })
    $overlayResult = & (Join-Path $SourceRoot 'New-CertaWorkmapTask.ps1') -ServerRoot $serverRoot -TaskPath $overlayTask
    if (-not [bool]$overlayResult.overlay_mode -or [int]$overlayResult.point_count -ne 2) { throw 'F-range overlay test failed.' }

    $fieldReturnCsv = Join-Path $stagingRoot 'field-return.csv'
    @(
        [pscustomobject]@{ P='301'; N=1000.5; E=1000.5; EL=100.1; DESC='1 IN IRON PIPE FOUND NEAR SEARCH'; Status='FOUND'; ObservedAt='2026-08-20T12:00:00Z' },
        [pscustomobject]@{ P='TRV10'; N=995; E=995; EL=99.5; DESC='TRV CONTROL'; Status='CONTROL'; ObservedAt='2026-08-20T12:01:00Z' }
    ) | Export-Csv -LiteralPath $fieldReturnCsv -NoTypeInformation -Encoding UTF8
    $fieldTask = Join-Path $testRoot 'field-task.json'
    Write-TestJson -Path $fieldTask -Value ([ordered]@{
        schema_version=1
        task_id='test-field-return'
        project_id='SSD-TEST-001'
        request='Ingest field return with tolerance 5 ft and update workmap.'
        inputs=@($pointsCsv,$fieldReturnCsv)
        sensitivity='COMPANY'
    })
    $fieldResult = & (Join-Path $SourceRoot 'Update-CertaFieldReturnTask.ps1') -ServerRoot $serverRoot -TaskPath $fieldTask
    if ([string]$fieldResult.status -ne 'PASS') { throw 'Field-return test failed.' }
    foreach ($path in @($fieldResult.output_paths)) { Assert-TestPath -Path $path }

    Write-Output 'CERTA_PRODUCTION_CAPABILITIES_TEST_PASS'
}
finally {
    if (-not $KeepTestRoot -and (Test-Path -LiteralPath $testRoot)) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
    elseif ($KeepTestRoot) {
        Write-Host "Test root preserved: $testRoot"
    }
}
