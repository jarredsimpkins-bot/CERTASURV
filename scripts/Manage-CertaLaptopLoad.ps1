param(
    [ValidateSet('Auto', 'Production', 'Throttle', 'Critical')]
    [string]$Mode = 'Auto',
    [switch]$Aggressive,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'

$balancedScheme = '381b4222-f694-41f0-9685-ff5bb260df2e'
$highPerformanceScheme = 'fca62ebf-1e83-4ae4-b3b0-4742360d4bda'
$highPerformanceTemplate = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
$protectedTitle = 'TBC|Trimble'
$protectedProcesses = 'Trimble|Tbc'

function Set-SafePriority {
    param(
        [System.Diagnostics.Process]$Process,
        [string]$Priority,
        [string]$Rule
    )

    $oldPriority = 'Unknown'
    $newPriority = 'Unknown'
    $status = 'OK'

    try { $oldPriority = [string]$Process.PriorityClass } catch { }

    try {
        $Process.PriorityClass = $Priority
        $newPriority = [string]$Process.PriorityClass
    }
    catch {
        $status = $_.Exception.Message
    }

    [pscustomobject]@{
        Process = $Process.ProcessName
        Id = $Process.Id
        Old = $oldPriority
        New = $newPriority
        Rule = $Rule
        Status = $status
        Title = $Process.MainWindowTitle
    }
}

$changes = @()

$tbcActive = $false
try {
    $tbcActive = [bool](Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -match $protectedProcesses -or $_.MainWindowTitle -match $protectedTitle } |
        Select-Object -First 1)
}
catch {
    $tbcActive = $false
}

$effectiveMode = if ($Mode -eq 'Auto') {
    if ($tbcActive) { 'TbcProtected' } else { 'Production' }
}
else {
    $Mode
}

function Enable-ProductionPower {
    $schemeToUse = $highPerformanceScheme
    $schemes = powercfg /list

    if ($schemes -match $highPerformanceScheme) {
        $schemeToUse = $highPerformanceScheme
    }
    elseif ($schemes -match 'Power Scheme GUID:\s+([0-9a-fA-F-]{36})\s+\(High performance\)') {
        $schemeToUse = $matches[1]
    }
    else {
        try {
            $created = powercfg /duplicatescheme $highPerformanceTemplate
            if ($created -match '([0-9a-fA-F-]{36})') {
                $schemeToUse = $matches[1]
                powercfg /changename $schemeToUse 'High performance' 'CERTA production key power plan' | Out-Null
            }
        }
        catch {
            $schemeToUse = $highPerformanceTemplate
        }
    }

    powercfg /setactive $schemeToUse | Out-Null
    powercfg /setacvalueindex $schemeToUse SUB_PROCESSOR PROCTHROTTLEMIN 5 | Out-Null
    powercfg /setdcvalueindex $schemeToUse SUB_PROCESSOR PROCTHROTTLEMIN 5 | Out-Null
    powercfg /setacvalueindex $schemeToUse SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
    powercfg /setdcvalueindex $schemeToUse SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
    powercfg /setactive $schemeToUse | Out-Null
}

function Enable-ThrottlePower {
    param(
        [int]$AcMax,
        [int]$DcMax
    )

    powercfg /setactive $balancedScheme | Out-Null
    powercfg /setacvalueindex $balancedScheme SUB_PROCESSOR PROCTHROTTLEMIN 5 | Out-Null
    powercfg /setdcvalueindex $balancedScheme SUB_PROCESSOR PROCTHROTTLEMIN 5 | Out-Null
    powercfg /setacvalueindex $balancedScheme SUB_PROCESSOR PROCTHROTTLEMAX $AcMax | Out-Null
    powercfg /setdcvalueindex $balancedScheme SUB_PROCESSOR PROCTHROTTLEMAX $DcMax | Out-Null
    powercfg /setactive $balancedScheme | Out-Null
}

switch ($effectiveMode) {
    'Production' { Enable-ProductionPower }
    'TbcProtected' { Enable-ProductionPower }
    'Throttle' { Enable-ThrottlePower -AcMax 85 -DcMax 70 }
    'Critical' { Enable-ThrottlePower -AcMax 75 -DcMax 60 }
}

# Protect TBC/Trimble production first.
$seenProtected = @{}
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -match $protectedProcesses -or $_.MainWindowTitle -match $protectedTitle } |
    ForEach-Object {
        if ($seenProtected.ContainsKey($_.Id)) { return }
        $seenProtected[$_.Id] = $true
        $target = if ($_.ProcessName -match 'Trimble\.WorkerService\.Tbc') { 'High' } else { 'Normal' }
        $changes += Set-SafePriority -Process $_ -Priority $target -Rule 'protected-production'
    }

