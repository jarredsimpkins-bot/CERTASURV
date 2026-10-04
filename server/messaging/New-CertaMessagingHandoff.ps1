#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServerRoot = 'D:\SERVER',
    [ValidateSet('CODEX','HUMAN')]
    [string]$Gate = 'CODEX'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$newTask = Join-Path $ServerRoot 'ROUTER\New-CertaTask.ps1'
if (-not (Test-Path -LiteralPath $newTask -PathType Leaf)) {
    throw 'Install/verify the existing Certa router first. No task was created.'
}
$readme = Join-Path $PSScriptRoot 'README.md'
if ($Gate -eq 'CODEX') {
    $request = 'Review and test the isolated server/messaging client-texting module. Run synthetic tests, inspect failure handling, and produce a receipt. Keep the module paused and dry-run only. Do not contact clients or execute release steps. Follow the README handoff boundaries.'
} else {
    $request = 'Human review required for client-texting production release: provider and existing-number compatibility, verified sender, consent evidence, operator account isolation, private secrets, budgets, callback verification, owner-only test, and separate client-release approval. Do not send messages or deploy from this task.'
}
# Uses the existing task constructor; does not add an arbitrary-shell capability,
# change router policy, execute CODEX, configure a provider, or send an SMS.
& $newTask -ServerRoot $ServerRoot -Request $request -InputPath $readme `
    -PreferredLane $Gate -AllowedLane @('CODEX','HUMAN') -Sensitivity COMPANY
