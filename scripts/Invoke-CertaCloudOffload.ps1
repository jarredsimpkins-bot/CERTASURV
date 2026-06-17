param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'

function Resolve-PreferredPath {
    param(
        [string]$Primary,
        [string]$Fallback
    )

    if (Test-Path -LiteralPath $Primary) {
        return $Primary
    }

    return $Fallback
}

$documents = 'C:\Users\SimpS\OneDrive\Documents'
$coordinationPath = Resolve-PreferredPath -Primary (Join-Path $documents 'WV_COURTHOUSE_RESEARCHER') -Fallback (Join-Path $documents 'CERTARD')
$webAppPath = Resolve-PreferredPath -Primary (Join-Path $documents 'CERTASURV_WEB_APP') -Fallback (Join-Path $documents 'New project2')
$repos = @(
    @{ Name = 'CERTAHEALTH'; Path = Join-Path $documents 'CERTAHEALTH' },
    @{ Name = 'WV_COURTHOUSE_RESEARCHER'; Path = $coordinationPath },
    @{ Name = 'MACROTBC'; Path = Join-Path $documents 'MACROTBC' },
    @{ Name = 'AUTOMATIONS'; Path = Join-Path $documents 'AUTOMATIONS' },
    @{ Name = 'CERTASURV_WEB_APP'; Path = $webAppPath }
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

    if (-not $branch) {
        [pscustomobject]@{
            Repo = $repo.Name
            Status = 'detached-head'
            Branch = ''
            Remote = $remote
            Detail = 'Skipped push because this worktree is detached; checkout a named branch before cloud push.'
        }
        continue
    }

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
