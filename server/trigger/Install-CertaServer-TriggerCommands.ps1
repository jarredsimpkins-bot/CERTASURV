#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CertaCommandPropertyValue {
    param(
        [Parameter(Mandatory=$true)]$InputObject,
        [Parameter(Mandatory=$true)][string]$Name
    )

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return '' }
    return [string]$property.Value
}

$commandsPath = Join-Path $env:USERPROFILE '.TRIGGERcmdData\commands.json'
if (-not (Test-Path -LiteralPath $commandsPath)) {
    throw "TRIGGERcmd commands file not found: $commandsPath. Open the foreground agent under this Windows profile, then rerun."
}

$backupDir = Join-Path $ServerRoot 'CONTROL\backups\triggercmd'
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$backupPath = Join-Path $backupDir ('commands-{0:yyyyMMdd-HHmmssfff}-{1}.json' -f (Get-Date), ([guid]::NewGuid().ToString('N').Substring(0,8)))
Copy-Item -LiteralPath $commandsPath -Destination $backupPath -Force

$items = @()
$raw = Get-Content -LiteralPath $commandsPath -Raw
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    # Windows PowerShell 5.1 can preserve a JSON array as one nested pipeline
    # object. Assign first, then expand it so each command is validated alone.
    $parsedItems = $raw | ConvertFrom-Json
    $items = @($parsedItems)
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

$names = @($definitions | ForEach-Object { $_.trigger })
$retainedItems = @()
$droppedInvalidItems = 0
foreach ($item in $items) {
    $triggerName = Get-CertaCommandPropertyValue -InputObject $item -Name 'trigger'
    $commandText = Get-CertaCommandPropertyValue -InputObject $item -Name 'command'
    if ([string]::IsNullOrWhiteSpace($triggerName) -or [string]::IsNullOrWhiteSpace($commandText)) {
        $droppedInvalidItems++
        continue
    }
    if ($triggerName -notin $names) { $retainedItems += $item }
}
$items = @($retainedItems) + @($definitions)
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

    $json = $items | ConvertTo-Json -Depth 20
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText($temporaryPath, $json, $utf8NoBom)
    $fileBytes = [IO.File]::ReadAllBytes($temporaryPath)
    if ($fileBytes.Length -ge 3 -and $fileBytes[0] -eq 0xEF -and $fileBytes[1] -eq 0xBB -and $fileBytes[2] -eq 0xBF) {
        throw 'Trigger command JSON must be UTF-8 without a byte-order mark.'
    }
    $validatedJson = Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json
    $validatedItems = @($validatedJson)
    foreach ($definition in $definitions) {
        $match = @($validatedItems | Where-Object {
            (Get-CertaCommandPropertyValue -InputObject $_ -Name 'trigger') -eq [string]$definition.trigger
        })
        if ($match.Count -ne 1) { throw "Trigger command validation failed for '$($definition.trigger)'." }
        if ((Get-CertaCommandPropertyValue -InputObject $match[0] -Name 'allowParams') -ne 'false') {
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
    status = 'PASS'
    commands_path = $commandsPath
    backup_path = $backupPath
    installed = $names
    agent_restarted = $agentRestarted
    retained_existing_commands = $retainedItems.Count
    dropped_invalid_commands = $droppedInvalidItems
    note = 'Foreground commands were registered atomically with parameters disabled.'
}
