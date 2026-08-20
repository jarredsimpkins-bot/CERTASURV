# CertaSurv Production Capabilities v1

This package advances `D:\SERVER` from task classification into useful deterministic production work while preserving CertaSurv evidence and professional authority.

## Installed verified capabilities

### `project-intake-v1`

Creates or repairs the SSD project structure, project manifest, source registry, missing-requirements report, and receipt. Original inputs are never deleted. Files are copied into project evidence only when they already reside under the governed server staging/inbox roots.

### `courthouse-packet-v1`

Creates parcel research folders and produces:

- `PARCEL_REGISTER.csv`
- `MASTER_RESEARCH_LOG.csv`
- `COURTHOUSE_SOURCE_REGISTER.csv`
- `CHAIN_OF_TITLE.csv`
- `PLOT_SOURCE_GATE.csv`
- `RESEARCH_GAPS.csv`
- `COURTHOUSE_PACKET.json`

A deed or plat filename creates only a candidate source. The script never marks a parcel plot-ready without review.

### `deed-plot-v1`

Reads a structured calls CSV with `Bearing` and `Distance` (or chord-bearing/chord-distance) and creates:

- computed raw calls;
- PNEZD points;
- raw R12-compatible DXF;
- SVG preview;
- raw closure and area report;
- warnings and execution receipt.

The geometry is raw and unadjusted. Curve-only rows are rejected instead of being invented.

### `workmap-build-v1`

Reads a point CSV using common CertaSurv/PNEZD headings and creates:

- normalized points;
- `CONTROL.csv`;
- `FIELD.csv`;
- `STAKEOUT.csv`;
- field-action register;
- DXF;
- SVG preview;
- KML only when real latitude/longitude columns exist;
- package manifest.

Status rules are green SEARCH, red FOUND, blue SET, orange CONTROL, and grey EXTRACT. A request such as `F300-F378 label overlay` outputs only that F range and does not add vectors, leaders, or unrelated point families.

### `field-return-v1`

Combines a current point/workmap CSV with a field-return CSV without overwriting either source. It preserves unique point-event records, builds current point state, computes candidate search-to-found/set proximity, lists unresolved stakeout, regenerates the workmap, and writes a receipt.

## Install the complete canary

Run from elevated PowerShell while this branch is under review:

```powershell
$p = "$env:TEMP\Install-CertaSurvProductionServer.ps1"

Invoke-WebRequest -UseBasicParsing `
  "https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/feat/certa-server-router-v1/bootstrap/Install-CertaSurvProductionServer-FromGitHub.ps1" `
  -OutFile $p

powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File $p `
  -ServerRoot "D:\SERVER" `
  -Ref "feat/certa-server-router-v1"
```

After the branch is merged, use `-Ref main` or omit `-Ref`.

## Task examples

```powershell
# Project intake
& 'D:\SERVER\ROUTER\New-CertaTask.ps1' `
  -ProjectId 'SSD-11661-118' `
  -Request 'Create governed project intake' `
  -InputPath 'D:\SERVER\STAGING\SSD-11661-118'

# Courthouse packet
& 'D:\SERVER\ROUTER\New-CertaTask.ps1' `
  -ProjectId 'SSD-11661-118' `
  -Request 'Build courthouse research packet and plot source gate' `
  -InputPath 'D:\SERVER\STAGING\SSD-11661-118\COURTHOUSE'

# Deed plot
& 'D:\SERVER\ROUTER\New-CertaTask.ps1' `
  -ProjectId 'SSD-11661-118' `
  -Request 'Create raw deed auto plot and closure report' `
  -InputPath 'D:\SERVER\STAGING\SSD-11661-118\calls.csv'

# Workmap
& 'D:\SERVER\ROUTER\New-CertaTask.ps1' `
  -ProjectId 'SSD-11661-118' `
  -Request 'Build workmap package' `
  -InputPath 'D:\SERVER\STAGING\SSD-11661-118\points.csv'

# F-series overlay
& 'D:\SERVER\ROUTER\New-CertaTask.ps1' `
  -ProjectId 'SSD-11661-118' `
  -Request 'Create F300-F378 label overlay only' `
  -InputPath 'D:\SERVER\STAGING\SSD-11661-118\points.csv'

# Field return
& 'D:\SERVER\ROUTER\New-CertaTask.ps1' `
  -ProjectId 'SSD-11661-118' `
  -Request 'Ingest field return with tolerance 5 ft and update workmap' `
  -InputPath @(
      'D:\SERVER\PROJECTS\SSD-11661-118\03_FIELD_WORK\WORKMAPS\current\WORKMAP_POINTS.csv',
      'D:\SERVER\STAGING\SSD-11661-118\field-return.csv'
  )

# Route and execute SCRIPT/OLLAMA queues
& 'D:\SERVER\ROUTER\Invoke-CertaQueueWorker.ps1' -ServerRoot 'D:\SERVER'
```

## What remains specialist or review work

- County IDX/browser capture that needs credentials or interactive navigation.
- OCR verification against deed/plat page images.
- Curves and ambiguous legal calls not supplied as verified chords.
- Orthophoto/LiDAR road and drain extraction.
- TBC/Land Desktop/CAD operations on MSI.
- Final boundary, legal, contractual, destructive, credential, and production-release decisions.

Those tasks remain routed to Ollama, Codex, an approved specialist node, or human/PLS review rather than being silently automated.
