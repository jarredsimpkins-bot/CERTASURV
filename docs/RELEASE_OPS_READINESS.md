# Certa Release Ops Readiness

Last updated: 2026-06-18 18:21

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest overall run `#51` on June 18, 2026 succeeded on `codex/wv-courthouse-launch-alignment-20260618b`; latest `main` run `#41` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| App workspace naming | Active local folders are `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` and `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#51`, branch `codex/wv-courthouse-launch-alignment-20260618b`, commit `b3cf43c`, created `2026-06-18T21:36:13Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified job summary for run `#51`: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax` and `Verify required control files`

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` and `WV_COURTHOUSE_RESEARCHER` across sibling repos so release handoff docs all use the same workspace names.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
