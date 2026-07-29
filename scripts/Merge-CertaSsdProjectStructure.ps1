[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ProjectRoot,

    [string] $ManifestPath = (
        Join-Path $PSScriptRoot '..\templates\ssd-post-workshop\structure.txt'
    )
)

$resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$resolvedManifestPath = [System.IO.Path]::GetFullPath($ManifestPath)

if (-not (Test-Path -LiteralPath $resolvedProjectRoot -PathType Container)) {
    throw "Project root does not exist: $resolvedProjectRoot"
}

if (-not (Test-Path -LiteralPath $resolvedManifestPath -PathType Leaf)) {
    throw "Structure manifest does not exist: $resolvedManifestPath"
}

$created = [System.Collections.Generic.List[string]]::new()
$existing = [System.Collections.Generic.List[string]]::new()

foreach ($relativePath in Get-Content -LiteralPath $resolvedManifestPath) {
    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        continue
    }

    $nativeRelativePath = $relativePath.Replace(
        '/',
        [System.IO.Path]::DirectorySeparatorChar
    )
    $targetPath = [System.IO.Path]::GetFullPath(
        (Join-Path $resolvedProjectRoot $nativeRelativePath)
    )

    if (-not $targetPath.StartsWith(
        $resolvedProjectRoot + [System.IO.Path]::DirectorySeparatorChar,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Manifest path escapes the project root: $relativePath"
    }

    if (Test-Path -LiteralPath $targetPath -PathType Container) {
        $existing.Add($targetPath)
        continue
    }

    if ($PSCmdlet.ShouldProcess($targetPath, 'Create directory')) {
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        $created.Add($targetPath)
    }
}

[pscustomobject]@{
    ProjectRoot = $resolvedProjectRoot
    Manifest = $resolvedManifestPath
    CreatedCount = $created.Count
    ExistingCount = $existing.Count
    Created = $created
}
