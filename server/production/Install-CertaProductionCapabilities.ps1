#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [switch]$SkipSelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$started = Get-Date
$runId = 'certa-production-capabilities-{0:yyyyMMdd-HHmmss}' -f $started

$requiredRuntime = @(
    'ROUTER\Invoke-CertaScriptTask.ps1',
    'ROUTER\Invoke-CertaQueueWorker.ps1',
    'CONTROL\registries\CAPABILITY_REGISTRY.csv'
)
foreach ($relative in $requiredRuntime) {
    $path = Join-Path $ServerRoot $relative
    if (-not (Test-Path -LiteralPath $path)) {
        throw "The base router and worker extension must be installed first. Missing: $path"
    }
}

$sourceFiles = @(
    'CertaServer.Common.ps1',
    'Initialize-CertaProjectTask.ps1',
    'New-CertaCourthousePacketTask.ps1',
    'New-CertaDeedPlotTask.ps1',
    'New-CertaWorkmapTask.ps1',
    'Update-CertaFieldReturnTask.ps1',
    'Test-CertaProductionCapabilities.ps1'
)
foreach ($name in $sourceFiles) {
    $path = Join-Path $PSScriptRoot $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Production source file is missing: $path" }
}

if (-not $SkipSelfTest) {
    $testOutput = & (Join-Path $PSScriptRoot 'Test-CertaProductionCapabilities.ps1') -SourceRoot $PSScriptRoot 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $testOutput -notmatch 'CERTA_PRODUCTION_CAPABILITIES_TEST_PASS') {
        throw "Production capability self-test failed.`n$testOutput"
    }
}

$folders = @(
    'SCRIPTS',
    'CONTROL\registries',
    'CONTROL\manifests',
    'CONTROL\receipts',
    'CONTROL\tests',
    'PROJECTS'
)
foreach ($relative in $folders) {
    New-Item -ItemType Directory -Path (Join-Path $ServerRoot $relative) -Force | Out-Null
}

$copyMap = [ordered]@{
    'CertaServer.Common.ps1' = 'SCRIPTS\CertaServer.Common.ps1'
    'Initialize-CertaProjectTask.ps1' = 'SCRIPTS\Initialize-CertaProjectTask.ps1'
    'New-CertaCourthousePacketTask.ps1' = 'SCRIPTS\New-CertaCourthousePacketTask.ps1'
    'New-CertaDeedPlotTask.ps1' = 'SCRIPTS\New-CertaDeedPlotTask.ps1'
    'New-CertaWorkmapTask.ps1' = 'SCRIPTS\New-CertaWorkmapTask.ps1'
    'Update-CertaFieldReturnTask.ps1' = 'SCRIPTS\Update-CertaFieldReturnTask.ps1'
    'Test-CertaProductionCapabilities.ps1' = 'CONTROL\tests\Test-CertaProductionCapabilities.ps1'
}
foreach ($entry in $copyMap.GetEnumerator()) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $entry.Key) -Destination (Join-Path $ServerRoot $entry.Value) -Force
}

$registryPath = Join-Path $ServerRoot 'CONTROL\registries\CAPABILITY_REGISTRY.csv'
$existing = if (Test-Path -LiteralPath $registryPath) { @(Import-Csv -LiteralPath $registryPath) } else { @() }
$capabilityIds = @(
    'project-intake-v1',
    'courthouse-packet-v1',
    'deed-plot-v1',
    'workmap-build-v1',
    'field-return-v1'
)
$existing = @($existing | Where-Object { $_.capability_id -notin $capabilityIds })

