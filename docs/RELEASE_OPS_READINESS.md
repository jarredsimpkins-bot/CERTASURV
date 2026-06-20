# Certa Release Ops Readiness

Last updated: 2026-06-20 02:00

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest `main` run `#41` on June 18, 2026 succeeded at `6f40b64`; latest overall run `#81` on June 20, 2026 also succeeded on a release-ops branch | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Staging and Apps Script deployment references exist outside this repo; current local provisioning check reports `G:` shared-drive paths unmounted | Blocked on local mount |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| Provisioning Git checks | `scripts\Test-CertaProjectProvisioning.ps1` now asks Git for repo and origin state, so normal clones and `.git` file worktrees are handled consistently | Ready |
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
- Latest verified overall public run: `#81`, branch `codex/release-ops-tooling-evidence-20260620`, commit `71e3d50`, created `2026-06-20T05:57:09Z`, conclusion `success`
- Local syntax verification on June 20, 2026: `scripts\Test-CertaProjectProvisioning.ps1` parses cleanly after Git worktree-safe remote detection changes

## Launch Blockers

1. Mount `G:\Shared drives\CERTASURV_PROJECT DRIVE` before shared-drive release checks or handoff staging.
2. Add Node/npm to `PATH` if local web/app checks must run from this control host.
3. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
