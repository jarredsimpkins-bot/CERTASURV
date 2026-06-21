# Certa Release Ops Readiness

Last updated: 2026-06-21 11:05

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public GitHub Actions page shows latest visible overall run `#127` on June 21, 2026 succeeded; latest previously verified `main` run remains `#40` on June 18, 2026 | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; control scripts now use that path directly | Ready |
| CERTARD release lane | Local repo has `origin` set to `https://github.com/jarredsimpkins-bot/certard.git`; remaining work is push/review timing outside this control repo | Ready with review timing |
| CERTASURV_WEB_APP release lane | Local repo has `origin` set to `https://github.com/jarredsimpkins-bot/certasurv-web-app.git`; remaining work is push/review timing outside this control repo | Ready with review timing |
| MACROTBC release lane | Local repo has `origin` set to `https://github.com/jarredsimpkins-bot/macrotbc.git`, but it still has substantive release work and dirty/untracked production artifacts | Blocked |
| WV_COURTHOUSE_RESEARCHER release lane | Local repo exists as a Git worktree with dirty release-runbook/toolkit edits but no `origin` remote configured on this host | Blocked |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`
- `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER\docs\certasurv_toolkit_runbook.md`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest visible overall public run: `#127`, branch `codex/release-control-webapp-path-guard-20260621-1500`, commit `9cd16ff`, triggered `2026-06-21 11:25`, conclusion `success`
- Latest previously verified `main` run: `#40`, branch `main`, commit `e0cd20b`, created `2026-06-18T15:17:34Z`, conclusion `success`
- Verified job summary for run `#127`: single job `powershell-and-docs` succeeded; GitHub shows one Node.js runner deprecation warning for `actions/checkout@v4`

## Current Launch Blockers

1. Finish MACROTBC release hardening and review/stage only intended production integration artifacts before push.
2. Configure and push `WV_COURTHOUSE_RESEARCHER` to `https://github.com/jarredsimpkins-bot/wv-courthouse-researcher.git`, then review the dirty runbook/toolkit edits before release.
3. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Push/review timing remains for CERTARD and CERTASURV_WEB_APP, but neither is the current substantive release blocker.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
