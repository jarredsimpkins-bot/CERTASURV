# Certa Release Ops Readiness

Last updated: 2026-06-24 04:30

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh` shows latest visible `CertaHealth Control Checks` run `28084364917` on June 24, 2026 succeeded on `codex/release-control-webapp-path-guard-20260624-0715`; recent control runs are green | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops; `G:` shared-drive paths were not mounted during this pass | Ready with external dependency |
| Web app workspace naming | Release scripts now point directly at `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` fallback is removed | Ready |
| GitHub CLI access | `gh auth status` reports authenticated `jarredsimpkins-bot` with `repo` scope; private workflow logs can be inspected | Ready |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release blocker | Latest `CertaSurv TBC Cloud Readiness` run `28081546239` failed on June 24, 2026: required checks for command registry, TBC operator workflow HTML, and TBC tabulated workflow | Blocked |
| WV courthouse researcher release blocker | Local repo exists at `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`, but no `origin` remote is configured and `jarredsimpkins-bot/WV_COURTHOUSE_RESEARCHER` is not resolvable through `gh repo view` | Blocked |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified visible control run: `28084364917`, branch `codex/release-control-webapp-path-guard-20260624-0715`, created `2026-06-24T08:04:57Z`, conclusion `success`
- Latest verified visible control run on previous release-ops branch: `28082687371`, branch `codex/release-ops-wv-macrotbc-readiness-20260624b`, created `2026-06-24T07:31:39Z`, conclusion `success`
- Latest verified MACROTBC blocker run: `28081546239`, branch `codex/certasurv-unified-forward`, commit `6de47a9`, created `2026-06-24T07:08:25Z`, conclusion `failure`

## Launch Blockers

1. Fix MACROTBC repo validation failures for command registry, TBC operator workflow HTML, and TBC tabulated workflow so `CertaSurv TBC Cloud Readiness` turns green.
2. Configure and publish `WV_COURTHOUSE_RESEARCHER` to its intended GitHub remote; the local repo is currently source-control local only.
3. Remount or sign into Google Drive for Desktop before any shared-drive package handoff; `G:\Shared drives\CERTASURV_PROJECT DRIVE` was unavailable to `Test-CertaProjectProvisioning.ps1` on this run.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Keep private workflow inspection on `gh` now that the host is authenticated; public REST API remains a fallback for public control workflow visibility.
- Do not sweep unrelated dirty changes from sibling repos into release commits; current release-ops work should stay repo-local unless a generated copy from a committed repo file is intentionally handed off.
