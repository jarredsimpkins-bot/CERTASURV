# CertaSurv Server Router v1

This is the first operational layer that turns `D:\SERVER` into the primary CertaSurv task intake and routing location.

## What it does

Every task enters `D:\SERVER\INBOX` and is routed into one of five lanes:

1. **SCRIPT** — a verified deterministic capability already exists.
2. **OLLAMA** — low-risk local classification, extraction, summarization, tagging, or explanation.
3. **CODEX** — new code, debugging, integration, migration, tests, or repository changes are required.
4. **SPECIALIST** — TBC, Land Desktop, CAD, CloudCompare, WebODM, or another licensed/hardware-specific node is required.
5. **HUMAN** — professional survey judgment, legal authority, credentials, destructive work, or production release is required.

The router does not convert arbitrary natural-language text into unrestricted shell commands. It writes routed task records and receipts. The local Ollama lane produces candidate-only responses.

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

Ollama remains bound to `127.0.0.1:11434`, uses one loaded model and one parallel request, and stores models under `D:\SERVER\OLLAMA\models`.

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

After registration, quit and reopen the TRIGGERcmd foreground tray agent so the commands publish.

## Safety and authority

- Original project evidence remains in its approved source system.
- AI output is candidate information until validated.
- A verified script is preferred over a model.
- Codex builds new capabilities; repeated successful patterns can later be promoted to tested scripts.
- Boundary, legal, credential, destructive, and release decisions remain human/PLS/admin gates.
- Ollama is not exposed to the office LAN.
- No unrestricted Trigger shell is installed.
