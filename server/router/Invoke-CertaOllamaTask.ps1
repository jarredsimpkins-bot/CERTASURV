#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ })]
    [string]$TaskPath,

    [string]$Model = 'certard-local'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$task = Get-Content -LiteralPath $TaskPath -Raw | ConvertFrom-Json
if ([string]$task.status -ne 'ROUTED' -or [string]$task.route.lane -ne 'OLLAMA') {
    throw 'The task must be ROUTED to the OLLAMA lane.'
}

$prompt = @"
You are CERTARD Local, a low-authority CertaSurv worker.
Complete only a reversible, candidate-level response to the request below.
Do not make professional survey, boundary, legal, credential, destructive, or release decisions.
State uncertainty and recommend CODEX, SPECIALIST, or HUMAN escalation when appropriate.

TASK ID: $($task.task_id)
PROJECT: $($task.project_id)
REQUEST:
$($task.request)
"@

$body = @{
    model = $Model
    prompt = $prompt
    stream = $false
    keep_alive = '10m'
} | ConvertTo-Json

$response = Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:11434/api/generate' -ContentType 'application/json' -Body $body -TimeoutSec 600
$now = (Get-Date).ToUniversalTime().ToString('o')
$outputDir = Join-Path $ServerRoot 'OUTPUTS\ollama'
$receiptDir = Join-Path $ServerRoot 'RECEIPTS\ollama'
New-Item -ItemType Directory -Path $outputDir,$receiptDir -Force | Out-Null

$outputPath = Join-Path $outputDir "$($task.task_id).md"
Set-Content -LiteralPath $outputPath -Value ([string]$response.response) -Encoding UTF8

$task.status = 'CANDIDATE_COMPLETE'
$task | Add-Member -NotePropertyName candidate_output -NotePropertyValue $outputPath -Force
$task | Add-Member -NotePropertyName completed_at -NotePropertyValue $now -Force
$task.history = @($task.history) + [pscustomobject]@{ timestamp=$now; event='OLLAMA_CANDIDATE_COMPLETE'; output=$outputPath; model=$Model }
$task | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $TaskPath -Encoding UTF8

$tokensPerSecond = $null
if ($response.eval_duration -and $response.eval_count) {
    $tokensPerSecond = [math]::Round(($response.eval_count / ($response.eval_duration / 1000000000)), 2)
}
$receipt = [ordered]@{
    schema_version = 1
    timestamp = $now
    task_id = [string]$task.task_id
    model = $Model
    output = $outputPath
    tokens_per_second = $tokensPerSecond
    status = 'CANDIDATE_COMPLETE'
    authority = 'CANDIDATE_ONLY'
}
$receiptPath = Join-Path $receiptDir "$($task.task_id)-ollama.json"
$receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $receiptPath -Encoding UTF8

[pscustomobject]@{
    task_id = $task.task_id
    output = $outputPath
    receipt = $receiptPath
    tokens_per_second = $tokensPerSecond
    status = 'CANDIDATE_COMPLETE'
}