# Put browser helper/render processes in the back seat. Keep the visible TBC dashboard responsive.
$seenBrowsers = @{}
Get-Process -Name msedge,chrome,firefox,brave,opera -ErrorAction SilentlyContinue |
    ForEach-Object {
        if ($seenBrowsers.ContainsKey($_.Id)) { return }
        $seenBrowsers[$_.Id] = $true
        if ($_.MainWindowTitle -match $protectedTitle) {
            $changes += Set-SafePriority -Process $_ -Priority 'Normal' -Rule 'protected-browser'
        }
        elseif ($_.MainWindowTitle) {
            $changes += Set-SafePriority -Process $_ -Priority 'BelowNormal' -Rule 'visible-browser'
        }
        else {
            $changes += Set-SafePriority -Process $_ -Priority 'Idle' -Rule 'background-browser'
        }
}

# TBC Python helpers do useful work, but they should not monopolize the laptop.
$pythonCommands = @{}
Get-CimInstance Win32_Process -Filter "Name = 'python.exe'" -ErrorAction SilentlyContinue |
    ForEach-Object { $pythonCommands[[int]$_.ProcessId] = [string]$_.CommandLine }

Get-Process -Name python -ErrorAction SilentlyContinue |
    ForEach-Object {
        $commandLine = $pythonCommands[$_.Id]
        if ($commandLine -match 'TBC-Control-Dashboard\.py') {
            $changes += Set-SafePriority -Process $_ -Priority 'Normal' -Rule 'protected-tbc-python'
        }
        elseif ($commandLine -match 'TBC|Trimble|Workflow|Recorder') {
            $changes += Set-SafePriority -Process $_ -Priority 'BelowNormal' -Rule 'quiet-tbc-python'
        }
        else {
            $changes += Set-SafePriority -Process $_ -Priority 'BelowNormal' -Rule 'quiet-python'
        }
    }

# Quiet common non-production helpers without stopping them.
$backgroundNames = @(
    'msedgewebview2',
    'mscopilot',
    'RazerAppEngine',
    'RazerAppEngineService',
    'CefSharp.BrowserSubprocess',
    'OneDrive.Sync.Service',
    'codex',
    'Codex',
    'DCv2'
 ) | Sort-Object -Unique

foreach ($name in $backgroundNames) {
    $seenBackground = @{}
    Get-Process -Name $name -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -notmatch $protectedProcesses -and $_.MainWindowTitle -notmatch $protectedTitle } |
        ForEach-Object {
            if ($seenBackground.ContainsKey($_.Id)) { return }
            $seenBackground[$_.Id] = $true
            $target = if ($effectiveMode -eq 'TbcProtected' -or $_.ProcessName -eq 'mscopilot') { 'Idle' } else { 'BelowNormal' }
            $changes += Set-SafePriority -Process $_ -Priority $target -Rule 'quiet-background'
        }
}

if ($effectiveMode -eq 'Production') {
    # When TBC is not active, let local development helpers run with more room.
    Get-Process -Name codex,Codex,node,node_repl,python,powershell -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -notmatch $protectedTitle } |
        ForEach-Object {
            $target = if ($_.ProcessName -match 'node_repl') { 'BelowNormal' } else { 'Normal' }
            $changes += Set-SafePriority -Process $_ -Priority $target -Rule 'local-production-boost'
        }
}

if ($Aggressive) {
    # Close only obvious non-production app windows. This intentionally avoids browsers, Notepad, TBC, and Trimble.
    Get-Process -Name mscopilot -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -notmatch $protectedTitle } |
        ForEach-Object {
            $closed = $false
            try { $closed = $_.CloseMainWindow() } catch { }
            $changes += [pscustomobject]@{
                Process = $_.ProcessName
                Id = $_.Id
                Old = 'WindowOpen'
                New = if ($closed) { 'CloseRequested' } else { 'Unchanged' }
                Rule = 'aggressive-close'
                Status = if ($closed) { 'OK' } else { 'Close not accepted' }
                Title = $_.MainWindowTitle
            }
        }
}

if (-not $Quiet) {
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1
    $mem = Get-Counter '\Memory\Available MBytes' -SampleInterval 1 -MaxSamples 1

    [pscustomobject]@{
        PowerPlan = (powercfg /getactivescheme)
        Mode = $Mode
        EffectiveMode = $effectiveMode
        TbcActive = $tbcActive
        CpuPercent = [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
        AvailableMB = [math]::Round($mem.CounterSamples[0].CookedValue, 0)
        Changes = $changes.Count
    } | Format-List

    $changes |
        Sort-Object Rule,Process,Id |
        Select-Object Process,Id,Old,New,Rule,Status,Title |
        Format-Table -AutoSize
}
