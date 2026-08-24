param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'

. (Join-Path $PSScriptRoot 'CertaRepoPaths.ps1')
$paths = Get-CertaRepositoryPaths
$repos = @(
    @{ Name = 'CERTAHEALTH'; Path = $paths.Control },
    @{ Name = 'CERTARD'; Path = $paths.Certard },
    @{ Name = 'MACROTBC'; Path = $paths.MacroTbc },
    @{ Name = 'AUTOMATIONS'; Path = $paths.Automations },
    @{ Name = 'CERTASURV_WEB_APP'; Path = $paths.WebApp }
)

$rows = foreach ($repo in $repos) {
    $gitDir = Join-Path $repo.Path '.git'
    if (-not (Test-Path -LiteralPath $gitDir)) {
        [pscustomobject]@{ Repo = $repo.Name; Status = 'missing-git'; Branch = ''; Remote = ''; Detail = $repo.Path }
        continue
    }

    $branch = git -C $repo.Path branch --show-current
    $remote = git -C $repo.Path remote get-url origin 2>$null
    $dirty = git -C $repo.Path status --porcelain

    if (-not $remote) {
        [pscustomobject]@{ Repo = $repo.Name; Status = 'no-remote'; Branch = $branch; Remote = ''; Detail = 'Run Set-CertaGitRemotes.ps1 -Apply after repositories exist' }
        continue
    }

    git -C $repo.Path push -u origin $branch
    $pushOk = ($LASTEXITCODE -eq 0)
    [pscustomobject]@{
        Repo = $repo.Name
        Status = if ($pushOk) { 'pushed' } else { 'push-failed' }
        Branch = $branch
        Remote = $remote
        Detail = if ($dirty) { 'local uncommitted changes preserved; pushed committed branch only' } else { 'clean branch pushed' }
    }
}

if (-not $Quiet) {
    [pscustomobject]@{
        GitPushMode = 'credential-manager'
        Timestamp = Get-Date
    } | Format-List

    $rows | Format-Table -AutoSize -Wrap
}

if ($rows.Status -contains 'push-failed') {
    exit 1
}

exit 0
