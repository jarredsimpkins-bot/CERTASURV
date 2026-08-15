$ErrorActionPreference='Stop'
$url='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/START-CERTASURV-NODE-OFFLOAD.cmd'
$drives=@()
try {
  $drives=Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveLetter -ne 'C' -and $_.FileSystem } | ForEach-Object {
    $root="$($_.DriveLetter):\"
    $probe=Join-Path $root '.certasurv_probe'
    try {
      'x' | Set-Content -LiteralPath $probe -Encoding ASCII -ErrorAction Stop
      Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
      [pscustomobject]@{Drive=$_.DriveLetter;Root=$root;Label=$_.FileSystemLabel;Size=$_.Size;Free=$_.SizeRemaining}
    } catch {}
  }
} catch {}
if(-not $drives){throw 'No writable non-C volumes found.'}
foreach($d in $drives){
  $dest=Join-Path $d.Root 'START-CERTASURV-NODE-OFFLOAD.cmd'
  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $dest
  $note=@"
CERTASURV PORTABLE NODE OFFLOAD
Run START-CERTASURV-NODE-OFFLOAD.cmd on a Windows workstation to collect only curated skills, agents, workflows, scripts, repos/config, and limited durable knowledge.
Live CAD/runtime/project data is not intended for purge.
"@
  $note | Set-Content -LiteralPath (Join-Path $d.Root 'README-CERTASURV-OFFLOAD.txt') -Encoding UTF8
  Write-Host ("SEEDED {0}:  {1}  Free {2:N1} GB" -f $d.Drive,$d.Label,($d.Free/1GB))
}
