$ErrorActionPreference='Stop'

function Log([string]$Message) {
    $line = "$(Get-Date -Format s) $Message"
    $line | Tee-Object -FilePath $script:LogFile -Append
}

function Get-TreeStats([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Files=0; Bytes=0 }
    }
    $items = Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue
    $bytes = ($items | Measure-Object Length -Sum).Sum
    if ($null -eq $bytes) { $bytes = 0 }
    [pscustomobject]@{ Files=@($items).Count; Bytes=[int64]$bytes }
}

# Pick the largest non-C volume >=100 GB so the command is portable across nodes.
$disk = Get-CimInstance Win32_LogicalDisk |
    Where-Object { $_.DeviceID -ne 'C:' -and $_.Size -ge 100GB -and $_.DriveType -in 2,3 } |
    Sort-Object Size -Descending |
    Select-Object -First 1
if (-not $disk) { throw 'No non-C: removable/local volume of at least 100 GB was found.' }

$driveRoot = "$($disk.DeviceID)\"
$root = Join-Path $driveRoot 'CERTASURV_SERVER_HANDOFF'
$legacy = Join-Path $root '01_LEGACY_CODEX'
$reposRoot = Join-Path $root '02_REPOS'
$logs = Join-Path $root '99_LOGS'
New-Item -ItemType Directory -Force -Path $root,$legacy,$reposRoot,$logs | Out-Null

$script:LogFile = Join-Path $logs 'legacy_handoff.log'
$ledgerCsv = Join-Path $logs 'PURGE_LEDGER.csv'
$ledgerJson = Join-Path $logs 'PURGE_LEDGER.json'
$repoList = Join-Path $logs 'REPO_PATHS.txt'

Log "START computer=$env:COMPUTERNAME drive=$($disk.DeviceID) size_gb=$([math]::Round($disk.Size/1GB,1)) free_gb=$([math]::Round($disk.FreeSpace/1GB,1))"

# High-confidence legacy/dev locations only. Active survey/TBC production folders are excluded.
$sources = @(
    [pscustomobject]@{ Path=(Join-Path $env:USERPROFILE '.codex'); Name='USERPROFILE_.codex'; Category='Codex state' },
    [pscustomobject]@{ Path=(Join-Path $env:USERPROFILE 'Documents\ChatGPT'); Name='Documents_ChatGPT'; Category='ChatGPT legacy work' },
    [pscustomobject]@{ Path=(Join-Path $env:USERPROFILE 'Documents\Codex'); Name='Documents_Codex'; Category='Codex work' },
    [pscustomobject]@{ Path=(Join-Path $env:USERPROFILE 'Desktop\Codex'); Name='Desktop_Codex'; Category='Codex work' },
    [pscustomobject]@{ Path='C:\Certa4010'; Name='Certa4010'; Category='CertaNode/CertaShell state' }
)

$ledger = @()
foreach ($s in $sources) {
    if (-not (Test-Path -LiteralPath $s.Path)) {
        Log "SKIP missing $($s.Path)"
        continue
    }

    $dest = Join-Path $legacy $s.Name
    $before = Get-TreeStats $s.Path
    Log "COPY source=$($s.Path) files=$($before.Files) bytes=$($before.Bytes)"

    & robocopy.exe $s.Path $dest /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /XJ /FFT /NP /NFL /NDL /LOG+:$script:LogFile | Out-Null
    $rc = $LASTEXITCODE
    $after = Get-TreeStats $dest

    # Robocopy exit codes 0-7 are success/nonfatal states.
    $copyOk = ($rc -le 7)
    $verified = $copyOk -and ($before.Files -eq $after.Files) -and ($before.Bytes -eq $after.Bytes)
    $safe = if ($verified) { 'YES' } else { 'NO' }

    $ledger += [pscustomobject]@{
        CATEGORY=$s.Category
        SOURCE_PATH=$s.Path
        DESTINATION_PATH=$dest
        SOURCE_FILES=$before.Files
        DEST_FILES=$after.Files
        SOURCE_BYTES=$before.Bytes
        DEST_BYTES=$after.Bytes
        ROBOCOPY_EXIT=$rc
        COPY_OK=$copyOk
        VERIFIED_COUNTS_AND_BYTES=$verified
        SAFE_TO_PURGE=$safe
        COPIED_AT=(Get-Date).ToString('o')
    }
    Log "RESULT source=$($s.Path) rc=$rc verified=$verified safe_to_purge=$safe"
}

