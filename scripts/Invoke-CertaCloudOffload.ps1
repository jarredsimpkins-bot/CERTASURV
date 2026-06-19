param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'

$documents = 'C:\Users\SimpS\OneDrive\Documents'
$webAppCandidates = @(
    Join-Path $documents 'CERTASURV_WEB_APP'
    Join-Path $documents 'New project2'
)
$webAppPath = $webAppCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $webAppPath) {
    $webAppPath = $webAppCandidates[0]
}
$repos = @(
    @{ Name = 'CERTAHEALTH'; Path = Join-Path $documents 'CERTAHEALTH' },
    @{ Name = 'CERTARD'; Path = Join-Path $documents 'CERTARD' },
    @{ Name = 'MACROTBC'; Path = Join-Path $documents 'MACROTBC' },
    @{ Name = 'AUTOMATIONS'; Path = Join-Path $documents 'AUTOMATIONS' },
    @{ Name = 'CERTASURV_WEB_APP'; Path = $webAppPath },
    @{ Name = 'WV_COURTHOUSE_RESEARCHER'; Path = Join-Path $documents 'WV_COURTHOUSE_RESEARCHER' }
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
        [pscustomobject]@{ Repo = $repo.Name; Status = 'no-branch'; Branch = ''; Remote = $remote; Detail = 'Create or check out a branch before cloud offload' }
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
