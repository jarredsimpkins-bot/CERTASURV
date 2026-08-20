# CertaSurv Server Router — Autonomy v2

`D:\SERVER` is the primary CertaSurv work intake, routing, repository, worktree, processing, output, and receipt location.

## Routing lanes

Every task enters `D:\SERVER\INBOX` and routes to one primary lane:

1. **SCRIPT** — a verified deterministic capability already exists.
2. **OLLAMA** — low-risk local classification, extraction, summarization, tagging, or explanation.
3. **CODEX** — new code, debugging, integration, migration, tests, or repository changes are required.
4. **SPECIALIST** — TBC, Land Desktop, CAD, CloudCompare, WebODM, or another licensed/hardware-specific node is required.
5. **HUMAN** — professional survey judgment, legal authority, credentials, destructive work, or production release is required.

SCRIPT and OLLAMA are eligible for the safe automatic worker. CODEX requires an explicit operator/Trigger action. SPECIALIST and HUMAN remain queued for controlled handoff.

## Install from a repository checkout

Run under the Windows profile that owns Ollama, Codex, and the TRIGGERcmd foreground agent:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap\Install-CertaServer-AutonomyV2.ps1 `
  -ServerRoot D:\SERVER `
  -PullModel `
  -InstallTriggerCommands `
  -InstallScheduledTasks `
  -CloneControlRepo `
  -DisableSleepOnAC
```

The installer:

- creates/reconciles the governed `D:\SERVER` tree;
- preserves and verifies an existing Ollama model store before switching paths;
- binds Ollama to `127.0.0.1:11434`;
- sets one loaded model and one parallel request;
- creates the `certard-local` low-authority worker;
- installs safe Trigger actions;
- installs a safe queue worker at logon and every five minutes;
- runs router and deterministic-capability self-tests;
- writes manifests, health records, and receipts.

It does not delete the former model store or `D:\CERTASURV_SERVER`.

## One-line bootstrap after merge

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/Install-CertaServer-AutonomyV2.ps1 -OutFile $env:TEMP\Install-CertaServer-AutonomyV2.ps1; & $env:TEMP\Install-CertaServer-AutonomyV2.ps1 -PullModel -InstallTriggerCommands -InstallScheduledTasks -CloneControlRepo -DisableSleepOnAC"
```

Use `ollama signin` separately for Ollama Pro/cloud access. Never paste an API key into the scripts.

## Create and route a script task

```powershell
$task = & D:\SERVER\ROUTER\New-CertaTask.ps1 `
  -Request 'Create a checksum manifest for this folder' `
  -InputPath 'D:\SERVER\STAGING\sample'

& D:\SERVER\ROUTER\Invoke-CertaRouter.ps1 -TaskPath $task.path
& D:\SERVER\ROUTER\Invoke-CertaQueue.ps1 -OnlyLane SCRIPT -MaxTasks 1 -SkipRouting
```

## Create and route an Ollama task

```powershell
$task = & D:\SERVER\ROUTER\New-CertaTask.ps1 `
  -Request 'Summarize and classify these intake notes'

& D:\SERVER\ROUTER\Invoke-CertaRouter.ps1 -TaskPath $task.path
& D:\SERVER\ROUTER\Invoke-CertaQueue.ps1 -OnlyLane OLLAMA -MaxTasks 1 -SkipRouting
```

Ollama outputs are always `CANDIDATE_COMPLETE`, not authoritative.

## Create and explicitly run a Codex task

The workspace must be a Git repository/worktree under `D:\SERVER\REPOS`, `WORKTREES`, or `PROJECTS`.

```powershell
$task = & D:\SERVER\ROUTER\New-CertaTask.ps1 `
  -Request 'Build a tested PowerShell importer and document the result' `
  -WorkspacePath 'D:\SERVER\WORKTREES\certasurv-task-001' `
  -PreferredLane CODEX `
  -MaxMinutes 60

& D:\SERVER\ROUTER\Invoke-CertaRouter.ps1 -TaskPath $task.path
& D:\SERVER\ROUTER\Invoke-CertaQueue.ps1 -OnlyLane CODEX -IncludeCodex -MaxTasks 1 -SkipRouting
```

Codex runs non-interactively with:

- `workspace-write` sandbox;
- approval policy `never` so unattended work does not stall;
- user config ignored;
- ephemeral session;
- JSON event capture;
- a hard task timeout;
- Git state recorded before and after.

It does not use `--yolo` or `danger-full-access`. Successful work is still `CANDIDATE_COMPLETE` until validated.

## Trigger commands

The installer adds:

- `Certa Server Health`
- `Certa Server Route Once`
- `Certa Server Route All`
- `Certa Server Process Safe`
- `Certa Codex Run Next`
- `Certa Server Action`
- `Certa Open Server`

Only `Certa Server Action` accepts parameters, and its operations are hard-coded:

```text
health
route-once
route-all
process-safe
script-next
ollama-next
codex-next
submit-b64 <base64url JSON>
status <exact task ID>
```

No arbitrary PowerShell or direct natural-language-to-shell path is installed.

## Remote task submission

Encode a small NORMAL or COMPANY-sensitivity JSON object as base64url and pass it to:

```text
Certa Server Action → submit-b64 <payload>
```

Supported payload fields:

```json
{
  "request": "Build a tested importer",
  "project_id": "SSD-XXXXX-XXX",
  "workspace_path": "D:\\SERVER\\WORKTREES\\example",
  "preferred_lane": "CODEX",
  "max_minutes": 60,
  "sensitivity": "COMPANY"
}
```

Do not transmit client/restricted source data in Trigger parameters. Put governed inputs on the server and submit only the task reference.

## Safety and promotion

- Original project evidence remains in its approved source system.
- AI output is candidate information until validated.
- A verified script is preferred over a model.
- Boundary, legal, credential, destructive, and release decisions remain human/PLS/admin gates.
- Ollama is not exposed to the office LAN.
- After three similar independently verified Codex runs, the system may propose a reusable script. Promotion still requires human approval and regression tests.

## Versioned bundle

Autonomy v2 is shipped as a SHA256-pinned source bundle:

```text
server/bundles/certa-server-autonomy-v2.zip
server/bundles/certa-server-autonomy-v2.manifest.json
```

The bootstrap verifies the manifest and expands the complete PowerShell source overlay before installation. GitHub Actions expands the same bundle, parses every PowerShell file, checks the task schema and routing policy, enforces sandbox/Trigger/Ollama safety invariants, and runs the deterministic router self-test.
