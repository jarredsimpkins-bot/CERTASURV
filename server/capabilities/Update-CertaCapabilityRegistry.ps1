#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CertaPropertyValue {
    param(
        [Parameter(Mandatory=$true)]$InputObject,
        [Parameter(Mandatory=$true)][string]$Name
    )

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return '' }
    return [string]$property.Value
}

$registryPath = Join-Path $ServerRoot 'CONTROL\registries\CAPABILITY_REGISTRY.csv'
$registryParent = Split-Path -Parent $registryPath
$backupDirectory = Join-Path $ServerRoot 'CONTROL\backups\capability-registry'
New-Item -ItemType Directory -Path $registryParent -Force | Out-Null
New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null

$backupPath = $null
$existing = @()
if (Test-Path -LiteralPath $registryPath) {
    $backupPath = Join-Path $backupDirectory ('CAPABILITY_REGISTRY-{0:yyyyMMdd-HHmmssfff}-{1}.csv' -f (Get-Date), ([guid]::NewGuid().ToString('N').Substring(0,8)))
    Copy-Item -LiteralPath $registryPath -Destination $backupPath -Force
    $raw = Get-Content -LiteralPath $registryPath -Raw
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
        $existing = @(Import-Csv -LiteralPath $registryPath)
    }
}

$normalized = @()
$droppedRows = 0
foreach ($entry in $existing) {
    $capabilityId = Get-CertaPropertyValue -InputObject $entry -Name 'capability_id'
    if ([string]::IsNullOrWhiteSpace($capabilityId)) {
        $droppedRows++
        continue
    }
    if ($capabilityId -eq 'file-manifest-v1') { continue }

    $normalized += [pscustomobject][ordered]@{
        capability_id = $capabilityId
        name = Get-CertaPropertyValue -InputObject $entry -Name 'name'
        intent_regex = Get-CertaPropertyValue -InputObject $entry -Name 'intent_regex'
        status = Get-CertaPropertyValue -InputObject $entry -Name 'status'
        script_path = Get-CertaPropertyValue -InputObject $entry -Name 'script_path'
        validator_path = Get-CertaPropertyValue -InputObject $entry -Name 'validator_path'
        node = Get-CertaPropertyValue -InputObject $entry -Name 'node'
        authority = Get-CertaPropertyValue -InputObject $entry -Name 'authority'
        notes = Get-CertaPropertyValue -InputObject $entry -Name 'notes'
    }
}

$normalized += [pscustomobject][ordered]@{
    capability_id = 'file-manifest-v1'
    name = 'File manifest with bounded SHA256 hashing'
    intent_regex = '(?i)(checksum|file manifest|inventory files)'
    status = 'VERIFIED'
    script_path = (Join-Path $ServerRoot 'SCRIPTS\New-CertaFileManifest.ps1')
    validator_path = (Join-Path $ServerRoot 'SCRIPTS\Test-CertaFileManifest.ps1')
    node = 'CERTA-SERVER'
    authority = 'DETERMINISTIC'
    notes = 'Read-only bounded scan with atomic output, self-exclusion, SHA256 validation, and CI execution test.'
}

$temporaryPath = Join-Path $registryParent ('.CAPABILITY_REGISTRY.{0}.tmp' -f [guid]::NewGuid().ToString('N'))
try {
    $normalized | Export-Csv -LiteralPath $temporaryPath -NoTypeInformation -Encoding UTF8
    $validated = @(Import-Csv -LiteralPath $temporaryPath)
    $manifestRows = @($validated | Where-Object {
        (Get-CertaPropertyValue -InputObject $_ -Name 'capability_id') -eq 'file-manifest-v1'
    })
    if ($manifestRows.Count -ne 1) {
        throw 'Capability registry validation failed: expected exactly one file-manifest-v1 record.'
    }
    Move-Item -LiteralPath $temporaryPath -Destination $registryPath -Force
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}

[pscustomobject]@{
    status = 'PASS'
    registry_path = $registryPath
    backup_path = $backupPath
    retained_rows = $normalized.Count
    dropped_invalid_rows = $droppedRows
}
