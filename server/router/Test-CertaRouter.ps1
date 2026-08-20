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
        validator_path=''
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

    Write-Host 'CERTA_ROUTER_TEST_PASS'
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
