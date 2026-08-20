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
$backupPath = Join-Path $backupDir ('commands-{0:yyyyMMdd-HHmmss}.json' -f (Get-Date))
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
$items | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $commandsPath -Encoding UTF8
$null = Get-Content -LiteralPath $commandsPath -Raw | ConvertFrom-Json

$agent = Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue | Select-Object -First 1
if ($agent) {
    $agentPath = $null
    try { $agentPath = $agent.Path } catch {}
    if ($agentPath -and (Test-Path -LiteralPath $agentPath)) {
        Stop-Process -Id $agent.Id -Force
        Start-Sleep -Seconds 2
        Start-Process -FilePath $agentPath
        Start-Sleep -Seconds 3
    }
}

[pscustomobject]@{
    status = 'PASS'
    commands_path = $commandsPath
    backup_path = $backupPath
    installed = $names
    note = 'Foreground commands were registered with parameters disabled.'
}
