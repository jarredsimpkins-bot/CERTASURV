# TEMPORARY OWNER-PRESENT MSI BOOTSTRAP — restore after one verified run.
# Fetches one immutable hash-bound package from an exact Git commit.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($env:COMPUTERNAME -ine 'MSI') { throw "Refusing: bootstrap is MSI-only, current host is $env:COMPUTERNAME." }
if (-not (Test-Path -LiteralPath 'D:\')) { throw 'Refusing: D: is not mounted.' }

$Commit = '24af869599b8dc143148c1ddd66ecba0f14be4e9'
$PackageSha256 = '6271631d3c289a4a1c5ae3a23680277d18de3f59b9daf54abacb5820d47acd30'
$InstallerSha256 = '341184e19d9fa1f5064f0f1bce037006e02bfeee49183ebde2a82cfd108f3788'
$Url = "https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/$Commit/bootstrap/certard-msi-r2/CertaRD_TriggerControl_OpenClaw_MSI_20260916_R2.zip"
$StageRoot = 'D:\CERTARD\staging\bootstrap\MSI_TRIGGERCONTROL_OPENCLAW_20260916_R2'
$ZipPath = 'D:\CERTARD\staging\bootstrap\CertaRD_TriggerControl_OpenClaw_MSI_20260916_R2.zip'

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ZipPath) | Out-Null
Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $ZipPath
$actualZip = (Get-FileHash -Algorithm SHA256 -LiteralPath $ZipPath).Hash.ToLowerInvariant()
if ($actualZip -ne $PackageSha256) { throw "R2 ZIP SHA256 mismatch: $actualZip" }

if (Test-Path -LiteralPath $StageRoot) { Remove-Item -LiteralPath $StageRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $StageRoot | Out-Null
Expand-Archive -LiteralPath $ZipPath -DestinationPath $StageRoot -Force
$installer = Join-Path $StageRoot 'certard_msi_bootstrap\Apply-Bootstrap-MSI.ps1'
if (-not (Test-Path -LiteralPath $installer)) { throw "Bootstrap installer missing: $installer" }
$actualInstaller = (Get-FileHash -Algorithm SHA256 -LiteralPath $installer).Hash.ToLowerInvariant()
if ($actualInstaller -ne $InstallerSha256) { throw "Installer SHA256 mismatch: $actualInstaller" }

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer
$code = $LASTEXITCODE
if ($null -eq $code) { $code = 0 }
if ($code -ne 0) { throw "R2 bootstrap installer failed with exit code $code." }
Write-Output 'CERTARD_MSI_TRIGGER_BOOTSTRAP_R2_COMPLETED'
