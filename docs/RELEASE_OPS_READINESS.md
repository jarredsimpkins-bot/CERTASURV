# Certa Release Ops Readiness

Last updated: 2026-06-24 04:45 UTC

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | GitHub CLI now shows latest visible run `#210` on June 24, 2026 succeeded on `codex/release-control-webapp-path-guard-20260624-r2`; recent visible release-control/readiness runs remain green | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops; local `G:` shared-drive mount is currently missing on this host | Blocked until Drive mount returns |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk, but the current local checkout has many generated/unreviewed changes | Needs branch cleanup/review |
| GitHub CLI access | `gh auth status` now reports authenticated `jarredsimpkins-bot` access with `repo` scope and can inspect private workflow runs | Ready for inspection |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release gate | Latest `CertaSurv TBC Cloud Readiness` run `#37` failed on June 24, 2026; repo artifact/config checks pass, but end-to-end release-host checks still fail for the Command registry, TBC operator workflow HTML, and TBC tabulated workflow resolved from local `C:\...` config paths | Blocked |
| WV courthouse researcher gate | Local repo exists on branch `codex/wv-courthouse-researcher-cabell-lessons` with modified runbook/tool files and no configured Git remote | Blocked |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified run: `#210`, branch `codex/release-control-webapp-path-guard-20260624-r2`, commit `56f34f0`, created `2026-06-24T04:05:39Z`, conclusion `success`
- Recent verified release-control/readiness runs through `#210` completed successfully.
- Verified job summary for current control workflow: single job `powershell-and-docs` succeeds, including `Validate PowerShell syntax` and `Verify required control files`.

## Cross-Repo Launch Signals

| Repo | Latest checked signal | Launch impact |
| --- | --- | --- |
| CERTARD | `CERTARD Checks` run `#31` succeeded on `main` at commit `b2d1e59` on June 22, 2026; local branch has one modified liaison brief | Mostly push/review timing; not the primary release blocker |
| CERTASURV_WEB_APP | Latest visible CI remains run `#6`, failing June 19, 2026 on `tests/test_survey_storage.py::test_associated_drive_survey_export_dir_uses_active_project_lane`; local checkout includes deleted repo files plus generated data/cache artifacts | Needs branch cleanup/push/review timing before treating web app as release-green |
| MACROTBC | `CertaSurv TBC Cloud Readiness` run `#37` failed June 24, 2026 at commit `daafac0`; the log shows tabulated workflow/artifact checks pass, then end-to-end validation fails the Command registry, TBC operator workflow HTML, and TBC tabulated workflow checks against release-host `C:\...` paths | Primary release blocker |
| WV_COURTHOUSE_RESEARCHER | Local branch has modified docs/scripts/templates and no `origin` remote; no remote workflow could be inspected | Primary release blocker |

## Launch Blockers

1. Restore or sign into Google Drive Desktop so `G:\Shared drives\CERTASURV_PROJECT DRIVE` is visible before shared-drive handoff validation.
2. Fix or deliberately split MACROTBC release-host path validation for Command registry, TBC operator workflow HTML, and TBC tabulated workflow so cloud artifact checks do not mask missing local install paths.
3. Configure and publish WV_COURTHOUSE_RESEARCHER to a reviewed remote, then add at least a lightweight workflow/readiness check.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using public REST API checks as a fallback when GitHub CLI auth or token scopes are unavailable on a future host.
