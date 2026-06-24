param(
    [string]$ScriptsPath = (Join-Path $PSScriptRoot '*.ps1')
)

$ErrorActionPreference = 'Stop'

$legacyWebAppPath = 'New' + ' project2'
$thisScript = $PSCommandPath
$matches = Get-ChildItem -Path $ScriptsPath | Where-Object {
    $_.FullName -ne $thisScript
} | Select-String -Pattern $legacyWebAppPath -SimpleMatch

if ($matches) {
    foreach ($match in $matches) {
        Write-Error "Legacy web app path reference in $($match.Path):$($match.LineNumber)"
    }
    exit 1
}

Write-Host 'Release path guards passed.'
