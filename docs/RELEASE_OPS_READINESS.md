# Certa Release Ops Readiness

Last updated: 2026-06-19 00:45 EDT

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest overall run `#64` on branch `codex/release-control-wv-hardening-20260618` succeeded on June 19, 2026; latest `main` run remains `#41` on commit `6f40b64` and also succeeded | Ready |
| Control repo docs and scripts | Core launch docs are present in repo, tracked by workflow required-file validation, and now re-aligned to the current cross-repo blocker map | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references still exist outside this repo and were re-verified read-only during this pass | Ready with external dependency |
| CERTASURV web app lane | `CERTASURV_WEB_APP` is present locally, has `origin`, and is clean in the current local check | Ready pending push/review timing |
| CERTARD coordination lane | `CERTARD` has `origin` and helper scripts in place, but the current local check found one modified liaison brief | Near ready; local doc change pending |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| MACROTBC lane | `MACROTBC` has `origin`, but the current local check found multiple tracked edits plus two untracked files | Blocked |
| WV courthouse lane | `WV_COURTHOUSE_RESEARCHER` exists locally but is still `LOCAL_ONLY` with no `origin`; the current local check also found tracked edits | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` remains the intended dedicated target | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#64`, branch `codex/release-control-wv-hardening-20260618`, commit `79097bd`, created `2026-06-19T03:42:13Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified job summary for run `#64`: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax` and `Verify required control files`

## Current Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Resolve the active dirty work in `MACROTBC` before treating that lane as release-ready.
4. Create and set `origin` for `WV_COURTHOUSE_RESEARCHER`, then stage or commit its current toolkit/runbook changes intentionally.

## Non-Blocking Follow-Up

- Keep treating `CERTARD` as near-ready, but clear or commit `drive/CERTASURV_LIAISON_BRIEF.md` before claiming the lane is clean.
- Keep using the public REST API as the fallback for public workflow visibility when `gh` remains unauthenticated on this host.
- Normalize `node` and `npm` onto `PATH`; the provisioning script still reports both missing on this machine.
