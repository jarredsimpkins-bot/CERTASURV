# Cloud Processing Plan

Last updated: 2026-06-24

## What Moves To Cloud

| Work | Cloud Target | Reason |
| --- | --- | --- |
| Python app tests for `CERTASURV_WEB_APP` | GitHub Actions | Keeps dependency install and pytest load off the laptop |
| PowerShell syntax checks for control/TBC scripts | GitHub Actions on Windows runners | Catches broken scripts without touching local production |
| JSON/config validation for command-center and Drive automation packages | GitHub Actions | Verifies package integrity before handoff |
| Drive file routing and scraper jobs | Google Apps Script triggers | Runs near Drive data instead of depending on laptop uptime |
| Shared-drive package artifacts | GitHub Actions artifacts after push | Gives downloadable release packages outside OneDrive |

## What Stays Local

| Work | Reason |
| --- | --- |
| Live TBC/Trimble macro execution | Requires installed Trimble Business Center and local user session |
| Google Drive Desktop mounting | Requires signed-in desktop client and local drive letter |
| Laptop load/process management | Controls this physical machine |

## Adaptive Rule

`CERTA Laptop Load Manager` now runs in `Auto` mode every minute. If TBC/Trimble is active, local priority shifts to TBC and nonessential browser/Codex/helper work is parked. If TBC is not active, local dev helpers are allowed back to normal priority so Codex/local tooling can take more work. `CERTA Cloud Offload Runner` checks every 5 minutes and pushes already-committed branches once Git remotes and Git Credential Manager access are available.

## Codex Cloud Utilization

The subscription is now used in parallel launch lanes:

| Lane | Cadence | Cloud Work |
| --- | --- | --- |
| Certa launch supervisor | Hourly | Cross-repo launch readiness review |
| Certa launch implementer | Hourly | Safe repo-local launch fixes across the stack |
| MACROTBC implementation worker | Hourly | TBC integration hardening that does not require live TBC |
| Drive automation implementation worker | Hourly | Apps Script, registry, and Drive automation hardening |
| Web app implementation worker | Hourly | App/dashboard tests, package, and CI readiness |
| Certa release ops worker | Hourly | Release docs, runbooks, workflow/handoff readiness |
| Certa launch cloud health | Every 30 minutes | Thread health report for cloud/local routing |
| WV courthouse researcher worker | As needed until remote exists | Prepare courthouse/title/LiDAR/TBC basemap docs and scripts for a reviewable remote lane |

Cloud workers may commit and push scoped repo-local fixes. They must not touch live Trimble runtime folders, destructively modify shared-drive data, or sweep unrelated dirty local changes into commits.

## Activation Gate

The workflows are prepared locally and pushed to GitHub. They run on each pushed repo/branch:

1. `CERTASURV` / `CERTAHEALTH`: public control repo, `main`.
2. `certard`: private coordination repo, `main`.
3. `macrotbc`: private TBC production integration repo, `codex/certasurv-command-center`.
4. `certasurv-automations`: private Drive/AppScript automation repo, `codex/onboard-everything`.
5. `certasurv-web-app`: private app/dashboard repo, `codex/land-opportunity-radar-mvp`.
6. `wv-courthouse-researcher`: not activated yet; local repo has no configured remote.

The cloud offload runner pushes committed branches every 10 minutes. It intentionally does not auto-stage or auto-commit live work.

## Current Control-Repo Signal

- Control-repo workflow `CertaHealth Control Checks` is visible on GitHub and the latest checked run `#208` on branch `codex/release-control-webapp-path-guard-20260624-0205`, commit `227a526`, succeeded on June 24, 2026.
- CERTARD latest checked `CERTARD Checks` run `#31` succeeded on `main`, commit `b2d1e59`, on June 22, 2026.
- MACROTBC latest checked `CertaSurv TBC Cloud Readiness` run `#37` failed on June 24, 2026 because three required checks need attention: Command registry, TBC operator workflow HTML, and TBC tabulated workflow.
- CERTASURV_WEB_APP latest visible CI run remains the June 19, 2026 failure in `tests/test_survey_storage.py::test_associated_drive_survey_export_dir_uses_active_project_lane`; the local checkout also has deleted repo files plus generated data/cache artifacts, so treat web app as needing cleanup, push/review timing, and CI confirmation.
- WV_COURTHOUSE_RESEARCHER has no configured remote, so cloud workflow output is not available yet.
