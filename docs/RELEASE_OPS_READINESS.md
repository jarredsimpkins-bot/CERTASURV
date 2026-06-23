# Certa Release Ops Readiness

Last updated: 2026-06-23 10:36

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API previously showed run `#40` on June 18, 2026 succeeded on `main`; local workflow file still validates PowerShell syntax and required release docs | Ready pending next push |
| Control repo docs | Core launch docs are present in repo and tracked by workflow required-file validation, including this current blocker register | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| CERTARD coordination repo | Current launch focus treats CERTARD as locally clean and waiting on push/review timing | Ready pending push/review timing |
| CERTASURV web app | Current launch focus treats `CERTASURV_WEB_APP` as locally clean and waiting on push/review timing | Ready pending push/review timing |
| MACROTBC release lane | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` is on `codex/certasurv-unified-forward` with a dirty `command_center/tbc/command_usage_log.csv` during this pass | Blocked until operator review/commit or intentional discard |
| WV courthouse researcher lane | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` is on `codex/wv-courthouse-researcher-cabell-lessons` with dirty docs, scripts, and template registry files during this pass | Blocked until branch is reviewed, verified, and pushed |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#40`, branch `main`, commit `e0cd20b`, created `2026-06-18T15:17:34Z`, conclusion `success`
- Latest verified prior feature-branch run: `#39`, branch `codex/adaptive-worktree-launch-hardening-20260618`, commit `422cbb5`, created `2026-06-18T14:19:31Z`, conclusion `success`
- Verified job summary for run `#40`: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax` and `Verify required control files`

## Launch Blockers

1. Resolve the MACROTBC dirty command usage log state: either commit it as intentional release evidence or discard/regenerate it outside the release branch after operator review.
2. Resolve the WV_COURTHOUSE_RESEARCHER branch by reviewing and verifying the dirty docs/scripts/template registry changes, then push for review.
3. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
- Keep CERTARD and CERTASURV_WEB_APP in push/review timing mode unless a later local status pass shows new dirty files.
