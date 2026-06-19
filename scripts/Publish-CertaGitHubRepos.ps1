$ErrorActionPreference = 'Stop'

function Get-GitHubCredentialToken {
    $inputText = "protocol=https`nhost=github.com`n`n"
    $credText = $inputText | git credential fill
    $passwordLine = $credText | Where-Object { $_ -like 'password=*' } | Select-Object -First 1

    if (-not $passwordLine) {
        throw 'No GitHub token returned by Git Credential Manager.'
    }

    return $passwordLine.Substring('password='.Length)
}

$token = Get-GitHubCredentialToken
$headers = @{
    Authorization = "Bearer $token"
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}

$documents = 'C:\Users\SimpS\OneDrive\Documents'
$webAppPath = Join-Path $documents 'CERTASURV_WEB_APP'
$wvResearchPath = Join-Path $documents 'WV_COURTHOUSE_RESEARCHER'

$repos = @(
    @{
        Name = 'certard'
        Description = 'CERTARD project watcher and coordination companion.'
        Path = 'C:\Users\SimpS\OneDrive\Documents\CERTARD'
    },
    @{
        Name = 'macrotbc'
        Description = 'CertaSurv TBC macro, command center, and local production integration.'
        Path = 'C:\Users\SimpS\OneDrive\Documents\MACROTBC'
    },
    @{
        Name = 'certasurv-automations'
        Description = 'CertaSurv Google Drive, Apps Script, and operations automation package.'
        Path = 'C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS'
    },
    @{
        Name = 'certasurv-web-app'
        Description = 'CertaSurv land opportunity radar, parcel, estimate, and dashboard app.'
        Path = $webAppPath
    },
    @{
        Name = 'wv-courthouse-researcher'
        Description = 'CertaSurv courthouse research tooling, runbooks, and operations hub sources.'
        Path = $wvResearchPath
    }
)

$results = foreach ($repo in $repos) {
    if (-not (Test-Path -LiteralPath (Join-Path $repo.Path '.git'))) {
        [pscustomobject]@{
            Repo = "jarredsimpkins-bot/$($repo.Name)"
            Created = $false
            Branch = ''
            Pushed = $false
            Url = ''
            Status = 'missing-git'
        }
        continue
    }

    $fullName = "jarredsimpkins-bot/$($repo.Name)"
    $exists = $false

    try {
        Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$fullName" -Headers $headers | Out-Null
        $exists = $true
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -ne 404) {
            throw
        }
    }

    if (-not $exists) {
        $body = @{
            name = $repo.Name
            description = $repo.Description
            private = $true
            auto_init = $false
        } | ConvertTo-Json

        Invoke-RestMethod -Method Post -Uri 'https://api.github.com/user/repos' -Headers $headers -Body $body -ContentType 'application/json' | Out-Null
        $created = $true
    }
    else {
        $created = $false
    }

    $branch = git -C $repo.Path branch --show-current
    if (-not $branch) {
        [pscustomobject]@{
            Repo = $fullName
            Created = $created
            Branch = ''
            Pushed = $false
            Url = "https://github.com/$fullName"
            Status = 'no-branch'
        }
        continue
    }

    $remote = "https://github.com/$fullName.git"
    $remotes = git -C $repo.Path remote

    if ($remotes -contains 'origin') {
        git -C $repo.Path remote set-url origin $remote
    }
    else {
        git -C $repo.Path remote add origin $remote
    }

    git -C $repo.Path push -u origin $branch
    $pushOk = ($LASTEXITCODE -eq 0)

    [pscustomobject]@{
        Repo = $fullName
        Created = $created
        Branch = $branch
        Pushed = $pushOk
        Url = "https://github.com/$fullName"
        Status = if ($pushOk) { 'pushed' } else { 'push-failed' }
    }
}

$results | Format-Table -AutoSize
