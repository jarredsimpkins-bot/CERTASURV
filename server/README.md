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
  -DisableSleepOnAC
```

## One-line bootstrap after merge

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `
  "iwr https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/Install-CertaServer-FromGitHub.ps1 -OutFile $env:TEMP\Install-CertaServer.ps1; & $env:TEMP\Install-CertaServer.ps1 -PullModel -InstallTriggerCommands -DisableSleepOnAC"
```

The bootstrap resolves `main` (or another requested ref) to one immutable commit before downloading the installer set, and the installed manifest records that source commit.

Ollama remains bound to `127.0.0.1:11434`, disables Ollama cloud features, uses one loaded model and one parallel request, and stores models under `D:\SERVER\OLLAMA\models`.

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
- `Certa Server Route Once`
- `Certa Server Route All`
- `Certa Ollama Status`
- `Certa Open Server`

The installer updates `commands.json` through a validated temporary file, preserves a timestamped backup, and restarts the foreground agent when it can resolve the running executable. These commands require the same Windows profile and an interactive foreground-agent session; validate them again after a reboot.

## Execution boundary

This v1 router classifies and queues all five lanes. The Ollama queue has a manual candidate executor. SCRIPT, CODEX, SPECIALIST, and HUMAN remain controlled handoff queues until dedicated workers/adapters are added; routing a task does not mean that downstream work ran.

`STAGING\router` contains atomically claimed work. A healthy server has no stranded JSON tasks there. Original inbox records are retained in `ARCHIVE\tasks` after successful routing.

## Target-PC validation

Before production cutover:

1. Run the installer against the existing `D:\SERVER` and confirm unrelated content is unchanged.
2. Confirm `certard-local` is present, `OLLAMA_MODELS` points at `D:\SERVER\OLLAMA\models`, cloud use is disabled, and port 11434 has no wildcard listener.
3. Confirm all five TRIGGERcmd commands appear on the intended PC with parameters disabled and execute from a remote trigger.
4. Reboot, sign into the dedicated Windows profile, and rerun `Get-CertaServerHealth.ps1`.
5. Route one test through every lane and retain its routing receipt and archived intake record.

## Safety and authority

- Original project evidence remains in its approved source system.
- `D:\SERVER` contains control state, queues, worktrees, outputs, and receipts; it does not replace the approved project system of record.
- AI output is candidate information until validated.
- A verified script is preferred over a model.
- Codex builds new capabilities; repeated successful patterns can later be promoted to tested scripts.
- Boundary, legal, credential, destructive, and release decisions remain human/PLS/admin gates.
- Ollama is not exposed to the office LAN.
- Ollama cloud features are disabled for the server profile.
- No unrestricted Trigger shell is installed.
