param(
    [switch]$Detailed
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
$projects = @(
    @{ Name = 'CERTAHEALTH'; Path = Join-Path $documents 'CERTAHEALTH'; Type = 'control'; RequiresGit = $true },
    @{ Name = 'CERTARD'; Path = Join-Path $documents 'CERTARD'; Type = 'coordination'; RequiresGit = $true },
    @{ Name = 'MACROTBC'; Path = Join-Path $documents 'MACROTBC'; Type = 'tbc-integration'; RequiresGit = $true },
    @{ Name = 'AUTOMATIONS'; Path = Join-Path $documents 'AUTOMATIONS'; Type = 'automation'; RequiresGit = $true },
    @{ Name = 'CERTASURV_WEB_APP'; Path = $webAppPath; Type = 'local-app'; RequiresGit = $true },
    @{ Name = 'TBC Live Macros'; Path = Join-Path $documents 'Trimble Business Center\MacroCommands3\CertaSurv'; Type = 'tbc-live'; RequiresGit = $false },
    @{ Name = 'Feature Definition Manager'; Path = Join-Path $documents 'Feature Definition Manager'; Type = 'cad-standards'; RequiresGit = $false },
    @{ Name = 'TBC Templates Matrix'; Path = 'C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE'; Type = 'tbc-templates'; RequiresGit = $false }
)

$connections = @(
    @{ Name = 'Shared Drive Mount'; Path = 'G:\Shared drives\CERTASURV_PROJECT DRIVE'; Lane = 'outside-drive' },
    @{ Name = 'Command Center Root'; Path = 'G:\Shared drives\CERTASURV_PROJECT DRIVE\00_CERTASURV_COMMAND_CENTER'; Lane = 'outside-drive' },
    @{ Name = 'Shared Drive Projects'; Path = 'G:\Shared drives\CERTASURV_PROJECT DRIVE\00_CERTASURV_COMMAND_CENTER\01_PROJECTS'; Lane = 'outside-drive' },
    @{ Name = 'CERTARD Drive Mount Helper'; Path = Join-Path $documents 'CERTARD\scripts\Ensure-CertaSurvDriveMount.ps1'; Lane = 'outside-drive-helper' },
    @{ Name = 'CERTARD Drive Stage Helper'; Path = Join-Path $documents 'CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1'; Lane = 'outside-drive-helper' },
    @{ Name = 'MACROTBC Command Manifest'; Path = Join-Path $documents 'MACROTBC\command_center\command_center_manifest.json'; Lane = 'outside-appsheet-drive' },
    @{ Name = 'MACROTBC Shared Drive Config'; Path = Join-Path $documents 'MACROTBC\certasurv_shared_drive.json'; Lane = 'outside-drive-config' },
    @{ Name = 'AUTOMATIONS Apps Script'; Path = Join-Path $documents 'AUTOMATIONS\share-drive-automation\apps-script\Code.gs'; Lane = 'outside-automation' },
    @{ Name = 'AUTOMATIONS Deploy Notes'; Path = Join-Path $documents 'AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md'; Lane = 'outside-automation' },
    @{ Name = 'TBC Live Macros'; Path = Join-Path $documents 'Trimble Business Center\MacroCommands3\CertaSurv'; Lane = 'in-house-tbc' },
    @{ Name = 'TBC Templates Matrix'; Path = 'C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE'; Lane = 'in-house-tbc' },
    @{ Name = 'Feature Definition Manager'; Path = Join-Path $documents 'Feature Definition Manager'; Lane = 'in-house-cad' }
)

$toolNames = @('git', 'gh', 'python', 'node', 'npm', 'powershell')
$toolRows = foreach ($tool in $toolNames) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if (-not $cmd -and $tool -eq 'gh' -and (Test-Path 'C:\Program Files\GitHub CLI\gh.exe')) {
        $cmd = Get-Item 'C:\Program Files\GitHub CLI\gh.exe'
    }
    if (-not $cmd -and $tool -eq 'node' -and (Test-Path 'C:\Program Files\nodejs\node.exe')) {
        $cmd = Get-Item 'C:\Program Files\nodejs\node.exe'
    }
    if (-not $cmd -and $tool -eq 'npm' -and (Test-Path 'C:\Program Files\nodejs\npm.cmd')) {
        $cmd = Get-Item 'C:\Program Files\nodejs\npm.cmd'
    }
    [pscustomobject]@{
        Area = 'Tool'
        Name = $tool
        Status = if ($cmd) { 'OK' } else { 'MISSING' }
        Detail = if ($cmd.Source) { $cmd.Source } elseif ($cmd.FullName) { $cmd.FullName } else { 'Not on PATH' }
    }
}

$connectionRows = foreach ($connection in $connections) {
    [pscustomobject]@{
        Area = 'Connection'
        Name = $connection.Name
        Status = if (Test-Path -LiteralPath $connection.Path) { 'OK' } else { 'MISSING' }
        Detail = $connection.Path
    }
}

$projectRows = foreach ($project in $projects) {
    $exists = Test-Path -LiteralPath $project.Path
    $hasGit = $false
    $hasRemote = $false
    $remoteUrl = ''

    if ($exists -and $project.RequiresGit) {
        $insideWorkTree = git -C $project.Path rev-parse --is-inside-work-tree 2>$null
        $hasGit = $LASTEXITCODE -eq 0 -and $insideWorkTree -eq 'true'
        if ($hasGit) {
            $remoteUrl = git -C $project.Path remote get-url origin 2>$null
            $hasRemote = $LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($remoteUrl)
        }
    }

    [pscustomobject]@{
        Area = 'Project'
        Name = $project.Name
        Status = if (-not $exists) { 'MISSING' } elseif ($project.RequiresGit -and -not $hasGit) { 'NO_GIT' } elseif ($project.RequiresGit -and -not $hasRemote) { 'LOCAL_ONLY' } else { 'OK' }
        Detail = if ($project.RequiresGit) { "git remote: $hasRemote; $remoteUrl; $($project.Path)" } else { $project.Path }
    }
}

$allRows = @($toolRows) + @($connectionRows) + @($projectRows)
$allRows | Sort-Object Area,Name | Format-Table -AutoSize -Wrap

$missing = $allRows | Where-Object { $_.Status -ne 'OK' }
if ($missing) {
    Write-Host ''
    Write-Host 'Provisioning gaps to fix:'
    $missing | Sort-Object Area,Name | Format-Table -AutoSize -Wrap
    exit 1
}

if ($Detailed) {
    Write-Host ''
    Write-Host 'All checked project tools and connections are provisioned.'
}

exit 0
