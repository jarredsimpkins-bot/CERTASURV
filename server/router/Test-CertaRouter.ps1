#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Equal {
    param([string]$Name, $Actual, $Expected)
    if ($Actual -ne $Expected) {
        throw "$Name failed. Expected '$Expected' but got '$Actual'."
    }
    Write-Host "PASS $Name -> $Actual"
}

function Assert-True {
    param([string]$Name, [bool]$Condition)
    if (-not $Condition) { throw "$Name failed." }
    Write-Host "PASS $Name"
}

$testRoot = Join-Path $env:TEMP ('certa-router-test-' + [guid]::NewGuid().ToString('N'))
try {
    $policyDir = Join-Path $testRoot 'CONTROL\policies'
    $registryDir = Join-Path $testRoot 'CONTROL\registries'
    New-Item -ItemType Directory -Path $policyDir,$registryDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\policies\task-routing-policy.json') -Destination (Join-Path $policyDir 'task-routing-policy.json')

    $dummy = Join-Path $testRoot 'dummy.ps1'
    Set-Content -LiteralPath $dummy -Value "'ok'" -Encoding UTF8
    @([pscustomobject]@{
        capability_id='file-manifest-v1'
        intent_regex='(?i)(checksum|file manifest|inventory files)'
        status='VERIFIED'
        script_path=$dummy
        validator_path=$dummy
        node='CERTA-SERVER'
    }) | Export-Csv -LiteralPath (Join-Path $registryDir 'CAPABILITY_REGISTRY.csv') -NoTypeInformation -Encoding UTF8

    $newTask = Join-Path $PSScriptRoot 'New-CertaTask.ps1'
    $router = Join-Path $PSScriptRoot 'Invoke-CertaRouter.ps1'
    $cases = @(
        @{ Name='script'; Request='Create a checksum manifest for this folder'; Lane='SCRIPT' },
        @{ Name='ollama'; Request='Summarize and classify these notes'; Lane='OLLAMA' },
        @{ Name='codex'; Request='Build a new PowerShell integration and tests'; Lane='CODEX' },
        @{ Name='specialist'; Request='Open TBC and run the CAD import'; Lane='SPECIALIST' },
        @{ Name='human'; Request='Delete the final boundary and send to client'; Lane='HUMAN' }
    )

    foreach ($case in $cases) {
        $created = & $newTask -ServerRoot $testRoot -Request $case.Request
        $routed = & $router -ServerRoot $testRoot -TaskPath $created.path
        Assert-Equal -Name $case.Name -Actual $routed.lane -Expected $case.Lane
    }

    $forcedHuman = & $newTask -ServerRoot $testRoot -Request 'Delete production evidence' -AllowedLane CODEX
    $forcedHumanResult = & $router -ServerRoot $testRoot -TaskPath $forcedHuman.path
    Assert-Equal -Name 'human fail-closed lane' -Actual $forcedHumanResult.lane -Expected 'HUMAN'
    $forcedHumanTask = Get-Content -LiteralPath $forcedHumanResult.destination -Raw | ConvertFrom-Json
    Assert-Equal -Name 'human fail-closed status' -Actual $forcedHumanTask.status -Expected 'REVIEW_REQUIRED'

    $forcedSpecialist = & $newTask -ServerRoot $testRoot -Request 'Open TBC for this job' -AllowedLane CODEX
    $forcedSpecialistResult = & $router -ServerRoot $testRoot -TaskPath $forcedSpecialist.path
    Assert-Equal -Name 'specialist fail-closed lane' -Actual $forcedSpecialistResult.lane -Expected 'HUMAN'

    $inputFile = Join-Path $testRoot 'input.txt'
    Set-Content -LiteralPath $inputFile -Value 'bounded test input' -Encoding UTF8
    $ollamaWithInput = & $newTask -ServerRoot $testRoot -Request 'Summarize this input' -InputPath $inputFile
    $ollamaWithInputResult = & $router -ServerRoot $testRoot -TaskPath $ollamaWithInput.path
    Assert-Equal -Name 'ollama input escalates' -Actual $ollamaWithInputResult.lane -Expected 'CODEX'

    $outsideTask = Join-Path $testRoot 'outside-task.json'
    $outsideSource = & $newTask -ServerRoot $testRoot -Request 'Build a safe test'
    Copy-Item -LiteralPath $outsideSource.path -Destination $outsideTask
    $outsideRejected = $false
    try { $null = & $router -ServerRoot $testRoot -TaskPath $outsideTask } catch { $outsideRejected = $true }
    Assert-True -Name 'out-of-inbox path rejected' -Condition $outsideRejected
    Remove-Item -LiteralPath $outsideTask -Force

    $invalid = & $newTask -ServerRoot $testRoot -Request 'Build a malformed task test'
    $invalidTask = Get-Content -LiteralPath $invalid.path -Raw | ConvertFrom-Json
    $invalidTask.PSObject.Properties.Remove('allowed_lanes')
    $invalidTask | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $invalid.path -Encoding UTF8
    $invalidRejected = $false
    try { $null = & $router -ServerRoot $testRoot -TaskPath $invalid.path } catch { $invalidRejected = $true }
    Assert-True -Name 'invalid task rejected' -Condition $invalidRejected
    Assert-True -Name 'invalid task restored to inbox' -Condition (Test-Path -LiteralPath $invalid.path)
    Remove-Item -LiteralPath $invalid.path -Force

    $dryRunTask = & $newTask -ServerRoot $testRoot -Request 'Build a dry run test'
    $dryRunResult = & $router -ServerRoot $testRoot -TaskPath $dryRunTask.path -DryRun
    Assert-True -Name 'dry run preserves inbox task' -Condition (Test-Path -LiteralPath $dryRunTask.path)
    Assert-Equal -Name 'dry run flag' -Actual $dryRunResult.dry_run -Expected $true
    $null = & $router -ServerRoot $testRoot -TaskPath $dryRunTask.path

    $manifestSource = Join-Path $testRoot 'manifest-source'
    New-Item -ItemType Directory -Path (Join-Path $manifestSource 'nested') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $manifestSource 'alpha.txt') -Value 'alpha' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $manifestSource 'nested\beta.txt') -Value 'beta' -Encoding UTF8
    $manifestPath = Join-Path $manifestSource 'manifest.csv'
    $manifestScript = Join-Path $PSScriptRoot '..\capabilities\New-CertaFileManifest.ps1'
    $manifestResult = & $manifestScript -SourcePath $manifestSource -OutputPath $manifestPath -HashFileLimitMiB 1 -MaxTotalHashMiB 2
    Assert-Equal -Name 'manifest validated' -Actual $manifestResult.status -Expected 'PASS'
    Assert-Equal -Name 'manifest file count' -Actual $manifestResult.file_count -Expected 2
    $manifestResult2 = & $manifestScript -SourcePath $manifestSource -OutputPath $manifestPath -HashFileLimitMiB 1 -MaxTotalHashMiB 2
    Assert-Equal -Name 'manifest self-exclusion' -Actual $manifestResult2.file_count -Expected 2

    Write-Host 'CERTA_ROUTER_TEST_PASS'
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
