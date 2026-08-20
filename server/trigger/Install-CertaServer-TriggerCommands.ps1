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
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
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

$backupDir = Join-Path $ServerRoot 'CONTROL\backups\triggercmd'
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$backupSuffix = '{0:yyyyMMdd-HHmmssfff}-{1}' -f (Get-Date), ([guid]::NewGuid().ToString('N').Substring(0,8))
$backupPath = Join-Path $backupDir "commands-$backupSuffix.json"
$invalidPath = Join-Path $backupDir "invalid-command-entries-$backupSuffix.json"
Copy-Item -LiteralPath $commandsPath -Destination $backupPath -Force

$raw = Get-Content -LiteralPath $commandsPath -Raw
$parsedRoot = $null
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    try {
        $parsedRoot = $raw | ConvertFrom-Json
    }
    catch {
        throw "TRIGGERcmd commands file is not valid JSON. Original was backed up to $backupPath. $($_.Exception.Message)"
    }
}

$validItems = New-Object System.Collections.Generic.List[object]
$invalidItems = New-Object System.Collections.Generic.List[object]
foreach ($candidate in @(Expand-CertaCommandItems -Value $parsedRoot)) {
    $trigger = [string](Get-CertaPropertyValue -Object $candidate -Name 'trigger')
    $command = [string](Get-CertaPropertyValue -Object $candidate -Name 'command')

    if (-not [string]::IsNullOrWhiteSpace($trigger) -and -not [string]::IsNullOrWhiteSpace($command)) {
        $validItems.Add($candidate)
    }
    else {
        $invalidItems.Add($candidate)
    }
}

if ($invalidItems.Count -gt 0) {
    ConvertTo-Json -InputObject @($invalidItems) -Depth 20 |
        Set-Content -LiteralPath $invalidPath -Encoding UTF8
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
        trigger='Certa Server Route Once'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1'))
        offCommand=''
        ground='foreground'
        voice='certa server route once'
        voiceReply=''
        allowParams='false'
    },
    [pscustomobject]@{
        trigger='Certa Server Route All'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -All' -f (Join-Path $ServerRoot 'ROUTER\Invoke-CertaRouter.ps1'))
        offCommand=''
        ground='foreground'
        voice='certa server route all'
        voiceReply=''
        allowParams='false'
    },
    [pscustomobject]@{
        trigger='Certa Ollama Status'
        command=('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $ServerRoot 'ROUTER\Get-CertaServerHealth.ps1'))
        offCommand=''
        ground='foreground'
        voice='certa ollama status'
        voiceReply=''
        allowParams='false'
    },
    [pscustomobject]@{
        trigger='Certa Open Server'
        command=('explorer.exe "{0}"' -f $ServerRoot)
        offCommand=''
        ground='foreground'
        voice='open certa server'
        voiceReply=''
        allowParams='false'
    }
)

$names = @($definitions | ForEach-Object {
    [string](Get-CertaPropertyValue -Object $_ -Name 'trigger')
})

$items = @($validItems | Where-Object {
    $existingName = [string](Get-CertaPropertyValue -Object $_ -Name 'trigger')
    $names -notcontains $existingName
}) + $definitions

$agent = Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue | Select-Object -First 1
$agentPath = $null
if ($agent) { try { $agentPath = $agent.Path } catch {} }
$temporaryPath = Join-Path (Split-Path -Parent $commandsPath) ('.commands.{0}.tmp' -f [guid]::NewGuid().ToString('N'))
$agentRestarted = $false

try {
    if ($agent -and $agentPath -and (Test-Path -LiteralPath $agentPath)) {
        Stop-Process -Id $agent.Id -Force
        Start-Sleep -Seconds 1
    }

    ConvertTo-Json -InputObject @($items) -Depth 20 |
        Set-Content -LiteralPath $temporaryPath -Encoding UTF8

    $validatedRoot = Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json
    $validatedItems = @(Expand-CertaCommandItems -Value $validatedRoot)

    foreach ($definition in $definitions) {
        $definitionName = [string](Get-CertaPropertyValue -Object $definition -Name 'trigger')
        $match = @($validatedItems | Where-Object {
            [string](Get-CertaPropertyValue -Object $_ -Name 'trigger') -eq $definitionName
        })

        if ($match.Count -ne 1) {
            throw "Trigger command validation failed for '$definitionName'."
        }

        $allowParams = [string](Get-CertaPropertyValue -Object $match[0] -Name 'allowParams')
        if ($allowParams -ne 'false') {
            throw "Trigger command unexpectedly allows parameters: $definitionName"
        }
    }

    Move-Item -LiteralPath $temporaryPath -Destination $commandsPath -Force
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }

    if ($agentPath -and (Test-Path -LiteralPath $agentPath)) {
        Start-Process -FilePath $agentPath
        Start-Sleep -Seconds 3
        $agentRestarted = [bool](Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue)
    }
}

[pscustomobject]@{
    status = 'PASS'
    commands_path = $commandsPath
    backup_path = $backupPath
    invalid_entries_backup = if ($invalidItems.Count -gt 0) { $invalidPath } else { $null }
    invalid_entries_removed = $invalidItems.Count
    installed = $names
    agent_restarted = $agentRestarted
    note = 'Foreground commands were normalized and registered atomically with parameters disabled.'
}
