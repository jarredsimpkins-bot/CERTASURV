$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$root = 'C:\Certa4010'
$aiRoot = Join-Path $root 'AI'
$logRoot = Join-Path $root 'Logs'
New-Item -ItemType Directory -Force -Path $aiRoot,$logRoot | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$log = Join-Path $logRoot "gemini_install_$stamp.log"

function Log([string]$Message) {
    "$(Get-Date -Format s) $Message" | Tee-Object -FilePath $log -Append | Write-Host
}

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('PATH','Machine')
    $user = [Environment]::GetEnvironmentVariable('PATH','User')
    $env:PATH = "$machine;$user"
}

function Get-NodeMajor {
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node) { return 0 }
    try {
        $v = (& $node.Source --version).Trim()
        if ($v -match '^v(\d+)\.') { return [int]$Matches[1] }
    } catch {}
    return 0
}

Log "START Gemini CLI install on $env:COMPUTERNAME as $env:USERDOMAIN\$env:USERNAME"
Refresh-Path

$nodeMajor = Get-NodeMajor
if ($nodeMajor -lt 20) {
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'Gemini CLI requires Node.js 20+. Node is missing/old and winget is unavailable.'
    }
    Log "Node.js major version is $nodeMajor; installing/upgrading Node.js LTS."
    & winget.exe install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
    $wingetCode = $LASTEXITCODE
    if ($wingetCode -ne 0) {
        # winget may report an existing package that needs upgrade rather than install.
        Log "winget install returned $wingetCode; attempting upgrade."
        & winget.exe upgrade --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -ne 0) { throw "Node.js LTS install/upgrade failed with exit code $LASTEXITCODE" }
    }
    Refresh-Path
    $nodeMajor = Get-NodeMajor
    if ($nodeMajor -lt 20) { throw 'Node.js 20+ is still not available after installation.' }
}

$nodeVersion = (& node.exe --version).Trim()
$npmVersion = (& npm.cmd --version).Trim()
Log "Node $nodeVersion; npm $npmVersion"

Log 'Installing latest stable @google/gemini-cli globally with npm.'
& npm.cmd install -g '@google/gemini-cli@latest'
if ($LASTEXITCODE -ne 0) { throw "npm install -g @google/gemini-cli@latest failed with exit code $LASTEXITCODE" }
Refresh-Path

$gemini = Get-Command gemini.cmd -ErrorAction SilentlyContinue
if (-not $gemini) { $gemini = Get-Command gemini.exe -ErrorAction SilentlyContinue }
if (-not $gemini) { $gemini = Get-Command gemini -ErrorAction SilentlyContinue }
if (-not $gemini) { throw 'Gemini CLI installed but the gemini command is not on PATH.' }

$version = (& $gemini.Source --version 2>&1 | Out-String).Trim()
if (-not $version) { throw 'Gemini CLI version check returned no output.' }
Log "Gemini CLI version: $version"

$receipt = [ordered]@{
    timestamp = (Get-Date).ToString('o')
    computer = $env:COMPUTERNAME
    user = "$env:USERDOMAIN\$env:USERNAME"
    node = $nodeVersion
    npm = $npmVersion
    gemini = $version
    gemini_command = $gemini.Source
    status = 'INSTALLED'
    authentication = 'PENDING_FIRST_SIGN_IN'
    log = $log
}
$receiptPath = Join-Path $aiRoot 'gemini-receipt.json'
$receipt | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $receiptPath -Encoding UTF8

Log "PASS receipt=$receiptPath"
Write-Host ''
Write-Host 'CERTASURV_GEMINI_INSTALLED' -ForegroundColor Green
Write-Host "Gemini CLI $version is installed." -ForegroundColor Green
Write-Host 'Run: gemini' -ForegroundColor Cyan
Write-Host 'Then choose Sign in with Google. The browser sign-in is required once and credentials are cached locally.' -ForegroundColor Yellow
