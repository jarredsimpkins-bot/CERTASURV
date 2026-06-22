# Certa Release Ops Readiness

Last updated: 2026-06-22 09:05

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | GitHub API/CLI show latest overall run `#157` on June 22, 2026 succeeded; latest `main` run is `#41` on June 18, 2026 and succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Release scripts now use only `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; retired `New project2` is reported as a provisioning gap if present | Ready |
| CERTARD | Private workflow `CERTARD Checks` run `#31` on June 22, 2026 succeeded on `main` | Ready |
| CERTASURV_WEB_APP | Current local lane is treated as clean pending push/review timing; latest remote CI is still stale red from June 19, 2026 on `codex/certasurv-unified-forward` | Needs push/rerun evidence |
| MACROTBC | Latest private workflow run `#20` on June 22, 2026 failed two repo-readiness checks for folder-map/shared-config paths | Blocked pending owning-repo fix |
| WV_COURTHOUSE_RESEARCHER | Courthouse/title research release lane still needs remote/upstream and runbook evidence from its owning workspace | Blocked pending owning-repo evidence |
| GitHub CLI access | `gh auth status` succeeds for `jarredsimpkins-bot` with `repo` scope in this automation context | Ready for inspection |
| Local provisioning | `Test-CertaProjectProvisioning.ps1 -Detailed` finds missing shared-drive mount, missing MACROTBC shared-drive config, and `node`/`npm` absent from PATH | Blocked for final host handoff |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#157`, branch `codex/release-control-webapp-path-guard-20260622-automation`, commit `ad49013`, created `2026-06-22T08:07:44Z`, conclusion `success`
- Latest verified `main` run: `#41`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest private sibling-repo signals checked with `gh`: CERTARD run `#31` success; MACROTBC run `#20` failure; CERTASURV_WEB_APP run `#6` failure

## Launch Blockers

1. Fix MACROTBC owning-repo readiness: latest run fails `Folder map artifacts parse` and `Shared config TBC control root exists`.
2. Close WV_COURTHOUSE_RESEARCHER release evidence in the owning workspace: remote/upstream target, runbook/install notes, and workflow or smoke-test signal.
3. Push/rerun CERTASURV_WEB_APP clean branch evidence; latest remote CI failure is `tests/test_survey_storage.py::test_associated_drive_survey_export_dir_uses_active_project_lane`.
4. Restore final-host provisioning gaps: mount `G:\Shared drives\CERTASURV_PROJECT DRIVE`, restore `MACROTBC\certasurv_shared_drive.json`, and put `node`/`npm` on PATH.
5. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Keep CERTARD and CERTASURV_WEB_APP in push/review timing mode unless new local dirt or failing workflow evidence appears.
- Keep using the public REST API as a fallback when `gh` is unavailable in a future host context.
