#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CertaPropertyValue {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties | Where-Object {
        $_.Name.Equals($Name, [StringComparison]::OrdinalIgnoreCase)
    } | Select-Object -First 1
    if ($property) { return $property.Value }
    return $null
}

function Expand-CertaCommandItems {
    param([AllowNull()]$Value)

    $result = New-Object System.Collections.Generic.List[object]
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) {
        foreach ($item in $Value) {
            foreach ($expanded in @(Expand-CertaCommandItems -Value $item)) {
                $result.Add($expanded)
            }
        }
    }
    else {
        $result.Add($Value)
    }
    return @($result)
}

$commandsPath = Join-Path $env:USERPROFILE '.TRIGGERcmdData\commands.json'
if (-not (Test-Path -LiteralPath $commandsPath)) {
    throw "TRIGGERcmd commands file not found: $commandsPath. Open the foreground agent under this Windows profile, then rerun."
}

$requiredScripts = @(
    'ROUTER\Get-CertaServerHealth.ps1',
    'ROUTER\Get-CertaQueueStatus.ps1',
    'ROUTER\Invoke-CertaQueueWorker.ps1',
    'ROUTER\Start-CertaQueueWorker.ps1',
    'ROUTER\Stop-CertaQueueWorker.ps1',
    'CONTROL\tests\Test-CertaProductionCapabilities.ps1'
)
foreach ($relative in $requiredScripts) {
    $path = Join-Path $ServerRoot $relative
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required server command target is missing: $path"
    }
}

$baseInstaller = Join-Path $ServerRoot 'CONTROL\Install-CertaServer-TriggerCommands.ps1'
$baseResult = $null
if (Test-Path -LiteralPath $baseInstaller) {
    $baseResult = & $baseInstaller -ServerRoot $ServerRoot
}

$backupDir = Join-Path $ServerRoot 'CONTROL\backups\triggercmd'
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$suffix = '{0:yyyyMMdd-HHmmssfff}-{1}' -f (Get-Date), ([guid]::NewGuid().ToString('N').Substring(0,8))
$backupPath = Join-Path $backupDir "commands-production-$suffix.json"
$invalidPath = Join-Path $backupDir "invalid-production-command-entries-$suffix.json"
Copy-Item -LiteralPath $commandsPath -Destination $backupPath -Force

$raw = Get-Content -LiteralPath $commandsPath -Raw
$parsed = $null
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    try { $parsed = $raw | ConvertFrom-Json }
    catch { throw "TRIGGERcmd commands file is invalid JSON. Backup: $backupPath. $($_.Exception.Message)" }
}

$valid = New-Object System.Collections.Generic.List[object]
$invalid = New-Object System.Collections.Generic.List[object]
foreach ($candidate in @(Expand-CertaCommandItems -Value $parsed)) {
    $trigger = [string](Get-CertaPropertyValue -Object $candidate -Name 'trigger')
    $command = [string](Get-CertaPropertyValue -Object $candidate -Name 'command')
    if (-not [string]::IsNullOrWhiteSpace($trigger) -and -not [string]::IsNullOrWhiteSpace($command)) {
        $valid.Add($candidate)
    }
    else {
        $invalid.Add($candidate)
    }
}
if ($invalid.Count -gt 0) {
    @($invalid) | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $invalidPath -Encoding UTF8
}

$definitions = @(
    [pscustomobject]@{
        trigger='Certa Server Health'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $ServerRoot 'ROUTER\Get-CertaServerHealth.ps1'))
        offCommand=''
        ground='foreground'
        voice='certa server health'
        voiceReply=''
        allowParams='false'
    },
    [pscustomobject]@{
        trigger='Certa Server Queue Status'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $ServerRoot 'ROUTER\Get-CertaQueueStatus.ps1'))
        offCommand=''
        ground='foreground'
        voice='certa server queue status'
        voiceReply=''
        allowParams='false'
    },
    [pscustomobject]@{
        trigger='Certa Server Process Queue'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $ServerRoot 'ROUTER\Invoke-CertaQueueWorker.ps1'))
        offCommand=''
        ground='foreground'
        voice='certa server process queue'
        voiceReply=''
        allowParams='false'
    },
    [pscustomobject]@{
        trigger='Certa Server Start Worker'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $ServerRoot 'ROUTER\Start-CertaQueueWorker.ps1'))
        offCommand=''
        ground='foreground'
        voice='certa server start worker'
        voiceReply=''
        allowParams='false'
    },
    [pscustomobject]@{
        trigger='Certa Server Stop Worker'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $ServerRoot 'ROUTER\Stop-CertaQueueWorker.ps1'))
        offCommand=''
        ground='foreground'
        voice='certa server stop worker'
        voiceReply=''
        allowParams='false'
    },
    [pscustomobject]@{
        trigger='Certa Server Production Test'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -SourceRoot "{1}"' -f (Join-Path $ServerRoot 'CONTROL\tests\Test-CertaProductionCapabilities.ps1'), (Join-Path $ServerRoot 'SCRIPTS'))
        offCommand=''
        ground='foreground'
        voice='certa server production test'
        voiceReply=''
        allowParams='false'
    },
    [pscustomobject]@{
        trigger='Certa Server Open'
        command=('explorer.exe "{0}"' -f $ServerRoot)
        offCommand=''
        ground='foreground'
        voice='open certa server'
        voiceReply=''
        allowParams='false'
    }
)

$names = @($definitions | ForEach-Object { [string]$_.trigger })
$items = @($valid | Where-Object {
    $name = [string](Get-CertaPropertyValue -Object $_ -Name 'trigger')
    $names -notcontains $name
}) + $definitions

$temporaryPath = Join-Path (Split-Path -Parent $commandsPath) ('.commands.production.{0}.tmp' -f [guid]::NewGuid().ToString('N'))
$agent = Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue | Select-Object -First 1
$agentPath = $null
if ($agent) { try { $agentPath = $agent.Path } catch {} }
$agentRestarted = $false
try {
    if ($agent -and $agentPath -and (Test-Path -LiteralPath $agentPath)) {
        Stop-Process -Id $agent.Id -Force
        Start-Sleep -Seconds 1
    }

    @($items) | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
    $validated = @(Expand-CertaCommandItems -Value (Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json))
    foreach ($definition in $definitions) {
        $matches = @($validated | Where-Object {
            [string](Get-CertaPropertyValue -Object $_ -Name 'trigger') -eq [string]$definition.trigger
        })
        if ($matches.Count -ne 1) { throw "Trigger validation failed for '$($definition.trigger)'." }
        if ([string](Get-CertaPropertyValue -Object $matches[0] -Name 'allowParams') -ne 'false') {
            throw "Trigger command unexpectedly allows parameters: $($definition.trigger)"
        }
    }
    Move-Item -LiteralPath $temporaryPath -Destination $commandsPath -Force
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
    if ($agentPath -and (Test-Path -LiteralPath $agentPath)) {
        Start-Process -FilePath $agentPath
        Start-Sleep -Seconds 3
        $agentRestarted = [bool](Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue)
    }
}

[pscustomobject]@{
    status='PASS'
    commands_path=$commandsPath
    backup_path=$backupPath
    invalid_entries_backup=if ($invalid.Count -gt 0) { $invalidPath } else { $null }
    invalid_entries_removed=$invalid.Count
    installed=$names
    base_installer_result=$baseResult
    agent_restarted=$agentRestarted
    note='Production server commands were normalized and registered atomically with parameters disabled.'
}
