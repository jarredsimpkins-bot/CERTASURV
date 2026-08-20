#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ })]
    [string]$SourcePath,

    [Parameter(Mandatory)]
    [string]$OutputPath,

    [ValidateRange(0, 1048576)]
    [int]$HashFileLimitMiB = 256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedSource = (Resolve-Path -LiteralPath $SourcePath).Path
$outputParent = Split-Path -Parent $OutputPath
if ($outputParent -and -not (Test-Path -LiteralPath $outputParent)) {
    New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
}

$limitBytes = [int64]$HashFileLimitMiB * 1MB
$rows = New-Object System.Collections.Generic.List[object]
$files = @(Get-ChildItem -LiteralPath $resolvedSource -File -Recurse -Force -ErrorAction Stop)

foreach ($file in $files) {
    $relative = $file.FullName.Substring($resolvedSource.Length).TrimStart('\')
    $hash = $null
    $hashStatus = 'SKIPPED_SIZE'
    if ($file.Length -le $limitBytes) {
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        $hashStatus = 'HASHED'
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

$rows | Sort-Object relative_path | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8

$summary = [ordered]@{
    schema_version = 1
    created_at = (Get-Date).ToUniversalTime().ToString('o')
    source_path = $resolvedSource
    output_path = $OutputPath
    file_count = $rows.Count
    total_bytes = [int64](($rows | Measure-Object -Property size_bytes -Sum).Sum)
    hashed_count = @($rows | Where-Object hash_status -eq 'HASHED').Count
    skipped_hash_count = @($rows | Where-Object hash_status -ne 'HASHED').Count
    status = 'PASS'
}
$summaryPath = [IO.Path]::ChangeExtension($OutputPath, '.summary.json')
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

[pscustomobject]$summary
