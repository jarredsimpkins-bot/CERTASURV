# CertaEvent Engine

CertaEvent is the deterministic event/rule layer behind CertaRD.

**Pipeline:** `EVENT -> RULE -> SCRIPT -> AI IF NEEDED -> ACTION -> VALIDATOR -> RECEIPT`

The first implementation intentionally keeps AI out of the critical path. Folder events and application handoffs are deterministic; AI can be inserted later only for classification/judgment steps.

## What ships now

- Polling watcher designed to survive bulk drops without `FileSystemWatcher` buffer loss.
- Dataset stability gate: a folder does not fire until its metadata signature stops changing for the rule's `stable_seconds`.
- Idempotency: the same dataset signature cannot fire twice.
- Per-action receipts: retries do not repeat actions that already succeeded.
- Persistent event receipts and an append-only office-attention outbox.
- Drone imagery rule: `03_FIELD_WORK\Drone Works\RAW PHOTOS` (underscore variants also accepted) -> WebODM -> office notification -> optional OpenProject comment.
- GNSS, total-station, field-form and field-photo notifications.
- WebODM project/task de-duplication using the SSD project number and deterministic event task name.
- Optional OpenProject work-package comments, auto-resolving the project by SSD identifier/name and the target work package by subject.
- Windows Scheduled Task bootstrap and synthetic self-test.

## Runtime

Installed files live in:

`C:\Certa4010\CertaEvent`

Important paths:

- `config.json` - machine/runtime settings.
- `rules.json` - company automation rules.
- `state\datasets` - dataset signatures and retry state.
- `state\actions` - action idempotency receipts.
- `receipts` - detected/completed/blocked event receipts.
- `outbox\office\attention.ndjson` - append-only office attention stream.
- `logs\certaevent.ndjson` - engine log.

## Relationship to `D:\SERVER`

`C:\Certa4010\CertaEvent` remains the deterministic watcher/action runtime, and `D:\CertaSurv\Projects` plus the approved shared drive remain project evidence roots. `D:\SERVER` is the task-router control plane: inbox, queues, policies, worktrees, model storage, outputs, receipts, and archived intake records. It does not introduce a second authoritative `PROJECTS` tree.

CertaEvent adapters may create validated task JSON in `D:\SERVER\INBOX`. The router then applies the SCRIPT/OLLAMA/CODEX/SPECIALIST/HUMAN policy. Production evidence stays at its approved source path and is referenced rather than copied or overwritten.

## Install

Run PowerShell as Administrator:

```powershell
$u='https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/Install-CertaEvent.ps1'
$p="$env:TEMP\Install-CertaEvent.ps1"
Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $p
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $p -ProjectRoots 'D:\CertaSurv\Projects' -StartNow
```

Pass multiple roots as a PowerShell array if field uploads can land in more than one project tree. If no root is passed, the installer checks the common CertaSurv locations already used by the node and writes the selected roots into `config.json`.

## WebODM credentials

The repository contains no secrets. Set machine-level variables on the server:

```powershell
[Environment]::SetEnvironmentVariable('CERTA_WEBODM_USER','YOUR_WEBODM_USER','Machine')
[Environment]::SetEnvironmentVariable('CERTA_WEBODM_PASSWORD','YOUR_WEBODM_PASSWORD','Machine')
```

The default WebODM URL is `http://127.0.0.1:8000`. Override it with `CERTA_WEBODM_URL` or edit `config.json`.

WebODM currently authenticates through `/api/token-auth/`, uses `Authorization: JWT ...`, creates/reuses a project by SSD number, and submits imagery through `/api/projects/{project_id}/tasks/`.

## OpenProject

OpenProject is disabled in the example config until the local URL/token are set. When ready:

```powershell
[Environment]::SetEnvironmentVariable('CERTA_OPENPROJECT_URL','https://openproject.example','Machine')
[Environment]::SetEnvironmentVariable('CERTA_OPENPROJECT_TOKEN','opapi-REDACTED','Machine')
```

Then set `openproject.enabled` to `true` in `config.json`.

CertaEvent uses OpenProject API v3 bearer-token authentication and posts comments to `/api/v3/work_packages/{id}/activities`. It searches the project collection for an SSD identifier/name, then finds a work package such as `Office Processing`.

A project may override IDs with a `CERTA_PROJECT.json` file:

```json
{
  "openproject": {
    "project_identifier": "ssd-11661-118",
    "work_packages": {
      "Office Processing": 1234
    }
  }
}
```

## Rule behavior

`rules.json` is intentionally data-only. A rule defines:

- the path regex that identifies a dataset folder,
- file extensions,
- minimum file count,
- stable time,
- ordered actions,
- whether an action is required.

A required action failure marks the event `blocked`, creates one office-attention record, and retries later. Succeeded actions are not repeated. A dry run never consumes a dataset signature.

## Next action adapters

The engine is ready for additional deterministic scripts without changing the watcher:

- LiDAR receive -> EZ LAS unzip -> AOI crop -> CloudCompare classification/surface.
- WebODM completed -> download ortho/DSM/DTM -> QGIS project folders.
- Field complete -> unlock Office Processing in OpenProject.
- Draft created -> CertaCAD QC.
- QC passed -> unlock PLS Review.
- PLS approved -> delivery package.
- Twenty WON/NTP -> SSD project provisioner -> OpenProject template.
- AppSheet status/upload -> project event injection.

Each adapter should return exit code `0` only after its validator passes. CertaEvent then writes the receipt.
