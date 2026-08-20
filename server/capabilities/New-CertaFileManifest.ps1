#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$SourcePath,

    [Parameter(Mandatory)]
    [string]$OutputPath,

    [ValidateRange(0, 1048576)]
    [int]$HashFileLimitMiB = 256,

    [ValidateRange(1, 1000000)]
    [int]$MaxFileCount = 100000,

    [ValidateRange(1, 1048576)]
    [int]$MaxTotalHashMiB = 4096
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedSource = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $SourcePath).Path).TrimEnd('\')
$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
$summaryPath = [IO.Path]::ChangeExtension($resolvedOutput, '.summary.json')
$outputParent = Split-Path -Parent $resolvedOutput
if ($outputParent -and -not (Test-Path -LiteralPath $outputParent)) {
    New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
}

$excludedPaths = @($resolvedOutput, $summaryPath)
$files = @(Get-ChildItem -LiteralPath $resolvedSource -File -Recurse -Force -ErrorAction Stop | Where-Object {
    $candidate = [IO.Path]::GetFullPath($_.FullName)
    -not ($excludedPaths | Where-Object { [string]::Equals($_, $candidate, [StringComparison]::OrdinalIgnoreCase) })
})
if ($files.Count -gt $MaxFileCount) {
    throw "Source contains $($files.Count) files, exceeding MaxFileCount $MaxFileCount."
}

$perFileLimitBytes = [int64]$HashFileLimitMiB * 1MB
$totalHashLimitBytes = [int64]$MaxTotalHashMiB * 1MB
$hashedBytes = [int64]0
$rows = New-Object System.Collections.Generic.List[object]

foreach ($file in $files) {
    $relative = $file.FullName.Substring($resolvedSource.Length).TrimStart('\')
    $hash = $null
    $hashStatus = 'SKIPPED_SIZE'
    if ($file.Length -le $perFileLimitBytes) {
        if (($hashedBytes + $file.Length) -le $totalHashLimitBytes) {
            $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
            $hashStatus = 'HASHED'
            $hashedBytes += [int64]$file.Length
        }
        else {
            $hashStatus = 'SKIPPED_TOTAL_LIMIT'
        }
    }

    $rows.Add([pscustomobject]@{
        relative_path = $relative
        full_path = $file.FullName
        size_bytes = [int64]$file.Length
        modified_utc = $file.LastWriteTimeUtc.ToString('o')
        sha256 = $hash
        hash_status = $hashStatus
    })
}

$csvTemporaryPath = Join-Path $outputParent ('.{0}.{1}.tmp' -f ([IO.Path]::GetFileName($resolvedOutput)), [guid]::NewGuid().ToString('N'))
$summaryTemporaryPath = Join-Path $outputParent ('.{0}.{1}.tmp' -f ([IO.Path]::GetFileName($summaryPath)), [guid]::NewGuid().ToString('N'))
try {
    @($rows | Sort-Object relative_path) | Export-Csv -LiteralPath $csvTemporaryPath -NoTypeInformation -Encoding UTF8
    Move-Item -LiteralPath $csvTemporaryPath -Destination $resolvedOutput -Force

    $summary = [ordered]@{
        schema_version = 1
        created_at = (Get-Date).ToUniversalTime().ToString('o')
        source_path = $resolvedSource
        output_path = $resolvedOutput
        file_count = $rows.Count
        total_bytes = [int64](($rows | Measure-Object -Property size_bytes -Sum).Sum)
        hashed_count = @($rows | Where-Object hash_status -eq 'HASHED').Count
        hashed_bytes = $hashedBytes
        skipped_hash_count = @($rows | Where-Object hash_status -ne 'HASHED').Count
        max_file_count = $MaxFileCount
        max_total_hash_mib = $MaxTotalHashMiB
        status = 'PENDING_VALIDATION'
    }
    $summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryTemporaryPath -Encoding UTF8
    $null = Get-Content -LiteralPath $summaryTemporaryPath -Raw | ConvertFrom-Json
    Move-Item -LiteralPath $summaryTemporaryPath -Destination $summaryPath -Force

    $validatorPath = Join-Path $PSScriptRoot 'Test-CertaFileManifest.ps1'
    if (-not (Test-Path -LiteralPath $validatorPath)) { throw "Manifest validator was not found: $validatorPath" }
    $validation = & $validatorPath -SourcePath $resolvedSource -ManifestPath $resolvedOutput -SummaryPath $summaryPath
    $summary['status'] = 'PASS'
    $summary['validation'] = $validation
    $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryTemporaryPath -Encoding UTF8
    $null = Get-Content -LiteralPath $summaryTemporaryPath -Raw | ConvertFrom-Json
    Move-Item -LiteralPath $summaryTemporaryPath -Destination $summaryPath -Force
}
finally {
    foreach ($temporaryPath in @($csvTemporaryPath,$summaryTemporaryPath)) {
        if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
    }
}

[pscustomobject]$summary
