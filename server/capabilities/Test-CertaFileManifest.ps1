#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$SourcePath,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ManifestPath,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$SummaryPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$source = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $SourcePath).Path).TrimEnd('\')
$manifest = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $ManifestPath).Path)
$summaryFile = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $SummaryPath).Path)
$sourcePrefix = $source + '\'
$summary = Get-Content -LiteralPath $summaryFile -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $manifest)

if ([int]$summary.schema_version -ne 1) { throw 'Manifest summary schema_version must equal 1.' }
if ([int]$summary.file_count -ne $rows.Count) { throw 'Manifest row count does not match the summary.' }
if (@($rows | Group-Object relative_path | Where-Object Count -gt 1).Count -gt 0) { throw 'Manifest contains duplicate relative paths.' }

$rowPaths = @{}
foreach ($row in $rows) {
    $fullPath = [IO.Path]::GetFullPath([string]$row.full_path)
    if (-not $fullPath.StartsWith($sourcePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Manifest path escapes the source root: $fullPath"
    }
    if ([string]::Equals($fullPath, $manifest, [StringComparison]::OrdinalIgnoreCase) -or [string]::Equals($fullPath, $summaryFile, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Manifest must not include its own CSV or summary output.'
    }
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { throw "Manifest file is missing: $fullPath" }
    if ([int64](Get-Item -LiteralPath $fullPath).Length -ne [int64]$row.size_bytes) { throw "Manifest size mismatch: $fullPath" }
    if ([string]$row.hash_status -eq 'HASHED') {
        $actualHash = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
        if (-not [string]::Equals($actualHash, [string]$row.sha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Manifest hash mismatch: $fullPath"
        }
    }
    $rowPaths[$fullPath.ToLowerInvariant()] = $true
}

$currentFiles = @(Get-ChildItem -LiteralPath $source -File -Recurse -Force -ErrorAction Stop | Where-Object {
    $candidate = [IO.Path]::GetFullPath($_.FullName)
    -not [string]::Equals($candidate, $manifest, [StringComparison]::OrdinalIgnoreCase) -and
    -not [string]::Equals($candidate, $summaryFile, [StringComparison]::OrdinalIgnoreCase)
})
if ($currentFiles.Count -ne $rows.Count) { throw 'Manifest file set no longer matches the source tree.' }
foreach ($file in $currentFiles) {
    if (-not $rowPaths.ContainsKey([IO.Path]::GetFullPath($file.FullName).ToLowerInvariant())) { throw "Manifest omitted source file: $($file.FullName)" }
}

[pscustomobject]@{
    status = 'PASS'
    validated_at = (Get-Date).ToUniversalTime().ToString('o')
    row_count = $rows.Count
    hashed_count = @($rows | Where-Object hash_status -eq 'HASHED').Count
}
