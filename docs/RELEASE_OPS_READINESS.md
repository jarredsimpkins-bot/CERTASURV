# Certa Release Ops Readiness

Last updated: 2026-06-21 21:16 ET

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest visible run `#143` on June 22, 2026 succeeded on `codex/release-control-webapp-path-guard-20260622`; latest verified `main` run remains `#40` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## Current Launch Focus

| Component | Release-ops signal | Next release action |
| --- | --- | --- |
| CERTARD | Local repo has `origin` configured at `https://github.com/jarredsimpkins-bot/certard.git`; launch focus says local content is already clean enough for push/review timing | Schedule push/review window; do not reopen release scope unless a reviewer finds a blocker |
| CERTASURV_WEB_APP | Active workspace path is canonical and `origin` is configured at `https://github.com/jarredsimpkins-bot/certasurv-web-app.git`; launch focus says local content is already clean enough for push/review timing | Schedule push/review window after Node/npm PATH is restored for local smoke checks |
| MACROTBC | `origin` is configured at `https://github.com/jarredsimpkins-bot/macrotbc.git`, but provisioning still reports missing `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json` | Restore or intentionally regenerate the shared-drive config before release packaging |
| WV_COURTHOUSE_RESEARCHER | Local repo exists at `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` but has no `origin` remote during this pass | Add/confirm remote destination, then push and review the current Cabell lessons branch |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified visible public run: `#143`, branch `codex/release-control-webapp-path-guard-20260622`, commit `5f36c19`, created `2026-06-22T01:06:11Z`, conclusion `success`
- Latest verified `main` run: `#40`, branch `main`, commit `e0cd20b`, created `2026-06-18T15:17:34Z`, conclusion `success`
- Latest verified prior feature-branch run: `#39`, branch `codex/adaptive-worktree-launch-hardening-20260618`, commit `422cbb5`, created `2026-06-18T14:19:31Z`, conclusion `success`
- Verified job summary for run `#40`: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax` and `Verify required control files`

## Current Local Provisioning Gaps

`scripts\Test-CertaProjectProvisioning.ps1 -Detailed` on June 21, 2026 reported these release-ops gaps:

- Shared-drive mount missing: `G:\Shared drives\CERTASURV_PROJECT DRIVE`
- Command-center root and shared-drive project folders missing under the shared-drive mount
- MACROTBC shared-drive config missing: `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json`
- `node` and `npm` missing from PATH on this host

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Resolve the two substantive release blockers: MACROTBC shared-drive config/package readiness and WV_COURTHOUSE_RESEARCHER remote/push readiness.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
