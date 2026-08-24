param(
    [string]$Owner = 'jarredsimpkins-bot',
    [switch]$Apply,
    [switch]$UseSsh
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'CertaRepoPaths.ps1')
$paths = Get-CertaRepositoryPaths
$repos = @(
    @{ Name = 'CERTAHEALTH'; Path = $paths.Control; Slug = 'CERTASURV' },
    @{ Name = 'CERTARD'; Path = $paths.Certard; Slug = 'certard' },
    @{ Name = 'MACROTBC'; Path = $paths.MacroTbc; Slug = 'macrotbc' },
    @{ Name = 'AUTOMATIONS'; Path = $paths.Automations; Slug = 'certasurv-automations' },
    @{ Name = 'CERTASURV_WEB_APP'; Path = $paths.WebApp; Slug = 'certasurv-web-app' }
)

$rows = foreach ($repo in $repos) {
    if (-not (Test-Path (Join-Path $repo.Path '.git'))) {
        [pscustomobject]@{
            Repo = $repo.Name
            Path = $repo.Path
            Remote = ''
            Status = 'missing-local-git'
        }
        continue
    }

    $remoteUrl = if ($UseSsh) {
        "git@github.com:$Owner/$($repo.Slug).git"
    }
    else {
        "https://github.com/$Owner/$($repo.Slug).git"
    }

    $current = ''
    $remotes = git -C $repo.Path remote
    if ($remotes -contains 'origin') {
        $current = git -C $repo.Path remote get-url origin
    }
    if ($Apply) {
        if ($current) {
            git -C $repo.Path remote set-url origin $remoteUrl
            $status = 'updated-origin'
        }
        else {
            git -C $repo.Path remote add origin $remoteUrl
            $status = 'added-origin'
        }
    }
    else {
        $status = if ($current) { 'would-update-origin' } else { 'would-add-origin' }
    }

    [pscustomobject]@{
        Repo = $repo.Name
        Path = $repo.Path
        Remote = $remoteUrl
        Status = $status
    }
}

$rows | Format-Table -AutoSize -Wrap

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Dry run only. Re-run with -Apply after the GitHub repositories exist.'
}
