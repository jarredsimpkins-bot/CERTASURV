$ErrorActionPreference = 'Stop'

function Resolve-CertaControlRoot {
    $scriptRepoRoot = Split-Path -Path $PSScriptRoot -Parent
    if ($scriptRepoRoot -and (Test-Path -LiteralPath (Join-Path $scriptRepoRoot 'scripts\Manage-CertaLaptopLoad.ps1'))) {
        return $scriptRepoRoot
    }

    $fallbackRoots = @(
        'C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH',
        'C:\Users\SimpS\OneDrive\Documents\CERTASURV'
    )

    foreach ($candidate in $fallbackRoots) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'scripts\Manage-CertaLaptopLoad.ps1')) {
            return $candidate
        }
    }

    throw 'Unable to resolve the CERTA control repo root.'
}

$root = Resolve-CertaControlRoot
$loadScript = Join-Path $root 'scripts\Manage-CertaLaptopLoad.ps1'
$cloudScript = Join-Path $root 'scripts\Invoke-CertaCloudOffload.ps1'

$loadAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$loadScript`" -Mode Auto -Quiet"
$loadTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1)
$loadSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew -Priority 5
Register-ScheduledTask -TaskName 'CERTA Laptop Load Manager' -Action $loadAction -Trigger $loadTrigger -Settings $loadSettings -Description 'Adaptive production: boosts local work when free, protects TBC and parks background load when TBC is active.' -Force | Out-Null

$cloudAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$cloudScript`" -Quiet"
$cloudTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) -RepetitionInterval (New-TimeSpan -Minutes 5)
$cloudSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -MultipleInstances IgnoreNew -Priority 7
Register-ScheduledTask -TaskName 'CERTA Cloud Offload Runner' -Action $cloudAction -Trigger $cloudTrigger -Settings $cloudSettings -Description 'Pushes committed branches to GitHub when auth/remotes are available so cloud checks can run.' -Force | Out-Null

Write-Host 'OK: adaptive production and cloud offload tasks are enabled.'
