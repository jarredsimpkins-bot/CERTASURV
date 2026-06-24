param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

$legacyPatterns = @(
    ('New ' + 'project2')
)

$scriptRoot = Join-Path $Root 'scripts'
$scriptFiles = Get-ChildItem -LiteralPath $scriptRoot -Filter '*.ps1' -File |
    Where-Object { $_.FullName -ne $PSCommandPath }

$hits = foreach ($pattern in $legacyPatterns) {
    $scriptFiles | Select-String -SimpleMatch -Pattern $pattern | ForEach-Object {
        [pscustomobject]@{
            File = $_.Path
            Line = $_.LineNumber
            Pattern = $pattern
            Text = $_.Line.Trim()
        }
    }
}

if ($hits) {
    Write-Error 'Legacy release path references were found in active scripts.'
    $hits | Format-Table -AutoSize -Wrap
    exit 1
}

Write-Host 'Release path guards passed.'
exit 0
