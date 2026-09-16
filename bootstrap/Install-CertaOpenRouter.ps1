# TEMPORARY OWNER-PRESENT MSI BOOTSTRAP — restore after one verified run.
# This intentionally performs only the hash-bound CertaRD TriggerControl bootstrap.
# It does not install OpenRouter and it does not install OpenClaw.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$ExpectedRequestId = 'MSI_TRIGGERCONTROL_OPENCLAW_20260916_R2'
$ExpectedPackageName = 'CertaRD_TriggerControl_OpenClaw_MSI_20260916_R2.zip'
$ExpectedPackageSha256 = '6271631d3c289a4a1c5ae3a23680277d18de3f59b9daf54abacb5820d47acd30'
$ExpectedInstallerRel = 'certard_msi_bootstrap\Apply-Bootstrap-MSI.ps1'
$ExpectedInstallerSha256 = '341184e19d9fa1f5064f0f1bce037006e02bfeee49183ebde2a82cfd108f3788'
$RequestName = 'CertaRD_TriggerControl_OpenClaw_MSI_20260916_R2.request.json'

if ($env:COMPUTERNAME -ine 'MSI') { throw "Refusing: bootstrap is authorized only for MSI, not $env:COMPUTERNAME." }
if (-not (Test-Path -LiteralPath 'D:\')) { throw 'Refusing: D: removable/work drive is not mounted.' }

$candidates = @()
foreach ($drive in @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
    foreach ($meshRoot in @(
        (Join-Path $drive.Root 'Shared drives\CERTASURV_PROJECT DRIVE\CERTARD_MESH'),
        (Join-Path $drive.Root 'CERTASURV_PROJECT DRIVE\CERTARD_MESH')
    )) {
        $req = Join-Path $meshRoot ('overlay\requests\' + $RequestName)
        $pkg = Join-Path $meshRoot ('releases\' + $ExpectedPackageName)
        if ((Test-Path -LiteralPath $req) -and (Test-Path -LiteralPath $pkg)) {
            $candidates += [pscustomobject]@{ Request=$req; Package=$pkg; Root=$meshRoot }
        }
    }
}
$candidates = @($candidates | Sort-Object Root -Unique)
if ($candidates.Count -ne 1) { throw "Expected exactly one synchronized canonical CERTARD_MESH containing R2; found $($candidates.Count)." }
$selected = $candidates[0]

$request = Get-Content -Raw -LiteralPath $selected.Request | ConvertFrom-Json
if ([string]$request.request_id -ne $ExpectedRequestId) { throw 'Request ID mismatch.' }
if ([string]$request.target_node -ine 'MSI' -and [string]$request.target_host -ine 'MSI') { throw 'Request target mismatch.' }
if ([string]$request.request_status -notin @('OWNER_PRESENT_AUTHORIZED','REVIEWED_AUTHORIZED')) { throw 'Request is not authorized.' }
if (-not [bool]$request.authorization.direct_shell) { throw 'Request does not authorize direct shell.' }
if ([DateTimeOffset]::UtcNow -gt [DateTimeOffset]::Parse([string]$request.expires_at_utc)) { throw 'Request expired.' }
if ([string]$request.package.name -ne $ExpectedPackageName) { throw 'Package name mismatch.' }
if ([string]$request.package.sha256 -ine $ExpectedPackageSha256) { throw 'Request package hash mismatch.' }
if ([string]$request.installer.relpath -ne $ExpectedInstallerRel) { throw 'Installer path mismatch.' }
if ([string]$request.installer.sha256 -ine $ExpectedInstallerSha256) { throw 'Request installer hash mismatch.' }

$actualPackageHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $selected.Package).Hash.ToLowerInvariant()
if ($actualPackageHash -ne $ExpectedPackageSha256) { throw "ZIP SHA256 mismatch: $actualPackageHash" }

$stage = 'D:\CERTARD\staging\bootstrap\MSI_TRIGGERCONTROL_OPENCLAW_20260916_R2'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null
Expand-Archive -LiteralPath $selected.Package -DestinationPath $stage -Force
$installer = Join-Path $stage $ExpectedInstallerRel
if (-not (Test-Path -LiteralPath $installer)) { throw "Installer missing after extraction: $installer" }
$actualInstallerHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $installer).Hash.ToLowerInvariant()
if ($actualInstallerHash -ne $ExpectedInstallerSha256) { throw "Installer SHA256 mismatch: $actualInstallerHash" }

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer
$code = $LASTEXITCODE
if ($null -eq $code) { $code = 0 }
if ($code -ne 0) { throw "R2 bootstrap installer failed with exit code $code." }

Write-Output 'CERTARD_MSI_TRIGGER_BOOTSTRAP_R2_COMPLETED'
