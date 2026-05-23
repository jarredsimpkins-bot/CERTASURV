param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'

$gh = 'C:\Program Files\GitHub CLI\gh.exe'
$documents = 'C:\Users\SimpS\OneDrive\Documents'
$repos = @(
    @{ Name = 'CERTAHEALTH'; Path = Join-Path $documents 'CERTAHEALTH' },
    @{ Name = 'CERTARD'; Path = Join-Path $documents 'CERTARD' },
    @{ Name = 'MACROTBC'; Path = Join-Path $documents 'MACROTBC' },
    @{ Name = 'AUTOMATIONS'; Path = Join-Path $documents 'AUTOMATIONS' },
    @{ Name = 'New project2'; Path = Join-Path $documents 'New project2' }
)

function Get-GhReady {
    if (-not (Test-Path -LiteralPath $gh -PathType Leaf)) {
        return $false
    }

    & $gh auth status *> $null
    return ($LASTEXITCODE -eq 0)
}

$ghReady = Get-GhReady
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

    if (-not $ghReady) {
        [pscustomobject]@{ Repo = $repo.Name; Status = 'waiting-gh-auth'; Branch = $branch; Remote = $remote; Detail = 'gh auth status is not logged in' }
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
        GitHubCliReady = $ghReady
        Timestamp = Get-Date
    } | Format-List

    $rows | Format-Table -AutoSize -Wrap
}

if ($rows.Status -contains 'push-failed') {
    exit 1
}

exit 0