$newCapabilities = @(
    [pscustomobject]@{
        capability_id='project-intake-v1'
        name='Governed SSD project intake and source registry'
        intent_regex='(?i)(project intake|create governed project|initialize .*project|prepare .*job)'
        status='VERIFIED'
        script_path=(Join-Path $ServerRoot 'SCRIPTS\Initialize-CertaProjectTask.ps1')
        validator_path=''
        node='CERTA-SERVER'
        authority='DETERMINISTIC'
        notes='Creates project structure, manifest, source registry, missing requirements, and receipt. Copies only inputs already staged under the server.'
    },
    [pscustomobject]@{
        capability_id='courthouse-packet-v1'
        name='Courthouse research packet and plot-source gate'
        intent_regex='(?i)(courthouse|research packet|chain of title|map card|deed research|plot source gate)'
        status='VERIFIED'
        script_path=(Join-Path $ServerRoot 'SCRIPTS\New-CertaCourthousePacketTask.ps1')
        validator_path=''
        node='CERTA-SERVER'
        authority='DETERMINISTIC'
        notes='Builds parcel folders, research log, source register, chain template, gaps, and candidate-only plot-source gate. It does not mark a parcel plot-ready.'
    },
    [pscustomobject]@{
        capability_id='deed-plot-v1'
        name='Raw unadjusted deed plot with closure and DXF'
        intent_regex='(?i)(auto.?plot|plot deed|deed calls|closure report|raw deed plot)'
        status='VERIFIED'
        script_path=(Join-Path $ServerRoot 'SCRIPTS\New-CertaDeedPlotTask.ps1')
        validator_path=''
        node='CERTA-SERVER'
        authority='DETERMINISTIC'
        notes='Plots structured bearing/distance or chord calls; writes CSV, DXF, SVG, closure, warnings, and receipt. No adjustment or boundary acceptance.'
    },
    [pscustomobject]@{
        capability_id='workmap-build-v1'
        name='Point-based workmap, stakeout, action register, DXF, SVG, and optional KML'
        intent_regex='(?i)(workmap|field map|stakeout package|f.?series label|search overlay|shoot road|shoot drain)'
        status='VERIFIED'
        script_path=(Join-Path $ServerRoot 'SCRIPTS\New-CertaWorkmapTask.ps1')
        validator_path=''
        node='CERTA-SERVER'
        authority='DETERMINISTIC'
        notes='Applies green search, red found, blue set, orange control, and grey extract rules. F-range requests output only that point family/range.'
    },
    [pscustomobject]@{
        capability_id='field-return-v1'
        name='Field-return point-event ingestion and workmap update'
        intent_regex='(?i)(field return|ingest field|update workmap|field data return|reconcile field points)'
        status='VERIFIED'
        script_path=(Join-Path $ServerRoot 'SCRIPTS\Update-CertaFieldReturnTask.ps1')
        validator_path=''
        node='CERTA-SERVER'
        authority='DETERMINISTIC'
        notes='Preserves unique point events, builds current state, candidate search resolution, unresolved stakeout, updated workmap, and receipt.'
    }
)
($existing + $newCapabilities) |
    Sort-Object capability_id |
    Export-Csv -LiteralPath $registryPath -NoTypeInformation -Encoding UTF8

$installedScriptPaths = @($copyMap.GetEnumerator() | ForEach-Object { Join-Path $ServerRoot $_.Value })
foreach ($path in $installedScriptPaths) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Installed production file missing: $path" }
}

$manifest = [ordered]@{
    schema_version = 1
    installed_at = (Get-Date).ToUniversalTime().ToString('o')
    computer = $env:COMPUTERNAME
    user = "$env:USERDOMAIN\$env:USERNAME"
    server_root = $ServerRoot
    capabilities = $capabilityIds
    installed_files = $installedScriptPaths
    self_test = if ($SkipSelfTest) { 'SKIPPED_BY_OPERATOR' } else { 'PASS' }
    original_sources_preserved = $true
    professional_authority = 'HUMAN_PLS_GATE'
    status = 'PASS'
}
$manifestPath = Join-Path $ServerRoot 'CONTROL\manifests\production-capabilities-v1.json'
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
$receiptPath = Join-Path $ServerRoot "CONTROL\receipts\$runId.json"
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $receiptPath -Encoding UTF8

[pscustomobject]@{
    status='PASS'
    server_root=$ServerRoot
    capability_count=$capabilityIds.Count
    capabilities=$capabilityIds
    manifest=$manifestPath
    receipt=$receiptPath
    next='Create structured tasks with D:\SERVER\ROUTER\New-CertaTask.ps1 and process them with the queue worker.'
}
