# Certa Release Ops Readiness

Last updated: 2026-06-22

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest overall run `#40` on June 18, 2026 succeeded on `main`; the preceding feature-branch run `#39` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| Substantive release blockers | `MACROTBC` still needs production-integration package/workflow review; `WV_COURTHOUSE_RESEARCHER` needs remote/branch readiness and courthouse package review | Blocked |
| Clean local repos | `CERTARD` and `CERTASURV_WEB_APP` are treated as push/review-timing lanes rather than substantive blockers | Timing dependent |

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

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Finish the MACROTBC launch package/workflow review before treating the TBC production-integration lane as releasable.
4. Confirm the WV_COURTHOUSE_RESEARCHER GitHub remote, push branch, and courthouse/title package checks before release handoff.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
