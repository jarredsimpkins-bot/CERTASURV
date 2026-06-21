# Certa Release Ops Readiness

Last updated: 2026-06-21 00:52

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest `main` run `#41` on June 18, 2026 succeeded; latest visible feature-branch run `#113` on June 21, 2026 also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but `G:\Shared drives\CERTASURV_PROJECT DRIVE` was not mounted during the June 21 provisioning check | Blocked until mount is restored |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references remain in older sibling-repo background docs only | Ready |
| CERTARD | Remote exists and repo is reachable locally; current launch lane is mostly push/review timing, not release-doc structure | Ready with review timing dependency |
| CERTASURV_WEB_APP | Remote exists and renamed workspace path is used by current control scripts | Ready with review timing dependency |
| MACROTBC | Remote exists, but local working tree is dirty and `certasurv_shared_drive.json` / `package.json` are absent from the working tree during this check; `npm run validate:repo` could not be run | Substantive blocker |
| WV_COURTHOUSE_RESEARCHER | Local repo exists and has active edits, but no remote is configured, so cloud review/push timing is blocked | Substantive blocker |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` public run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified overall public run: `#113`, branch `codex/release-control-webapp-path-guard-20260621`, commit `672734f`, created `2026-06-21T04:20:49Z`, conclusion `success`
- Local provisioning check on June 21, 2026 failed on operational dependencies: missing shared-drive mount, missing MACROTBC shared-drive config in the working tree, and `node`/`npm` not on PATH.

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Restore or remount `G:\Shared drives\CERTASURV_PROJECT DRIVE` before staged release handoff or shared-drive validation.
4. Resolve MACROTBC working-tree readiness before launch review: `certasurv_shared_drive.json` and `package.json` are currently absent from the local working tree, blocking local shared-drive validation and `npm run validate:repo`.
5. Configure a remote for `WV_COURTHOUSE_RESEARCHER` or explicitly decide that it remains local-only for this launch.
6. Put Node/npm on PATH for release-operation shells, or document the pinned Node runtime path used for MACROTBC and web-app validation.

## Non-Blocking Follow-Up

- Normalize any remaining legacy `New project2` references in old sibling-repo background docs when those files are next touched.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
