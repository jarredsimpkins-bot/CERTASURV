# Certa Release Ops Readiness

Last updated: 2026-06-18 12:28

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest overall run `#41` on June 18, 2026 succeeded on `main`; the preceding feature-branch run `#40` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| Capability/connection map alignment | Repo-local connection matrix still matches current workspace names, shared-drive roots, and sibling repo paths checked during this pass | Ready |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Local operator shell/tooling | `powershell.exe` is available for runbooks, but `pwsh`, `node`, and `npm` are not on this host PATH | Needs host follow-up |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:39Z`, conclusion `success`
- Latest verified prior overall run: `#40`, branch `main`, commit `e0cd20b`, created `2026-06-18T15:17:34Z`, conclusion `success`
- Verified job summary for run `#41`: single job `powershell-and-docs` succeeded, starting `2026-06-18T16:17:48Z` and completing `2026-06-18T16:18:16Z`

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Normalize host tooling if local release steps need Node-based commands or PowerShell 7 specifically; this host currently exposes `powershell.exe` but not `pwsh`, `node`, or `npm` on PATH.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
