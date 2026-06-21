# Certa Release Ops Readiness

Last updated: 2026-06-21 08:00

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest overall run `#40` on June 18, 2026 succeeded on `main`; the preceding feature-branch run `#39` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| CERTARD and web app lanes | Both have configured origins and are locally past the cleanup pass; remaining work is push/review timing | Ready pending review timing |
| MACROTBC lane | Remote exists, but production integration hardening and workflow evidence remain launch-critical | Blocked |
| WV courthouse research lane | Local workspace exists with active branch `codex/wv-courthouse-researcher-cabell-lessons`, local changes, and no observed `origin` | Blocked |
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

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Finish MACROTBC release-blocking production integration review before declaring the TBC lane launch-ready.
4. Create or confirm the `WV_COURTHOUSE_RESEARCHER` upstream, set `origin`, and push its active branch for review.

## Non-Blocking Follow-Up

- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
