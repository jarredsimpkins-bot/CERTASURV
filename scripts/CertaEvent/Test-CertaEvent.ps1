param(
  [string]$WatcherPath = (Join-Path $PSScriptRoot 'CertaEvent-Watcher.ps1')
)

$ErrorActionPreference='Stop'
$root = Join-Path $env:TEMP ("CertaEventTest_" + [guid]::NewGuid().ToString('N'))
$project = Join-Path $root 'SSD-99999-001'
$drone = Join-Path $project '03_FIELD_WORK\DRONE_WORKS\RAW_PHOTOS'
$gnss = Join-Path $project '03_FIELD_WORK\GNSS'
$runtime = Join-Path $root 'runtime'
New-Item -ItemType Directory -Force -Path $drone,$gnss,$runtime | Out-Null

1..25 | ForEach-Object { Set-Content -LiteralPath (Join-Path $drone ("IMG_{0:D4}.jpg" -f $_)) -Value "fake-image-$_" -Encoding ASCII }
Set-Content -LiteralPath (Join-Path $gnss 'TEST.job') -Value 'fake-job' -Encoding ASCII

$config = [ordered]@{
  schema_version=1
  project_roots=@($root)
  project_id_regex='(?i)SSD-\d{5}(?:-\d{3})?'
  state_root=$runtime
  poll_seconds=2
  retry_seconds=2
  office_webhook_url=''
  webodm=@{enabled=$false;base_url=''}
  openproject=@{enabled=$false;base_url=''}
}
$configPath = Join-Path $root 'config.json'
$config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $configPath -Encoding UTF8

$rules = [ordered]@{
  schema_version=1
  rules=@(
    [ordered]@{
      id='test_drone';enabled=$true;event='files.received'
      path_regex='(?i)\\03_FIELD_WORK\\DRONE_WORKS\\RAW_PHOTOS$'
      extensions=@('.jpg');minimum_files=20;stable_seconds=0
      actions=@([ordered]@{id='office';type='office_notify';required=$true;message='{project_id}: test drone {file_count}'})
    },
    [ordered]@{
      id='test_gnss';enabled=$true;event='files.received'
      path_regex='(?i)\\03_FIELD_WORK\\GNSS$'
      extensions=@('.job');minimum_files=1;stable_seconds=0
      actions=@([ordered]@{id='office';type='office_notify';required=$true;message='{project_id}: test GNSS {file_count}'})
    }
  )
}
$rulesPath = Join-Path $root 'rules.json'
$rules | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $rulesPath -Encoding UTF8

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $WatcherPath -ConfigPath $configPath -RulesPath $rulesPath -Once
if ($LASTEXITCODE -ne 0) { throw "Watcher first pass failed: $LASTEXITCODE" }

$completed1 = @(Get-ChildItem -LiteralPath (Join-Path $runtime 'receipts') -Filter '*.completed.json' -File)
$office1 = @(Get-ChildItem -LiteralPath (Join-Path $runtime 'outbox\office') -Filter '*.json' -File)
if ($completed1.Count -ne 2) { throw "Expected 2 completed receipts, found $($completed1.Count)." }
if ($office1.Count -ne 2) { throw "Expected 2 office notifications, found $($office1.Count)." }

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $WatcherPath -ConfigPath $configPath -RulesPath $rulesPath -Once
if ($LASTEXITCODE -ne 0) { throw "Watcher second pass failed: $LASTEXITCODE" }

$completed2 = @(Get-ChildItem -LiteralPath (Join-Path $runtime 'receipts') -Filter '*.completed.json' -File)
$office2 = @(Get-ChildItem -LiteralPath (Join-Path $runtime 'outbox\office') -Filter '*.json' -File)
if ($completed2.Count -ne 2 -or $office2.Count -ne 2) { throw 'Idempotency failure: second pass emitted duplicates.' }

[ordered]@{
  result='CERTAEVENT_TEST_OK'
  root=$root
  completed_receipts=$completed2.Count
  office_notifications=$office2.Count
  idempotent=$true
} | ConvertTo-Json -Depth 5
