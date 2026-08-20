#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [switch]$NoReceipt
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredFolders = @('CONTROL','INBOX','QUEUE','PROJECTS','REPOS','WORKTREES','WORKING','OUTPUTS','RECEIPTS','LOGS','BACKUPS')
$folderStatus = @()
foreach ($name in $requiredFolders) {
    $path = Join-Path $ServerRoot $name
    $folderStatus += [pscustomobject]@{ name=$name; path=$path; exists=[bool](Test-Path -LiteralPath $path) }
}

$ollamaHealthy = $false
$ollamaVersion = $null
$models = @()
try {
    $version = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 5
    $tags = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 10
    $ollamaHealthy = $true
    $ollamaVersion = [string]$version.version
    $models = @($tags.models | ForEach-Object { $_.name })
}
catch {}

$listeners = @()
try {
    $listeners = @(Get-NetTCPConnection -LocalPort 11434 -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,OwningProcess)
}
catch {}
$wildcardListener = @($listeners | Where-Object { $_.LocalAddress -in @('0.0.0.0','::') }).Count -gt 0

$driveName = ([IO.Path]::GetPathRoot($ServerRoot)).TrimEnd('\').TrimEnd(':')
$drive = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
$queueCounts = [ordered]@{}
foreach ($lane in @('script','ollama','codex','specialist','review')) {
    $path = Join-Path $ServerRoot "QUEUE\$lane"
    $queueCounts[$lane] = if (Test-Path -LiteralPath $path) { @(Get-ChildItem -LiteralPath $path -File -Filter '*.json' -ErrorAction SilentlyContinue).Count } else { 0 }
}
$queueCounts['inbox'] = if (Test-Path -LiteralPath (Join-Path $ServerRoot 'INBOX')) { @(Get-ChildItem -LiteralPath (Join-Path $ServerRoot 'INBOX') -File -Filter '*.json' -ErrorAction SilentlyContinue).Count } else { 0 }

$triggerConfig = Join-Path $env:USERPROFILE '.TRIGGERcmdData\commands.json'
$triggerCommands = @()
if (Test-Path -LiteralPath $triggerConfig) {
    try { $triggerCommands = @((Get-Content -LiteralPath $triggerConfig -Raw | ConvertFrom-Json) | ForEach-Object { $_.trigger }) } catch {}
}

$status = 'PASS'
$findings = New-Object System.Collections.Generic.List[string]
if (@($folderStatus | Where-Object { -not $_.exists }).Count -gt 0) { $status='ATTENTION'; $findings.Add('One or more required server folders are missing.') }
if (-not $ollamaHealthy) { $status='ATTENTION'; $findings.Add('Ollama local API is not healthy.') }
if ($wildcardListener) { $status='FAIL'; $findings.Add('Ollama is listening on a wildcard address; keep it on localhost only.') }
if (-not (Test-Path -LiteralPath $triggerConfig)) { $status='ATTENTION'; $findings.Add('TRIGGERcmd commands.json was not found for the current profile.') }
if ($drive -and $drive.Free -lt 20GB) { $status='ATTENTION'; $findings.Add('Server drive has less than 20 GiB free.') }

$result = [ordered]@{
    schema_version = 1
    checked_at = (Get-Date).ToUniversalTime().ToString('o')
    status = $status
    computer = $env:COMPUTERNAME
    user = "$env:USERDOMAIN\$env:USERNAME"
    server_root = $ServerRoot
    folders = $folderStatus
    drive_free_gib = if ($drive) { [math]::Round(($drive.Free / 1GB),2) } else { $null }
    ollama = [ordered]@{
        healthy = $ollamaHealthy
        version = $ollamaVersion
        models = $models
        listeners = $listeners
        wildcard_listener = $wildcardListener
    }
    trigger = [ordered]@{
        config_path = $triggerConfig
        config_exists = [bool](Test-Path -LiteralPath $triggerConfig)
        commands = $triggerCommands
        agent_running = [bool](Get-Process TRIGGERcmdAgent -ErrorAction SilentlyContinue)
    }
    tools = [ordered]@{
        git = [bool](Get-Command git.exe -ErrorAction SilentlyContinue)
        codex = [bool](Get-Command codex.exe -ErrorAction SilentlyContinue)
        ollama = [bool](Get-Command ollama.exe -ErrorAction SilentlyContinue)
    }
    queue = $queueCounts
    findings = $findings
}

if (-not $NoReceipt) {
    $receiptDir = Join-Path $ServerRoot 'RECEIPTS\health'
    New-Item -ItemType Directory -Path $receiptDir -Force | Out-Null
    $receiptPath = Join-Path $receiptDir ('health-{0:yyyyMMdd-HHmmss}.json' -f (Get-Date))
    $result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
    $result['receipt'] = $receiptPath
}

[pscustomobject]$result
if ($status -eq 'FAIL') { exit 2 }
