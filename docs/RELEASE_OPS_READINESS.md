# Certa Release Ops Readiness

Last updated: 2026-06-19 09:55

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest overall run `#67` on branch `codex/release-ops-doc-refresh-20260619-0102` succeeded on June 19, 2026; latest `main` run remains `#41` on commit `6f40b64` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | External staging and deployment references still exist, but the `G:` shared-drive mount is missing on this host during this pass | Blocked on host state |
| Workspace launch split | `CERTASURV_WEB_APP` is clean; `CERTARD` is near-ready but still has one modified liaison brief; `MACROTBC` and `WV_COURTHOUSE_RESEARCHER` remain the substantive blockers | Mixed |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host as of June 19, 2026 | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still exist locally and continue to point at the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE`, but the `G:` mount itself is not currently available on this host.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#67`, branch `codex/release-ops-doc-refresh-20260619-0102`, commit `f6a0a19`, created `2026-06-19T05:32:20Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified job summary pattern for the latest completed runs: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax` and `Verify required control files`

## Launch Blockers

1. Restore the `G:\Shared drives\CERTASURV_PROJECT DRIVE` mount on the release host before any staging or handoff that depends on the system-of-record folders.
2. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
3. Resolve the substantive repo blockers: `MACROTBC` is still dirty, and `WV_COURTHOUSE_RESEARCHER` remains dirty with no `origin`.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- `CERTASURV_WEB_APP` is clean locally and looks ready for push/review timing once the broader launch blockers clear.
- `CERTARD` has only one modified file, `drive/CERTASURV_LIAISON_BRIEF.md`; decide whether that brief should ship or be reset before calling the repo clean.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
