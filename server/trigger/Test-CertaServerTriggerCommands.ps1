#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Expand-TestItems {
    param([AllowNull()]$Value)

    $result = New-Object System.Collections.Generic.List[object]
    if ($null -eq $Value) { return @() }

    if ($Value -is [System.Array]) {
        foreach ($item in $Value) {
            foreach ($expanded in @(Expand-TestItems -Value $item)) {
                $result.Add($expanded)
            }
        }
    }
    else {
        $result.Add($Value)
    }

    return @($result)
}

function Get-TestProperty {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

$tempRoot = Join-Path $env:TEMP ('certa-trigger-test-' + [guid]::NewGuid().ToString('N'))
$fakeProfile = Join-Path $tempRoot 'profile'
$commandsDir = Join-Path $fakeProfile '.TRIGGERcmdData'
$commandsPath = Join-Path $commandsDir 'commands.json'
$serverRoot = Join-Path $tempRoot 'server'
$originalProfile = $env:USERPROFILE

try {
    New-Item -ItemType Directory -Path $commandsDir,$serverRoot -Force | Out-Null

    @'
[
  {
    "trigger": "Calculator",
    "command": "calc",
    "offCommand": "",
    "ground": "foreground",
    "voice": "calculator",
    "voiceReply": "",
    "allowParams": "true"
  },
  [
    {
      "trigger": "Notepad",
      "command": "notepad",
      "offCommand": "",
      "ground": "foreground",
      "voice": "notepad",
      "voiceReply": "",
      "allowParams": "true"
    }
  ],
  {
    "note": "This malformed metadata object reproduces the missing-trigger failure."
  },
  null
]
'@ | Set-Content -LiteralPath $commandsPath -Encoding UTF8

    $env:USERPROFILE = $fakeProfile
    $installer = Join-Path $PSScriptRoot 'Install-CertaServer-TriggerCommands.ps1'
    $result = & $installer -ServerRoot $serverRoot

    if ([string]$result.status -ne 'PASS') {
        throw 'Trigger installer did not return PASS.'
    }

    $parsed = Get-Content -LiteralPath $commandsPath -Raw | ConvertFrom-Json
    $items = @(Expand-TestItems -Value $parsed)
    $names = @($items | ForEach-Object { [string](Get-TestProperty -Object $_ -Name 'trigger') })

    foreach ($required in @(
        'Calculator',
        'Notepad',
        'Certa Server Health',
        'Certa Server Route Once',
        'Certa Server Route All',
        'Certa Ollama Status',
        'Certa Open Server'
    )) {
        $count = @($names | Where-Object { $_ -eq $required }).Count
        if ($count -ne 1) {
            throw "Expected exactly one '$required' command, found $count."
        }
    }

    foreach ($item in $items) {
        $name = [string](Get-TestProperty -Object $item -Name 'trigger')
        $command = [string](Get-TestProperty -Object $item -Name 'command')
        if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($command)) {
            throw 'Normalized commands file still contains an invalid command entry.'
        }
    }

    foreach ($serverCommand in @(
        'Certa Server Health',
        'Certa Server Route Once',
        'Certa Server Route All',
        'Certa Ollama Status',
        'Certa Open Server'
    )) {
        $entry = $items | Where-Object {
            [string](Get-TestProperty -Object $_ -Name 'trigger') -eq $serverCommand
        } | Select-Object -First 1

        if ([string](Get-TestProperty -Object $entry -Name 'allowParams') -ne 'false') {
            throw "Server command unexpectedly allows parameters: $serverCommand"
        }
    }

    if ([int]$result.invalid_entries_removed -lt 1) {
        throw 'Malformed fixture entry was not reported as removed.'
    }

    if ([string]::IsNullOrWhiteSpace([string]$result.invalid_entries_backup) -or
        -not (Test-Path -LiteralPath ([string]$result.invalid_entries_backup))) {
        throw 'Malformed command entry backup was not created.'
    }

    'CERTA_TRIGGER_COMMAND_TEST_PASS'
}
finally {
    $env:USERPROFILE = $originalProfile
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
