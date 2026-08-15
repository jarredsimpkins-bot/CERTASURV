param(
  [Parameter(Mandatory=$true)][string]$ProjectId,
  [Parameter(Mandatory=$true)][string]$EventId,
  [Parameter(Mandatory=$true)][string]$TargetSubject,
  [Parameter(Mandatory=$true)][string]$Message,
  [string]$ProjectConfigPath,
  [string]$ConfigPath = 'C:\Certa4010\CertaEvent\config.json'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Read-JsonFile([string]$Path) { (Get-Content -LiteralPath $Path -Raw) | ConvertFrom-Json }
function Fail([int]$Code,[string]$Message) { Write-Error $Message; exit $Code }

$config = Read-JsonFile $ConfigPath
if (-not $config.openproject -or $config.openproject.enabled -eq $false) {
  [ordered]@{status='disabled';event_id=$EventId} | ConvertTo-Json -Compress
  exit 0
}

$base = if ($env:CERTA_OPENPROJECT_URL) { $env:CERTA_OPENPROJECT_URL } else { $config.openproject.base_url }
$token = $env:CERTA_OPENPROJECT_TOKEN
if ([string]::IsNullOrWhiteSpace($base) -or [string]::IsNullOrWhiteSpace($token)) {
  [ordered]@{status='not_configured';event_id=$EventId;message='Set CERTA_OPENPROJECT_URL and CERTA_OPENPROJECT_TOKEN.'} | ConvertTo-Json -Compress
  exit 0
}
$base = $base.TrimEnd('/')
$headers = @{Authorization="Bearer $token";Accept='application/hal+json'}

$projectConfig = $null
if ($ProjectConfigPath -and (Test-Path -LiteralPath $ProjectConfigPath)) {
  try { $projectConfig = Read-JsonFile $ProjectConfigPath } catch {}
}

$workPackageId = $null
if ($projectConfig -and $projectConfig.openproject -and $projectConfig.openproject.work_packages) {
  $p = $projectConfig.openproject.work_packages.PSObject.Properties | Where-Object { $_.Name -eq $TargetSubject -or $_.Name -eq ($TargetSubject -replace '\s','_').ToLowerInvariant() } | Select-Object -First 1
  if ($p) { $workPackageId = [int]$p.Value }
}

if (-not $workPackageId) {
  $projectIdentifier = $ProjectId.ToLowerInvariant()
  if ($projectConfig -and $projectConfig.openproject -and $projectConfig.openproject.project_identifier) {
    $projectIdentifier = $projectConfig.openproject.project_identifier.ToString()
  }

  $projects = Invoke-RestMethod -Method Get -Uri "$base/api/v3/projects?pageSize=200&filters=%5B%5D" -Headers $headers -TimeoutSec 30
  $project = @($projects._embedded.elements) | Where-Object { $_.identifier -eq $projectIdentifier -or $_.name -eq $ProjectId } | Select-Object -First 1
  if (-not $project) {
    [ordered]@{status='project_not_found';project_id=$ProjectId;identifier=$projectIdentifier;event_id=$EventId} | ConvertTo-Json -Compress
    exit 0
  }

  $wps = Invoke-RestMethod -Method Get -Uri "$base/api/v3/projects/$($project.id)/work_packages?pageSize=200&filters=%5B%5D" -Headers $headers -TimeoutSec 30
  $items = @($wps._embedded.elements)
  $wp = $items | Where-Object { $_.subject -eq $TargetSubject } | Select-Object -First 1
  if (-not $wp) { $wp = $items | Where-Object { $_.subject -like "*$TargetSubject*" } | Select-Object -First 1 }
  if (-not $wp) {
    [ordered]@{status='work_package_not_found';project_id=$ProjectId;target_subject=$TargetSubject;event_id=$EventId} | ConvertTo-Json -Compress
    exit 0
  }
  $workPackageId = [int]$wp.id
}

$body = @{comment=@{raw="$Message`n`nCertaEvent: $EventId"}} | ConvertTo-Json -Depth 5
$result = Invoke-RestMethod -Method Post -Uri "$base/api/v3/work_packages/$workPackageId/activities?notify=true" -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 30
[ordered]@{
  status='commented'
  work_package_id=$workPackageId
  activity_id=$result.id
  project_id=$ProjectId
  target_subject=$TargetSubject
  event_id=$EventId
} | ConvertTo-Json -Compress
