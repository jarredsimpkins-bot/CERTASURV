# Certa Release Ops Readiness

Last updated: 2026-06-19 12:05

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public Actions API now shows latest overall run `#69` succeeded on June 19, 2026; latest verified `main` run is `#41` and also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; control scripts now target that path directly | Ready |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; the planned `certahealth.git` URL currently returns `repository not found` | Blocked |
| Cross-repo launch focus | `CERTARD` and `CERTASURV_WEB_APP` are clean locally; `MACROTBC` and `WV_COURTHOUSE_RESEARCHER` still carry substantive implementation deltas | Needs follow-through |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#69`, branch `codex/release-ops-wv-blocker-refresh-20260619`, commit `3aeb98f`, created `2026-06-19T15:45:54Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified public run detail check: run `#59`, branch `codex/remove-legacy-webapp-fallback-20260618`, commit `e053ee9`, triggered `2026-06-19 01:38 UTC`, status `success`
- Public run detail also shows a non-blocking GitHub-hosted warning: `actions/checkout@v4` is being forced onto Node.js 24 because Node.js 20 is deprecated
- Verified job summary for recent public runs: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax` and `Verify required control files`

## Cross-Repo Readiness Snapshot

- `CERTARD`: dirty local tree from `drive/CERTASURV_LIAISON_BRIEF.md`, but the broader launch lane is documented elsewhere as clean/ahead and mainly waiting on push-review timing
- `CERTASURV_WEB_APP`: local tree is clean and remote is configured; still a timing/review lane, not a release blocker
- `MACROTBC`: active dirty implementation lane with tracked edits under `macro_source`, `scripts`, and command-center config plus untracked parser-hotkey files
- `WV_COURTHOUSE_RESEARCHER`: active dirty implementation lane with tracked runbook/tooling edits across docs, scripts, and templates; still a substantive blocker lane

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to a dedicated `certahealth.git` remote, then actually create that repository before cutover if the dedicated path is still desired.
3. Land and review the outstanding implementation work in `MACROTBC` and `WV_COURTHOUSE_RESEARCHER`; those remain the substantive stack blockers.

## Non-Blocking Follow-Up

- Keep operator-facing references normalized to `CERTASURV_WEB_APP`; legacy `New project2` fallback has now been removed from the control scripts in this repo.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
