# Release Ops Readiness

Last updated: 2026-06-17

This runbook is the repo-local release operations snapshot for the Certa/CertaSurv stack. It is meant to stay commit-safe: no live shared-drive content is changed here, but the documents and workflow checks below should track whether launch handoff is actually ready.

## Current Signal

| Area | Status | Notes |
| --- | --- | --- |
| Control repo workflow | Ready | Public GitHub Actions page for `jarredsimpkins-bot/CERTASURV` showed 26 `CertaHealth Control Checks` runs during this pass, with the latest visible run on 2026-06-17 |
| Release docs | Needs small follow-up elsewhere | This repo now reflects the `CERTASURV_WEB_APP` rename and current remote/auth state; other repos may still carry `New project2` references |
| GitHub CLI auth | Blocked locally | `gh auth status` reports no logged-in host, so authenticated PR/run inspection cannot be relied on from this machine yet |
| Local PowerShell 7 | Missing locally, non-blocking for GitHub Actions | `pwsh` is not installed in this workstation environment, but the workflow still targets GitHub-hosted Windows runners where PowerShell 7 is available |
| Shared-drive handoff docs | Informational only | Shared-drive paths remain documented here, but live Drive contents were not modified in this run |
| Repo routing | Needs decision | `CERTAHEALTH` still pushes to public `CERTASURV.git`; planned long-term slug remains `certahealth.git` in the docs |

## Handoff Sources Checked

- [`C:\Users\SimpS\.codex\worktrees\9224\CERTAHEALTH\docs\PROJECT_CONNECTION_MATRIX.md`](C:\Users\SimpS\.codex\worktrees\9224\CERTAHEALTH\docs\PROJECT_CONNECTION_MATRIX.md)
- [`C:\Users\SimpS\.codex\worktrees\9224\CERTAHEALTH\docs\GIT_SITUATION.md`](C:\Users\SimpS\.codex\worktrees\9224\CERTAHEALTH\docs\GIT_SITUATION.md)
- [`C:\Users\SimpS\.codex\worktrees\9224\CERTAHEALTH\docs\CLOUD_PROCESSING.md`](C:\Users\SimpS\.codex\worktrees\9224\CERTAHEALTH\docs\CLOUD_PROCESSING.md)
- [`C:\Users\SimpS\.codex\worktrees\9224\CERTAHEALTH\.github\workflows\certahealth-control-checks.yml`](C:\Users\SimpS\.codex\worktrees\9224\CERTAHEALTH\.github\workflows\certahealth-control-checks.yml)
- Public workflow page: [jarredsimpkins-bot/CERTASURV Actions](https://github.com/jarredsimpkins-bot/CERTASURV/actions)

## Launch Checklist

- Confirm whether the control repo should continue using the public `CERTASURV` repository or be repointed to `certahealth.git`.
- Authenticate GitHub CLI with `gh auth login` before depending on local run-log or PR automation.
- Continue rename cleanup in sibling repos if they still reference `New project2` instead of `CERTASURV_WEB_APP`.
- Re-run `scripts/Test-CertaProjectProvisioning.ps1 -Detailed` from the primary workstation when shared-drive and outside-repo mounts are expected to be online.

## Safe Local Verification

- `pwsh -NoProfile -File scripts/Test-CertaProjectProvisioning.ps1 -Detailed`
- GitHub Actions workflow `CertaHealth Control Checks`
- Local fallback used in this pass: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Test-CertaProjectProvisioning.ps1 -Detailed`
