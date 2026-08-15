param(
  [string[]]$ProjectRoots = @(),
  [switch]$StartNow
)

$ErrorActionPreference='Stop'
$runtime='C:\Certa4010\CertaEvent'
$base='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main'
New-Item -ItemType Directory -Force -Path $runtime | Out-Null

$downloads = @{
  'CertaEvent-Watcher.ps1'='scripts/CertaEvent/CertaEvent-Watcher.ps1'
  'Invoke-CertaWebODM.ps1'='scripts/CertaEvent/Invoke-CertaWebODM.ps1'
  'Invoke-CertaOpenProject.ps1'='scripts/CertaEvent/Invoke-CertaOpenProject.ps1'
  'Test-CertaEvent.ps1'='scripts/CertaEvent/Test-CertaEvent.ps1'
  'rules.json'='scripts/CertaEvent/rules.json'
  'config.example.json'='scripts/CertaEvent/config.example.json'
}
foreach ($name in $downloads.Keys) {
  Invoke-WebRequest -UseBasicParsing -Uri "$base/$($downloads[$name])" -OutFile (Join-Path $runtime $name)
}

$configPath = Join-Path $runtime 'config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
  $cfg = Get-Content -LiteralPath (Join-Path $runtime 'config.example.json') -Raw | ConvertFrom-Json

  if ($ProjectRoots.Count -eq 0 -and $env:CERTA_PROJECT_ROOTS) {
    $ProjectRoots = @($env:CERTA_PROJECT_ROOTS -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  }
  if ($ProjectRoots.Count -eq 0) {
    $candidates = @(
      'D:\CertaSurv\Projects',
      'D:\CERTASURV\Projects',
      'D:\CertaSurv',
      'D:\Projects',
      'C:\CertaSurv',
      'C:\Certa4010\Projects',
      'G:\My Drive\SSD',
      'G:\My Drive\CertaSurv'
    )
    $found = @($candidates | Where-Object { Test-Path -LiteralPath $_ })
    $ProjectRoots = @()
    foreach ($candidate in $found) {
      $full = [IO.Path]::GetFullPath($candidate).TrimEnd('\')
      $nested = $false
      foreach ($kept in $ProjectRoots) {
        $parent = [IO.Path]::GetFullPath($kept).TrimEnd('\')
        if ($full.StartsWith($parent + '\',[StringComparison]::OrdinalIgnoreCase) -or $full -eq $parent) { $nested=$true; break }
      }
      if (-not $nested) { $ProjectRoots += $full }
    }
  }
  if ($ProjectRoots.Count -eq 0) {
    $ProjectRoots = @('C:\Certa4010\Projects')
    New-Item -ItemType Directory -Force -Path $ProjectRoots[0] | Out-Null
  }
  $cfg.project_roots = @($ProjectRoots)
  $cfg | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $configPath -Encoding UTF8
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $runtime 'Test-CertaEvent.ps1')
if ($LASTEXITCODE -ne 0) { throw 'CertaEvent self-test failed; scheduled task was not installed.' }

$taskName='CertaEvent Watcher'
$watcher=Join-Path $runtime 'CertaEvent-Watcher.ps1'
$action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watcher`""
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$mappedOrUserRoot = @($ProjectRoots | Where-Object { $_ -match '^[G-Z]:' -or $_ -match '%USERPROFILE%' }).Count -gt 0
if ($admin -and -not $mappedOrUserRoot) {
  $trigger=New-ScheduledTaskTrigger -AtStartup
  $principal=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
} else {
  $trigger=New-ScheduledTaskTrigger -AtLogOn
  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Force | Out-Null
}

if ($StartNow) { Start-ScheduledTask -TaskName $taskName }

[ordered]@{
  result='CERTAEVENT_INSTALLED'
  runtime=$runtime
  config=$configPath
  rules=(Join-Path $runtime 'rules.json')
  task=$taskName
  started=[bool]$StartNow
  project_roots=@((Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json).project_roots)
  webodm_credentials='Set machine env vars CERTA_WEBODM_USER and CERTA_WEBODM_PASSWORD.'
  openproject_credentials='When enabled, set CERTA_OPENPROJECT_URL and CERTA_OPENPROJECT_TOKEN.'
} | ConvertTo-Json -Depth 10
