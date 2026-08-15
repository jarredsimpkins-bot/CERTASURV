param(
  [Parameter(Mandatory=$true)][string]$DatasetPath,
  [Parameter(Mandatory=$true)][string]$ProjectId,
  [Parameter(Mandatory=$true)][string]$EventId,
  [string]$Profile = 'survey_ortho',
  [string]$ConfigPath = 'C:\Certa4010\CertaEvent\config.json'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Read-JsonFile([string]$Path) {
  (Get-Content -LiteralPath $Path -Raw) | ConvertFrom-Json
}

function Fail([int]$Code, [string]$Message) {
  Write-Error $Message
  exit $Code
}

if (-not (Test-Path -LiteralPath $DatasetPath)) { Fail 11 "Dataset not found: $DatasetPath" }
$config = Read-JsonFile $ConfigPath
if (-not $config.webodm -or $config.webodm.enabled -eq $false) { Fail 20 'WebODM integration is disabled in config.json.' }

$base = if ($env:CERTA_WEBODM_URL) { $env:CERTA_WEBODM_URL } else { $config.webodm.base_url }
$user = $env:CERTA_WEBODM_USER
$pass = $env:CERTA_WEBODM_PASSWORD
if ([string]::IsNullOrWhiteSpace($base)) { Fail 20 'CERTA_WEBODM_URL / webodm.base_url is not configured.' }
if ([string]::IsNullOrWhiteSpace($user) -or [string]::IsNullOrWhiteSpace($pass)) {
  Fail 20 'Set machine environment variables CERTA_WEBODM_USER and CERTA_WEBODM_PASSWORD before enabling drone automation.'
}
$base = $base.TrimEnd('/')

$auth = Invoke-RestMethod -Method Post -Uri "$base/api/token-auth/" -Body @{username=$user;password=$pass} -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 30
if (-not $auth.token) { Fail 21 'WebODM authentication did not return a token.' }
$headers = @{Authorization="JWT $($auth.token)"}

$projects = @(Invoke-RestMethod -Method Get -Uri "$base/api/projects/" -Headers $headers -TimeoutSec 30)
$project = $projects | Where-Object { $_.name -eq $ProjectId } | Select-Object -First 1
if (-not $project) {
  $project = Invoke-RestMethod -Method Post -Uri "$base/api/projects/" -Headers $headers -Body @{name=$ProjectId} -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 30
}
if (-not $project.id) { Fail 22 'Could not resolve or create the WebODM project.' }

$taskName = "$ProjectId AUTO $($EventId.Substring(0,[Math]::Min(12,$EventId.Length)))"
$tasks = @(Invoke-RestMethod -Method Get -Uri "$base/api/projects/$($project.id)/tasks/" -Headers $headers -TimeoutSec 30)
$existing = $tasks | Where-Object { $_.name -eq $taskName } | Select-Object -First 1
if ($existing) {
  [ordered]@{status='existing';project_id=$project.id;task_id=$existing.id;task_name=$taskName;event_id=$EventId} | ConvertTo-Json -Compress
  exit 0
}

$imageExt = @('.jpg','.jpeg','.dng','.tif','.tiff','.png')
$inputs = @(Get-ChildItem -LiteralPath $DatasetPath -File -Recurse -Force | Where-Object { $_.Extension.ToLowerInvariant() -in $imageExt } | Sort-Object FullName)
if ($inputs.Count -lt 2) { Fail 23 "WebODM requires at least 2 images; found $($inputs.Count)." }

$sidecars = @()
foreach ($dir in @($DatasetPath,(Split-Path -Parent $DatasetPath))) {
  foreach ($name in @('gcp_list.txt','geo.txt')) {
    $p = Join-Path $dir $name
    if (Test-Path -LiteralPath $p) { $sidecars += Get-Item -LiteralPath $p }
  }
}
$inputs += @($sidecars | Sort-Object FullName -Unique)

$options = @()
if ($config.webodm.profiles) {
  $profileObj = $config.webodm.profiles.PSObject.Properties[$Profile]
  if ($profileObj) { $options = @($profileObj.Value.options) }
}
$optionsJson = $options | ConvertTo-Json -Compress -Depth 10
if ([string]::IsNullOrWhiteSpace($optionsJson)) { $optionsJson = '[]' }

Add-Type -AssemblyName System.Net.Http
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromHours(12)
$client.DefaultRequestHeaders.Add('Authorization',"JWT $($auth.token)")
$multi = New-Object System.Net.Http.MultipartFormDataContent
$streams = New-Object System.Collections.Generic.List[System.IDisposable]

try {
  $nameContent = New-Object System.Net.Http.StringContent -ArgumentList $taskName
  $optionsContent = New-Object System.Net.Http.StringContent -ArgumentList $optionsJson
  $multi.Add($nameContent,'name')
  $multi.Add($optionsContent,'options')

  foreach ($f in $inputs) {
    $stream = [IO.File]::Open($f.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    $streams.Add($stream)
    $fc = New-Object System.Net.Http.StreamContent -ArgumentList $stream
    $streams.Add($fc)
    $multi.Add($fc,'images',$f.Name)
  }

  $uri = "$base/api/projects/$($project.id)/tasks/"
  $response = $client.PostAsync($uri,$multi).GetAwaiter().GetResult()
  $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
  if (-not $response.IsSuccessStatusCode) {
    Fail 24 "WebODM task creation failed HTTP $([int]$response.StatusCode): $body"
  }
  $task = $body | ConvertFrom-Json
  if (-not $task.id) { Fail 25 "WebODM task response did not contain an id: $body" }
  [ordered]@{
    status='created'
    project_id=$project.id
    task_id=$task.id
    task_name=$taskName
    file_count=$inputs.Count
    profile=$Profile
    event_id=$EventId
  } | ConvertTo-Json -Compress
} finally {
  try { $multi.Dispose() } catch {}
  foreach ($s in $streams) { try { $s.Dispose() } catch {} }
  try { $client.Dispose() } catch {}
}
