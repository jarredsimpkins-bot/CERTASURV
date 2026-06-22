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

$repos = @(
    @{
        Name = 'certard'
        Description = 'CERTARD project watcher and coordination companion.'
        Path = 'C:\Users\SimpS\OneDrive\Documents\CERTARD'
        Branch = 'main'
    },
    @{
        Name = 'macrotbc'
        Description = 'CertaSurv TBC macro, command center, and local production integration.'
        Path = 'C:\Users\SimpS\OneDrive\Documents\MACROTBC'
        Branch = 'codex/certasurv-command-center'
    },
    @{
        Name = 'certasurv-automations'
        Description = 'CertaSurv Google Drive, Apps Script, and operations automation package.'
        Path = 'C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS'
        Branch = 'codex/onboard-everything'
    },
    @{
        Name = 'certasurv-web-app'
        Description = 'CertaSurv land opportunity radar, parcel, estimate, and dashboard app.'
        Path = $webAppPath
        Branch = 'codex/land-opportunity-radar-mvp'
    },
    @{
        Name = 'WV_COURTHOUSE_RESEARCHER'
        Description = 'WV courthouse research package is local-only until remote destination is approved.'
        Path = 'C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER'
        Branch = ''
        LocalOnly = $true
    }
)

$results = foreach ($repo in $repos) {
    if ($repo.LocalOnly) {
        [pscustomobject]@{
            Repo = $repo.Name
            Created = $false
            Branch = 'local-only'
            Pushed = $false
            Url = 'remote-blocked'
        }
        continue
    }

    git -C $repo.Path rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        [pscustomobject]@{
            Repo = $repo.Name
            Created = $false
            Branch = $repo.Branch
            Pushed = $false
            Url = 'missing-local-git'
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

    $remote = "https://github.com/$fullName.git"
    $remotes = git -C $repo.Path remote

    if ($remotes -contains 'origin') {
        git -C $repo.Path remote set-url origin $remote
    }
    else {
        git -C $repo.Path remote add origin $remote
    }

    git -C $repo.Path push -u origin $repo.Branch
    $pushOk = ($LASTEXITCODE -eq 0)

    [pscustomobject]@{
        Repo = $fullName
        Created = $created
        Branch = $repo.Branch
        Pushed = $pushOk
        Url = "https://github.com/$fullName"
    }
}

$results | Format-Table -AutoSize
