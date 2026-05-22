param(
    [switch]$Detailed
)

$ErrorActionPreference = 'Continue'

$documents = 'C:\Users\SimpS\OneDrive\Documents'
$projects = @(
    @{ Name = 'CERTAHEALTH'; Path = Join-Path $documents 'CERTAHEALTH'; Type = 'control' },
    @{ Name = 'CERTARD'; Path = Join-Path $documents 'CERTARD'; Type = 'coordination' },
    @{ Name = 'MACROTBC'; Path = Join-Path $documents 'MACROTBC'; Type = 'tbc-integration' },
    @{ Name = 'AUTOMATIONS'; Path = Join-Path $documents 'AUTOMATIONS'; Type = 'automation' },
    @{ Name = 'New project2'; Path = Join-Path $documents 'New project2'; Type = 'local-app' },
    @{ Name = 'TBC Live Macros'; Path = Join-Path $documents 'Trimble Business Center\MacroCommands3\CertaSurv'; Type = 'tbc-live' },
    @{ Name = 'Feature Definition Manager'; Path = Join-Path $documents 'Feature Definition Manager'; Type = 'cad-standards' },
    @{ Name = 'TBC Templates Matrix'; Path = 'C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE'; Type = 'tbc-templates' }
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
    $gitPath = Join-Path $project.Path '.git'
    $hasGit = $exists -and (Test-Path -LiteralPath $gitPath)
    $hasRemote = $false

    if ($hasGit) {
        $gitConfig = Join-Path $gitPath 'config'
        if (Test-Path -LiteralPath $gitConfig -PathType Leaf) {
            $hasRemote = Select-String -LiteralPath $gitConfig -Pattern '^\s*\[remote "' -Quiet -ErrorAction SilentlyContinue
        }
    }

    [pscustomobject]@{
        Area = 'Project'
        Name = $project.Name
        Status = if (-not $exists) { 'MISSING' } elseif ($hasGit -and -not $hasRemote) { 'LOCAL_ONLY' } else { 'OK' }
        Detail = if ($hasGit) { "git remote: $hasRemote; $($project.Path)" } else { $project.Path }
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
