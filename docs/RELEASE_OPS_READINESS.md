# Certa Release Ops Readiness

Last updated: 2026-06-22 12:20

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest `main` run `#41` on June 18, 2026 succeeded; latest overall visible run `#149` on June 22, 2026 also succeeded on a release path-guard branch | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Repo-local references exist, but `Test-CertaProjectProvisioning.ps1 -Detailed` currently reports the `G:` shared-drive mount and command-center folders missing on this host | Blocked until mount is restored |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| CERTARD and CERTASURV_WEB_APP | Both are on pushed release-support branches; live OneDrive roots still contain generated/untracked local clutter, so review should use the intended clean branch/worktree | Push/review timing with scope caveat |
| MACROTBC and WV_COURTHOUSE_RESEARCHER | MACROTBC has tracked package/config deletions, generated outputs, command-center CSV deltas, and missing `certasurv_shared_drive.json`; WV_COURTHOUSE_RESEARCHER has unpushed toolkit/runbook/tool registry edits and no upstream shown in status | Substantive release blockers |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

Current host provisioning check on June 22, 2026 could not access that shared-drive root, so the references are treated as expected targets rather than live mounted evidence for this run.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified overall public run: `#149`, branch `codex/release-control-webapp-path-guard-20260622-0004`, commit `990f15c`, created `2026-06-22T04:04:24Z`, conclusion `success`
- Verified job scope from public branch runs now includes `Validate PowerShell syntax`, `Verify required control files`, and a legacy web app path guard for `New project2` script references.

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Restore the `G:` shared-drive mount and command-center folders before copying or validating release handoff materials.
4. Close MACROTBC in its own repo: decide whether tracked root deletions are intentional, restore or replace missing `certasurv_shared_drive.json`, isolate generated output directories from the release diff, and confirm command-center CSV deltas are source-of-truth updates before review.
5. Close WV_COURTHOUSE_RESEARCHER in its own repo: either commit or intentionally clear the active toolkit/runbook/tool registry edits, set/confirm upstream tracking, and rerun the researcher smoke checks documented in that repo.

## Non-Blocking Follow-Up

- Treat CERTARD and CERTASURV_WEB_APP as push/review-timing items only after the intended clean release branch/worktree is selected, because the live OneDrive roots still contain broad generated/untracked local changes.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
- Restore Node.js/npm PATH before web app release verification from this host, or run web checks in a shell where Node LTS is available.
