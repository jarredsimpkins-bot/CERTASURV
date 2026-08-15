param(
  [string]$ConfigPath = 'C:\Certa4010\CertaEvent\config.json',
  [string]$RulesPath = 'C:\Certa4010\CertaEvent\rules.json',
  [switch]$Once,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Read-JsonFile([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { throw "Missing JSON file: $Path" }
  $raw = Get-Content -LiteralPath $Path -Raw
  if ([string]::IsNullOrWhiteSpace($raw)) { throw "Empty JSON file: $Path" }
  return ($raw | ConvertFrom-Json)
}

function Write-JsonAtomic([string]$Path, $Value) {
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  $tmp = "$Path.tmp.$PID"
  $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $tmp -Encoding UTF8
  Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Get-Sha256Text([string]$Text) {
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
  } finally { $sha.Dispose() }
}

function Get-ProjectId([string]$Path, [string]$Regex) {
  $m = [regex]::Match($Path, $Regex)
  if ($m.Success) { return $m.Value.ToUpperInvariant() }
  return 'UNASSIGNED'
}

function Get-ProjectConfigPath([string]$DatasetPath, [string]$ProjectRoot) {
  $cursor = Get-Item -LiteralPath $DatasetPath
  $limit = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
  while ($cursor -and $cursor.FullName.Length -ge $limit.Length) {
    foreach ($name in @('CERTA_PROJECT.json', '.certa\project.json')) {
      $candidate = Join-Path $cursor.FullName $name
      if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    if ($cursor.FullName.TrimEnd('\') -eq $limit) { break }
    $cursor = $cursor.Parent
  }
  return $null
}

function Get-DatasetSnapshot([string]$Path, $Rule) {
  $allowed = @()
  if ($Rule.extensions) { $allowed = @($Rule.extensions | ForEach-Object { $_.ToString().ToLowerInvariant() }) }
  $files = @(Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
    if ($allowed.Count -eq 0) { return $true }
    return ($_.Extension.ToLowerInvariant() -in $allowed)
  } | Sort-Object FullName)

  [int64]$bytes = 0
  [datetime]$latest = [datetime]::MinValue
  $sb = New-Object Text.StringBuilder
  foreach ($f in $files) {
    $bytes += [int64]$f.Length
    if ($f.LastWriteTimeUtc -gt $latest) { $latest = $f.LastWriteTimeUtc }
    [void]$sb.Append($f.FullName.ToLowerInvariant()).Append('|').Append($f.Length).Append('|').Append($f.LastWriteTimeUtc.Ticks).Append("`n")
  }

  $signature = Get-Sha256Text $sb.ToString()
  [pscustomobject]@{
    count = $files.Count
    bytes = $bytes
    latest_write_utc = if ($latest -eq [datetime]::MinValue) { $null } else { $latest.ToString('o') }
    signature = $signature
  }
}

function Get-RuleDirectories([string]$Root, $Rule) {
  if (-not (Test-Path -LiteralPath $Root)) { return @() }
  $all = @(Get-ChildItem -LiteralPath $Root -Directory -Recurse -Force -ErrorAction SilentlyContinue)
  $all += Get-Item -LiteralPath $Root
  return @($all | Where-Object {
    $p = $_.FullName.Replace('/','\')
    $p -match $Rule.path_regex
  })
}

function New-Result([bool]$Success, [string]$Status, [string]$Message, $Data = $null) {
  [pscustomobject]@{
    success = $Success
    status = $Status
    message = $Message
    data = $Data
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
  }
}

function Write-OfficeOutbox($Config, $Event, [string]$Kind, [string]$Message, $Extra = $null) {
  $root = $Config.state_root
  $officeDir = Join-Path $root 'outbox\office'
  New-Item -ItemType Directory -Force -Path $officeDir | Out-Null
  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $safeProject = ($Event.project_id -replace '[^A-Za-z0-9_-]','_')
  $path = Join-Path $officeDir ("{0}_{1}_{2}_{3}.json" -f $stamp,$safeProject,$Kind,$Event.event_id)
  $payload = [ordered]@{
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
    kind = $Kind
    message = $Message
    event = $Event
    extra = $Extra
  }
  Write-JsonAtomic $path $payload

  $ledger = Join-Path $officeDir 'attention.ndjson'
  ($payload | ConvertTo-Json -Compress -Depth 20) | Add-Content -LiteralPath $ledger -Encoding UTF8

  if ($Config.office_webhook_url) {
    try {
      Invoke-RestMethod -Method Post -Uri $Config.office_webhook_url -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 20) -TimeoutSec 15 | Out-Null
    } catch {
      $err = [ordered]@{timestamp=(Get-Date).ToUniversalTime().ToString('o');error=$_.Exception.Message;payload_path=$path}
      ($err | ConvertTo-Json -Compress -Depth 10) | Add-Content -LiteralPath (Join-Path $officeDir 'webhook-errors.ndjson') -Encoding UTF8
    }
  }
  return $path
}

function Invoke-ExternalAction([string]$ScriptPath, [string[]]$Arguments) {
  if (-not (Test-Path -LiteralPath $ScriptPath)) { return New-Result $false 'missing_script' "Missing action script: $ScriptPath" }
  $all = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$ScriptPath) + $Arguments
  $output = & powershell.exe @all 2>&1
  $code = $LASTEXITCODE
  $text = ($output | Out-String).Trim()
  if ($code -eq 0) { return New-Result $true 'ok' $text }
  return New-Result $false "exit_$code" $text
}

function Invoke-Action($Config, $Rule, $Action, $Event, [string]$ProjectConfigPath, [switch]$DryRun) {
  $type = $Action.type.ToString()
  $actionId = $Action.id.ToString()

  if ($DryRun) { return New-Result $true 'dry_run' "Would run $type/$actionId" }

  switch ($type) {
    'office_notify' {
      $msg = if ($Action.message) { $Action.message.ToString() } else { "$($Event.project_id): $($Rule.id) received." }
      $msg = $msg.Replace('{project_id}',$Event.project_id).Replace('{file_count}',$Event.snapshot.count.ToString()).Replace('{dataset_path}',$Event.dataset_path)
      $p = Write-OfficeOutbox $Config $Event 'event' $msg
      return New-Result $true 'queued' "Office notification queued: $p"
    }
    'webodm' {
      $script = Join-Path $PSScriptRoot 'Invoke-CertaWebODM.ps1'
      $args = @('-DatasetPath',$Event.dataset_path,'-ProjectId',$Event.project_id,'-EventId',$Event.event_id,'-ConfigPath',$ConfigPath)
      if ($Action.profile) { $args += @('-Profile',$Action.profile.ToString()) }
      return Invoke-ExternalAction $script $args
    }
    'openproject_comment' {
      $script = Join-Path $PSScriptRoot 'Invoke-CertaOpenProject.ps1'
      $target = if ($Action.target_subject) { $Action.target_subject.ToString() } else { 'Office Processing' }
      $msg = if ($Action.message) { $Action.message.ToString() } else { "$($Event.project_id): $($Rule.id) received ($($Event.snapshot.count) files)." }
      $msg = $msg.Replace('{project_id}',$Event.project_id).Replace('{file_count}',$Event.snapshot.count.ToString()).Replace('{dataset_path}',$Event.dataset_path)
      $args = @('-ProjectId',$Event.project_id,'-EventId',$Event.event_id,'-TargetSubject',$target,'-Message',$msg,'-ConfigPath',$ConfigPath)
      if ($ProjectConfigPath) { $args += @('-ProjectConfigPath',$ProjectConfigPath) }
      return Invoke-ExternalAction $script $args
    }
    'run_script' {
      if (-not $Action.script) { return New-Result $false 'invalid_action' "run_script action '$actionId' is missing script." }
      $scriptPath = $Action.script.ToString()
      if (-not [IO.Path]::IsPathRooted($scriptPath)) { $scriptPath = Join-Path $PSScriptRoot $scriptPath }
      $args = @('-DatasetPath',$Event.dataset_path,'-ProjectId',$Event.project_id,'-EventId',$Event.event_id)
      return Invoke-ExternalAction $scriptPath $args
    }
    default { return New-Result $false 'unknown_action' "Unknown action type: $type" }
  }
}

$Config = Read-JsonFile $ConfigPath
$RulesDoc = Read-JsonFile $RulesPath
if (-not $Config.state_root) { throw 'config.json must define state_root.' }
if (-not $Config.project_roots -or @($Config.project_roots).Count -eq 0) { throw 'config.json must define at least one project_roots entry.' }

$stateRoot = $Config.state_root
$datasetStateDir = Join-Path $stateRoot 'state\datasets'
$actionStateDir = Join-Path $stateRoot 'state\actions'
$receiptDir = Join-Path $stateRoot 'receipts'
$logDir = Join-Path $stateRoot 'logs'
New-Item -ItemType Directory -Force -Path $datasetStateDir,$actionStateDir,$receiptDir,$logDir | Out-Null
$logPath = Join-Path $logDir 'certaevent.ndjson'

function Log-Event([string]$Level, [string]$Message, $Data = $null) {
  $row = [ordered]@{timestamp=(Get-Date).ToUniversalTime().ToString('o');level=$Level;message=$Message;data=$Data}
  ($row | ConvertTo-Json -Compress -Depth 20) | Add-Content -LiteralPath $logPath -Encoding UTF8
}

function Process-RuleDirectory([string]$Root, $Rule, [string]$DatasetPath) {
  $snapshot = Get-DatasetSnapshot $DatasetPath $Rule
  $min = if ($Rule.minimum_files -ne $null) { [int]$Rule.minimum_files } else { 1 }
  if ($snapshot.count -lt $min) { return }

  $key = Get-Sha256Text ($Rule.id.ToString() + '|' + $DatasetPath.ToLowerInvariant())
  $statePath = Join-Path $datasetStateDir "$key.json"
  $now = (Get-Date).ToUniversalTime()
  $state = $null
  if (Test-Path -LiteralPath $statePath) { try { $state = Read-JsonFile $statePath } catch { $state = $null } }

  if (-not $state) {
    $state = [ordered]@{rule_id=$Rule.id;dataset_path=$DatasetPath;signature=$snapshot.signature;last_changed_utc=$now.ToString('o');processed_signature=$null;last_event_id=$null;retry_after_utc=$null}
    Write-JsonAtomic $statePath $state
    if ([int]$Rule.stable_seconds -gt 0) { return }
  } elseif ($state.signature -ne $snapshot.signature) {
    $state.signature = $snapshot.signature
    $state.last_changed_utc = $now.ToString('o')
    $state.retry_after_utc = $null
    Write-JsonAtomic $statePath $state
    if ([int]$Rule.stable_seconds -gt 0) { return }
  }

  if ($state.processed_signature -eq $snapshot.signature) { return }
  if ($state.retry_after_utc) {
    $retryAt = [datetime]::Parse($state.retry_after_utc).ToUniversalTime()
    if ($now -lt $retryAt) { return }
  }

  $stableSeconds = if ($Rule.stable_seconds -ne $null) { [int]$Rule.stable_seconds } else { 60 }
  $lastChanged = [datetime]::Parse($state.last_changed_utc).ToUniversalTime()
  if (($now - $lastChanged).TotalSeconds -lt $stableSeconds) { return }

  $projectRegex = if ($Config.project_id_regex) { $Config.project_id_regex.ToString() } else { '(?i)SSD-\d{5}(?:-\d{3})?' }
  $projectId = Get-ProjectId $DatasetPath $projectRegex
  $eventId = (Get-Sha256Text ($Rule.id.ToString() + '|' + $projectId + '|' + $DatasetPath.ToLowerInvariant() + '|' + $snapshot.signature)).Substring(0,24)
  $projectConfigPath = Get-ProjectConfigPath $DatasetPath $Root

  $event = [ordered]@{schema_version=1;event_id=$eventId;event_type='files.received';rule_id=$Rule.id;project_id=$projectId;project_root=$Root;dataset_path=$DatasetPath;detected_utc=$now.ToString('o');snapshot=$snapshot;computer=$env:COMPUTERNAME;project_config_path=$projectConfigPath}
  Write-JsonAtomic (Join-Path $receiptDir "$eventId.detected.json") $event
  Log-Event 'INFO' 'Event detected' $event

  $allRequiredOk = $true
  $actionResults = @()
  foreach ($action in @($Rule.actions)) {
    $actionId = $action.id.ToString()
    $actionReceipt = Join-Path $actionStateDir "$eventId.$actionId.json"
    $previous = $null
    if (Test-Path -LiteralPath $actionReceipt) { try { $previous = Read-JsonFile $actionReceipt } catch {} }

    if ($previous -and $previous.success -eq $true) {
      $result = $previous.result
    } else {
      $result = Invoke-Action $Config $Rule $action $event $projectConfigPath -DryRun:$DryRun
      $record = [ordered]@{event_id=$eventId;action_id=$actionId;action_type=$action.type;success=[bool]$result.success;result=$result}
      Write-JsonAtomic $actionReceipt $record
    }

    $actionResults += [pscustomobject]@{id=$actionId;type=$action.type;required=[bool]$action.required;result=$result}
    if ([bool]$action.required -and -not [bool]$result.success) { $allRequiredOk = $false; break }
  }

  $final = [ordered]@{event=$event;completed_utc=(Get-Date).ToUniversalTime().ToString('o');success=$allRequiredOk;actions=$actionResults}

  if ($allRequiredOk) {
    if ($DryRun) {
      Write-JsonAtomic (Join-Path $receiptDir "$eventId.dryrun.json") $final
      Log-Event 'INFO' 'Event dry-run completed without consuming dataset' $final
      return
    }
    $state.processed_signature = $snapshot.signature
    $state.last_event_id = $eventId
    $state.retry_after_utc = $null
    Write-JsonAtomic $statePath $state
    Write-JsonAtomic (Join-Path $receiptDir "$eventId.completed.json") $final
    Log-Event 'INFO' 'Event completed' $final
  } else {
    $retrySeconds = if ($Config.retry_seconds) { [int]$Config.retry_seconds } else { 300 }
    $state.retry_after_utc = $now.AddSeconds($retrySeconds).ToString('o')
    $state.last_event_id = $eventId
    Write-JsonAtomic $statePath $state
    $blockedPath = Join-Path $receiptDir "$eventId.blocked.json"
    $firstBlock = -not (Test-Path -LiteralPath $blockedPath)
    Write-JsonAtomic $blockedPath $final
    $failed = $actionResults[-1]
    $msg = "$projectId automation blocked at $($failed.id): $($failed.result.message)"
    if ($firstBlock) { [void](Write-OfficeOutbox $Config $event 'automation_blocked' $msg $failed) }
    Log-Event 'ERROR' $msg $final
  }
}

function Run-Poll {
  foreach ($rootValue in @($Config.project_roots)) {
    $root = [Environment]::ExpandEnvironmentVariables($rootValue.ToString())
    if (-not (Test-Path -LiteralPath $root)) { Log-Event 'WARN' "Project root missing: $root"; continue }
    foreach ($rule in @($RulesDoc.rules | Where-Object { $_.enabled -ne $false })) {
      try {
        foreach ($dir in @(Get-RuleDirectories $root $rule)) { Process-RuleDirectory $root $rule $dir.FullName }
      } catch {
        Log-Event 'ERROR' "Rule $($rule.id) failed: $($_.Exception.Message)" $_.ScriptStackTrace
      }
    }
  }
}

Log-Event 'INFO' 'CertaEvent watcher started' @{once=[bool]$Once;dry_run=[bool]$DryRun;roots=$Config.project_roots}
do {
  Run-Poll
  if ($Once) { break }
  $sleep = if ($Config.poll_seconds) { [int]$Config.poll_seconds } else { 15 }
  Start-Sleep -Seconds ([Math]::Max(2,$sleep))
} while ($true)
