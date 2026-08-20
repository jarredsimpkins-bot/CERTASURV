# Install the Certa server queue worker

The queue-worker extension is deliberately layered on top of the draft v1 router. It does not auto-run Codex, TBC/Land Desktop, professional review, destructive work, credentials, or releases.

## Draft-branch canary install

Run in an elevated PowerShell on the PC that owns `D:\SERVER`:

```powershell
$uri = 'https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/feat/certa-server-router-v1/bootstrap/Install-CertaServerWorkerExtension-FromGitHub.ps1'
$dst = Join-Path $env:TEMP 'Install-CertaServerWorkerExtension-FromGitHub.ps1'
Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $dst
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dst
```

The bootstrap installs the base router, pulls the configured local worker model unless skipped, adds the queue-worker extension, registers fixed non-parameterized TRIGGERcmd commands, disables sleep on AC, and registers the current-user worker startup entry.

## Expected Trigger commands

- `Certa Server Health`
- `Certa Server Queue Status`
- `Certa Server Process Queue`
- `Certa Server Start Worker`
- `Certa Server Stop Worker`
- `Certa Server Open`

Quit and reopen the TRIGGERcmd tray agent after installation so the commands republish.

## Manual checks before merge

1. `D:\SERVER\CONTROL\receipts` contains a passing base-install receipt and worker-extension receipt.
2. `certard-local` appears in `ollama list` and Ollama listens only on `127.0.0.1:11434`.
3. `Certa Server Health` and `Certa Server Queue Status` appear under the `CERTA-SERVER` computer in the company Trigger account.
4. A file-manifest task routes to SCRIPT, completes, and writes output plus a deterministic receipt.
5. A summary/classification task routes to OLLAMA and writes candidate-only output plus a receipt.
6. A coding task produces a CODEX queue record and prompt but does not auto-execute.
7. A Land Desktop/TBC task stays in SPECIALIST and is not converted into arbitrary shell execution.
8. A boundary/release/destructive request stays in HUMAN review.
9. Sign out/in or reboot and confirm the worker starts under the intended Windows profile.
10. Back up and restore a copy of `D:\SERVER\CONTROL` before authorizing cleanup on the MSI.

## Rollback

- Stop the worker with `D:\SERVER\ROUTER\Stop-CertaQueueWorker.ps1`.
- Remove or rename the current-user Startup entry `CertaServerQueueWorker.cmd` after preserving it for review.
- Restore the most recent `commands-worker-*.json` from `D:\SERVER\CONTROL\backups` to `%USERPROFILE%\.TRIGGERcmdData\commands.json`.
- The extension does not delete models, project data, source evidence, or the base router.
