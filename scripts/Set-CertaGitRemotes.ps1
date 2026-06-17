param(
    [string]$Owner = 'jarredsimpkins-bot',
    [switch]$Apply,
    [switch]$UseSsh
)

$ErrorActionPreference = 'Stop'

$documents = 'C:\Users\SimpS\OneDrive\Documents'
$repos = @(
    @{ Name = 'CERTAHEALTH'; Path = Join-Path $documents 'CERTAHEALTH'; Slug = 'certahealth' },
    @{ Name = 'WV_COURTHOUSE_RESEARCHER'; Path = Join-Path $documents 'WV_COURTHOUSE_RESEARCHER'; Slug = 'wv_courthouse_researcher' },
    @{ Name = 'MACROTBC'; Path = Join-Path $documents 'MACROTBC'; Slug = 'macrotbc' },
    @{ Name = 'AUTOMATIONS'; Path = Join-Path $documents 'AUTOMATIONS'; Slug = 'certasurv-automations' },
    @{ Name = 'CERTASURV_WEB_APP'; Path = Join-Path $documents 'CERTASURV_WEB_APP'; Slug = 'certasurv-web-app' }
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