# Inventory Git repositories separately so the server can ingest executable history.
$scanRoots = @(
    (Join-Path $env:USERPROFILE 'Documents'),
    (Join-Path $env:USERPROFILE 'Desktop'),
    (Join-Path $env:USERPROFILE 'source'),
    'C:\Certa4010'
) | Where-Object { Test-Path -LiteralPath $_ }

$repoParents = foreach ($r in $scanRoots) {
    Get-ChildItem -LiteralPath $r -Directory -Force -Recurse -Depth 6 -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq '.git' } |
        ForEach-Object { $_.Parent.FullName }
}
$repoParents = @($repoParents | Sort-Object -Unique)
$repoParents | Set-Content -LiteralPath $repoList -Encoding UTF8

$repoIndex = 0
foreach ($repo in $repoParents) {
    $repoIndex++
    $leaf = Split-Path $repo -Leaf
    $dest = Join-Path $reposRoot ("{0:D3}_{1}" -f $repoIndex,$leaf)
    $before = Get-TreeStats $repo
    Log "REPO_COPY source=$repo files=$($before.Files) bytes=$($before.Bytes)"
    & robocopy.exe $repo $dest /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /XJ /FFT /NP /NFL /NDL /LOG+:$script:LogFile | Out-Null
    $rc = $LASTEXITCODE
    $after = Get-TreeStats $dest
    $copyOk = ($rc -le 7)
    $verified = $copyOk -and ($before.Files -eq $after.Files) -and ($before.Bytes -eq $after.Bytes)
    $safe = if ($verified) { 'YES' } else { 'NO' }
    $ledger += [pscustomobject]@{
        CATEGORY='Git repository'
        SOURCE_PATH=$repo
        DESTINATION_PATH=$dest
        SOURCE_FILES=$before.Files
        DEST_FILES=$after.Files
        SOURCE_BYTES=$before.Bytes
        DEST_BYTES=$after.Bytes
        ROBOCOPY_EXIT=$rc
        COPY_OK=$copyOk
        VERIFIED_COUNTS_AND_BYTES=$verified
        SAFE_TO_PURGE=$safe
        COPIED_AT=(Get-Date).ToString('o')
    }
    Log "REPO_RESULT source=$repo rc=$rc verified=$verified safe_to_purge=$safe"
}

$ledger | Export-Csv -LiteralPath $ledgerCsv -NoTypeInformation -Encoding UTF8
$ledger | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ledgerJson -Encoding UTF8

$summary = [ordered]@{
    completed_at=(Get-Date).ToString('o')
    computer=$env:COMPUTERNAME
    destination_root=$root
    drive=$disk.DeviceID
    source_entries=@($ledger).Count
    verified_entries=@($ledger | Where-Object SAFE_TO_PURGE -eq 'YES').Count
    unsafe_entries=@($ledger | Where-Object SAFE_TO_PURGE -ne 'YES').Count
    total_source_bytes=[int64](($ledger | Measure-Object SOURCE_BYTES -Sum).Sum)
    total_source_gb=[math]::Round((($ledger | Measure-Object SOURCE_BYTES -Sum).Sum)/1GB,3)
    purge_ledger_csv=$ledgerCsv
    purge_ledger_json=$ledgerJson
}
$summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $logs 'HANDOFF_SUMMARY.json') -Encoding UTF8
Log "DONE entries=$($summary.source_entries) verified=$($summary.verified_entries) unsafe=$($summary.unsafe_entries) total_gb=$($summary.total_source_gb)"
Write-Output "CERTANODE_LEGACY_HANDOFF_COMPLETE $root"
