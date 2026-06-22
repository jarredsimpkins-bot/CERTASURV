# Certa Release Ops Readiness

Last updated: 2026-06-22 11:00

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest `main` run `#41` on June 18, 2026 succeeded; latest overall visible run `#147` on June 22, 2026 also succeeded on release path-guard branch | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| CERTARD and CERTASURV_WEB_APP | Remotes are configured and current launch focus is push/review timing; the live OneDrive roots still show broad generated/untracked changes, so release review should use the intended clean branch/worktree for each repo | Review timing with scope caveat |
| MACROTBC and WV_COURTHOUSE_RESEARCHER | Both remain substantive launch blockers: MACROTBC has generated outputs and command-center deltas; WV_COURTHOUSE_RESEARCHER has active toolkit/runbook/toolbox edits and missing-directory warnings in `git status` | Blocked pending repo-local closeout |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified overall public run: `#147`, branch `codex/release-control-webapp-path-guard-20260622-2308`, commit `46a30ab`, created `2026-06-22T03:03:45Z`, conclusion `success`
- Verified job summary for run `#147`: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax`, `Verify required control files`, and `Block legacy web app path fallback`

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Close MACROTBC release deltas in its own repo before launch handoff, especially generated outputs, command-center CSV changes, and package/config deletions.
4. Close WV_COURTHOUSE_RESEARCHER toolkit/runbook edits in its own repo and resolve `git status` missing-directory warnings before treating courthouse research as release-ready.

## Non-Blocking Follow-Up

- Treat CERTARD and CERTASURV_WEB_APP as push/review-timing items only after the intended clean release branch/worktree is selected, because the live OneDrive roots still contain broad generated/untracked local changes.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
