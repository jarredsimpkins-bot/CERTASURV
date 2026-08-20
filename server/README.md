# CertaSurv Server Router v1

This is the first operational layer that turns `D:\SERVER` into the primary CertaSurv task intake and routing location. It is a control-plane/runtime root, not a second project system of record. Production evidence remains in the approved shared-drive or `D:\CertaSurv\Projects` roots and is referenced through task inputs or `D:\SERVER\PROJECT_LINKS`.

## What it does

Every task enters `D:\SERVER\INBOX` and is routed into one of five lanes:

1. **SCRIPT** — a verified deterministic capability already exists.
2. **OLLAMA** — low-risk local classification, extraction, summarization, tagging, or explanation.
3. **CODEX** — new code, debugging, integration, migration, tests, or repository changes are required.
4. **SPECIALIST** — TBC, Land Desktop, CAD, CloudCompare, WebODM, or another licensed/hardware-specific node is required.
5. **HUMAN** — professional survey judgment, legal authority, credentials, destructive work, or production release is required.

The router does not convert arbitrary natural-language text into unrestricted shell commands. It validates each task, atomically claims it from the inbox, writes routed task records and receipts, and archives the original intake record. Human-risk terms fail closed even when the task tries to disallow the HUMAN lane. The local Ollama lane produces candidate-only responses and does not ingest file inputs in v1; input-bearing Ollama requests escalate to CODEX or HUMAN.

## Install from a repository checkout

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\server\Install-CertaServer.ps1 `
  -ServerRoot D:\SERVER `
  -PullModel `
  -InstallTriggerCommands `
  -DisableSleepOnAC `
  -RunSmokeTest
```

## One-line bootstrap after merge

```powershell
$p = Join-Path $env:TEMP 'Install-CertaServer.ps1'
Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/Install-CertaServer-FromGitHub.ps1' -OutFile $p
& $p -PullModel -InstallTriggerCommands -DisableSleepOnAC -RunSmokeTest
```

The bootstrap resolves `main` (or another requested ref) to one immutable commit before downloading the installer set, and the installed manifest records that source commit.

Ollama remains bound to `127.0.0.1:11434`, disables Ollama cloud features, uses one loaded model and one parallel request, and stores models under the selected server root (by default `D:\SERVER\OLLAMA\models`).

## Create and route a task

```powershell
$task = & D:\SERVER\ROUTER\New-CertaTask.ps1 `
  -Request 'Build a PowerShell importer with tests' `
  -ProjectId 'SSD-XXXXX-XXX'

& D:\SERVER\ROUTER\Invoke-CertaRouter.ps1 -TaskPath $task.path
```

For a low-risk Ollama task:

```powershell
$task = & D:\SERVER\ROUTER\New-CertaTask.ps1 -Request 'Summarize and classify these intake notes'
& D:\SERVER\ROUTER\Invoke-CertaRouter.ps1 -TaskPath $task.path
$ollamaTask = Get-ChildItem D:\SERVER\QUEUE\ollama\*.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1
& D:\SERVER\ROUTER\Invoke-CertaOllamaTask.ps1 -TaskPath $ollamaTask.FullName
```

## Trigger commands

The installer adds only named commands with parameters disabled:

- `Certa Server Health`
- `Certa Server Smoke Test`
- `Certa Beacon Refresh`
- `Certa Server Route Once`
- `Certa Server Route All`
- `Certa Ollama Status`
- `Certa Open Server`

The installer updates `commands.json` through a shared writer lock and an atomic, hash-verified replacement, preserves a timestamped backup, and signals the running foreground agent's file watcher without killing or duplicating the agent. Installing the remote commands requires `-RunSmokeTest`. A changed remotely listed beacon is the catalog-sync proof. These commands require the same Windows profile and an interactive foreground-agent session; unattended operation before sign-in is not delivered by v1.

`Certa Beacon Refresh` publishes one coarse, no-op command name such as `Certa Beacon H-PASS S-PASS U-20260820T095455Z R-A1B2C3D4`. Only health/smoke enums, UTC time, and a random run ID enter the TRIGGERcmd catalog; detailed findings remain in local receipts. `S-PASS` requires a complete evidence-bound smoke run no more than 15 minutes old. `INIT`, `RUNNING`, `STALE`, `ERROR`, or `FAIL` is not green. A remote check is current only when refresh produces exactly one valid beacon with a changed run ID. Never use a beacon to authorize destructive work, credentials, survey judgment, or production release.

`Certa Server Smoke Test` is synthetic and repeat-safe. It creates a unique no-input task, proves natural policy routing to OLLAMA, requires the local model to return a unique nonce, validates routing/execution receipts and task history, and moves the completed task from the live queue into `ARCHIVE\smoke\passed` or `ARCHIVE\smoke\failed`.

The installer preserves unrelated valid TRIGGERcmd entries but health fails if any retained entry allows remote parameters. Review every retained command before treating the whole Windows profile as safe; the installer guarantees that the seven Certa server commands and its beacon are fixed, parameter-free, and have no off-action.

## Execution boundary

This v1 router classifies and queues all five lanes. The Ollama queue has a manual candidate executor. SCRIPT, CODEX, SPECIALIST, and HUMAN remain controlled handoff queues until dedicated workers/adapters are added; routing a task does not mean that downstream work ran.

`STAGING\router` contains atomically claimed work. A healthy server has no stranded JSON tasks there. Original inbox records are retained in `ARCHIVE\tasks` after successful routing.

## Target-PC validation

Before production cutover:

1. Run the installer against the existing `D:\SERVER` and confirm unrelated content is unchanged.
2. Confirm `certard-local` is present, `OLLAMA_MODELS` points at `D:\SERVER\OLLAMA\models`, cloud use is disabled, and port 11434 has no wildcard listener.
3. Confirm all seven fixed TRIGGERcmd commands appear on the intended PC with parameters disabled and execute from a remote trigger.
4. Run `Certa Server Smoke Test`, then `Certa Beacon Refresh`; require one fresh `H-PASS S-PASS` beacon with a changed run ID.
5. Reboot, sign into the dedicated Windows profile, run `Certa Server Smoke Test` again, then refresh the beacon and require another fresh `H-PASS S-PASS` result with a changed run ID.
6. Route one controlled test through each remaining handoff lane and retain its routing receipt and archived intake record.

## Safety and authority

- Original project evidence remains in its approved source system.
- `D:\SERVER` contains control state, queues, worktrees, outputs, and receipts; it does not replace the approved project system of record.
- AI output is candidate information until validated.
- A verified script is preferred over a model.
- Codex builds new capabilities; repeated successful patterns can later be promoted to tested scripts.
- Boundary, legal, credential, destructive, and release decisions remain human/PLS/admin gates.
- Ollama is not exposed to the office LAN.
- Ollama cloud features are disabled for the server profile.
- This installer adds no unrestricted Trigger shell; retained pre-existing commands still require explicit review.
