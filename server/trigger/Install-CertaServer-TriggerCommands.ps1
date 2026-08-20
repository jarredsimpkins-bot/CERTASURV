#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
if (-not [string]::IsNullOrWhiteSpace($raw)) { $items = @($raw | ConvertFrom-Json) }

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
$items = @($items | Where-Object { $_.trigger -notin $names }) + $definitions
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

    $items | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
    $validatedItems = @(Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json)
    foreach ($definition in $definitions) {
        $match = @($validatedItems | Where-Object { [string]$_.trigger -eq [string]$definition.trigger })
        if ($match.Count -ne 1) { throw "Trigger command validation failed for '$($definition.trigger)'." }
        if ([string]$match[0].allowParams -ne 'false') { throw "Trigger command unexpectedly allows parameters: $($definition.trigger)" }
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
    note = 'Foreground commands were registered atomically with parameters disabled.'
}
