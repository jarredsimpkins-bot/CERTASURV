$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $PSCommandPath
$legacyPath = 'New ' + 'project2'
$scripts = Get-ChildItem -LiteralPath $scriptRoot -Filter *.ps1 |
    Where-Object { $_.FullName -ne $PSCommandPath }

$hits = $scripts | Select-String -Pattern $legacyPath -SimpleMatch
if ($hits) {
    $hits | ForEach-Object {
        Write-Error "$($_.Path):$($_.LineNumber): legacy web app path reference"
    }
    exit 1
}

Write-Host 'Release path policy passed: no legacy web app script paths found.'
exit 0
