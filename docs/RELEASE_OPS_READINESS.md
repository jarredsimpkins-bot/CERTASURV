# Certa Release Ops Readiness

Last updated: 2026-06-19 13:05

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public GitHub Actions page now shows `69 workflow runs`; latest visible overall run is `#69` on June 19, 2026 and it succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host, so private workflow/log inspection and authenticated push flows remain unavailable here | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## Current Launch Focus By Repo

| Repo | Current focus | Launch impact |
| --- | --- | --- |
| `CERTARD` | Clean locally; primarily waiting on push/review timing and release sequencing with the rest of the stack | Ready pending timing |
| `CERTASURV_WEB_APP` | Clean locally after workspace rename alignment; mainly needs push/review timing and final release coordination | Ready pending timing |
| `MACROTBC` | Still the substantive blocker because command-center, install, and production-integration readiness need final release confirmation | Blocker |
| `WV_COURTHOUSE_RESEARCHER` | Still the substantive blocker because Release 1 remote/readiness and final upstream handling are not fully cleared | Blocker |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest visible overall public run on the workflow page: `#69`, commit `3aeb98f`, branch `codex/release-ops-wv-blocker-refresh-20260619`, duration `20s`, conclusion `success`
- Additional recent successful runs visible on the public workflow page: `#68` (`ff261a7`) and `#67` (`f6a0a19`)
- Public workflow page currently reports `69 workflow runs` total
- The workflow still consists of a single `powershell-and-docs` job covering `Validate PowerShell syntax` and `Verify required control files`

## Launch Readiness Interpretation

- The control repo itself remains operationally ready for release-note and runbook updates because the public workflow continues to pass on recent release-ops branches.
- The control repo is not the current stack blocker; the launch-critical blockers remain `MACROTBC` and `WV_COURTHOUSE_RESEARCHER`.
- `CERTARD` and `CERTASURV_WEB_APP` should be treated as coordination items for push/review timing, not as engineering blockers, unless new remote or review failures appear.

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Clear the remaining release blockers in `MACROTBC` and `WV_COURTHOUSE_RESEARCHER`; until those are resolved, control-repo readiness does not translate into full-stack launch readiness.

## Non-Blocking Follow-Up

- Keep using the public GitHub workflow page as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
- Preserve repo-local release-note copies as the source for any later shared-drive documentation refreshes; do not edit live shared-drive content directly during release-ops triage.
