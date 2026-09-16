$ErrorActionPreference = 'Stop'

$root = 'C:\Certa4010'
$aiRoot = Join-Path $root 'AI'
$logRoot = Join-Path $root 'Logs'
New-Item -ItemType Directory -Force -Path $aiRoot,$logRoot | Out-Null
$log = Join-Path $logRoot ("openrouter_install_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

function Log([string]$Message) {
    "$(Get-Date -Format s) $Message" | Tee-Object -FilePath $log -Append
}

function Get-PythonCommand {
    if (Get-Command py.exe -ErrorAction SilentlyContinue) {
        return @('py.exe','-3')
    }
    if (Get-Command python.exe -ErrorAction SilentlyContinue) {
        return @('python.exe')
    }
    return $null
}

Log 'Starting CertaSurv OpenRouter bootstrap.'

$python = Get-PythonCommand
if (-not $python) {
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'Python 3.9+ is required and winget is not available. Install Python, then rerun this script.'
    }

    Log 'Python not found. Installing Python with winget.'
    & winget.exe install --id Python.Python.3.13 -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "Python installation failed with exit code $LASTEXITCODE" }

    $env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH','User')
    $python = Get-PythonCommand
    if (-not $python) { throw 'Python was installed but is not available in this session. Open a new PowerShell window and rerun.' }
}

$pythonExe = $python[0]
$pythonPrefix = @()
if ($python.Count -gt 1) { $pythonPrefix = $python[1..($python.Count-1)] }

Log 'Installing/upgrading the official OpenRouter Python SDK.'
& $pythonExe @pythonPrefix -m pip install --upgrade openrouter
if ($LASTEXITCODE -ne 0) { throw "pip install openrouter failed with exit code $LASTEXITCODE" }

$testScript = @'
import os
import sys
from openrouter import OpenRouter

api_key = os.getenv("OPENROUTER_API_KEY")
if not api_key:
    print("OPENROUTER_KEY_MISSING")
    sys.exit(20)

with OpenRouter(api_key=api_key) as client:
    response = client.chat.send(
        model="openrouter/free",
        messages=[
            {
                "role": "user",
                "content": "Reply with exactly: CERTASURV_OPENROUTER_OK"
            }
        ],
        stream=False,
    )

text = response.choices[0].message.content if response.choices else None
print(text)
if text and "CERTASURV_OPENROUTER_OK" in text:
    sys.exit(0)
sys.exit(21)
'@

$testPath = Join-Path $aiRoot 'test_openrouter.py'
Set-Content -LiteralPath $testPath -Value $testScript -Encoding UTF8

$key = [Environment]::GetEnvironmentVariable('OPENROUTER_API_KEY','Machine')
if (-not $key) { $key = [Environment]::GetEnvironmentVariable('OPENROUTER_API_KEY','User') }
if (-not $key) { $key = $env:OPENROUTER_API_KEY }

if (-not $key) {
    Log 'SDK installed. No local OpenRouter key found. Requesting a replacement key securely.'
    Write-Host ''
    Write-Host 'OpenRouter SDK installed.' -ForegroundColor Green
    Write-Host 'Paste a FRESH replacement OpenRouter API key below. Input is masked and the key is never written to GitHub or the install log.' -ForegroundColor Yellow
    $secureKey = Read-Host 'OpenRouter API key' -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    try {
        $key = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
    if ([string]::IsNullOrWhiteSpace($key)) { throw 'No OpenRouter API key was entered.' }
    [Environment]::SetEnvironmentVariable('OPENROUTER_API_KEY',$key,'User')
    Log 'OpenRouter key saved to the Windows user environment. Key value was not logged.'
}

$env:OPENROUTER_API_KEY = $key
Log 'Running zero-cost OpenRouter free-router smoke test.'
& $pythonExe @pythonPrefix $testPath
$code = $LASTEXITCODE

if ($code -eq 0) {
    $receipt = [ordered]@{
        timestamp = (Get-Date).ToString('o')
        computer = $env:COMPUTERNAME
        user = "$env:USERDOMAIN\$env:USERNAME"
        sdk = 'openrouter-python'
        model = 'openrouter/free'
        status = 'PASS'
        test_script = $testPath
        log = $log
    }
    $receipt | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $aiRoot 'openrouter-receipt.json') -Encoding UTF8
    Log 'OpenRouter smoke test PASS.'
    Write-Host 'CERTASURV_OPENROUTER_PASS' -ForegroundColor Green
    exit 0
}

Log "OpenRouter smoke test FAILED with exit code $code."
throw "OpenRouter smoke test failed with exit code $code. See $log"
