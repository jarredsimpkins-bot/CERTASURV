#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Request,

    [string]$ProjectId,

    [string[]]$InputPath = @(),

    [ValidateSet('SCRIPT','OLLAMA','CODEX','SPECIALIST','HUMAN')]
    [string]$PreferredLane,

    [ValidateSet('NORMAL','COMPANY','CLIENT','RESTRICTED')]
    [string]$Sensitivity = 'COMPANY',

    [ValidateSet('SCRIPT','OLLAMA','CODEX','SPECIALIST','HUMAN')]
    [string[]]$AllowedLane = @('SCRIPT','OLLAMA','CODEX','SPECIALIST','HUMAN')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (@($AllowedLane).Count -eq 0) {
    throw 'AllowedLane must contain at least one routing lane.'
}

$inbox = Join-Path $ServerRoot 'INBOX'
New-Item -ItemType Directory -Path $inbox -Force | Out-Null

$now = (Get-Date).ToUniversalTime()
$taskId = 'task-{0}-{1}' -f $now.ToString('yyyyMMdd-HHmmss'), ([guid]::NewGuid().ToString('N').Substring(0,8))
$inputs = @()
foreach ($path in @($InputPath)) {
    if ([string]::IsNullOrWhiteSpace($path)) { continue }
    $inputs += $path
}

$task = [ordered]@{
    schema_version = 1
    task_id = $taskId
    created_at = $now.ToString('o')
    created_by = "$env:USERDOMAIN\$env:USERNAME"
    computer = $env:COMPUTERNAME
    project_id = if ([string]::IsNullOrWhiteSpace($ProjectId)) { $null } else { $ProjectId }
    request = $Request.Trim()
    inputs = $inputs
    preferred_lane = if ([string]::IsNullOrWhiteSpace($PreferredLane)) { $null } else { $PreferredLane }
    allowed_lanes = @($AllowedLane | Select-Object -Unique)
    sensitivity = $Sensitivity
    status = 'NEW'
    route = $null
    attempts = 0
    history = @(
        [ordered]@{
            timestamp = $now.ToString('o')
            event = 'TASK_CREATED'
            actor = "$env:USERDOMAIN\$env:USERNAME"
        }
    )
}

$taskPath = Join-Path $inbox "$taskId.json"
$task | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $taskPath -Encoding UTF8

[pscustomobject]@{
    task_id = $taskId
    path = $taskPath
    status = 'NEW'
    request = $task.request
}
