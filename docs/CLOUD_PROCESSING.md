# Cloud Processing Plan

Last updated: 2026-06-20

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

Cloud workers may commit and push scoped repo-local fixes. They must not touch live Trimble runtime folders, destructively modify shared-drive data, or sweep unrelated dirty local changes into commits.

## Activation Gate

The workflows are prepared locally and pushed to GitHub. They run on each pushed repo/branch:

1. `CERTASURV` / `CERTAHEALTH`: public control repo, `main`.
2. `certard`: private coordination repo, `main`.
3. `macrotbc`: private TBC production integration repo, `codex/certasurv-command-center`.
4. `certasurv-automations`: private Drive/AppScript automation repo, `codex/onboard-everything`.
5. `certasurv-web-app`: private app/dashboard repo, `codex/land-opportunity-radar-mvp`.

The cloud offload runner pushes committed branches every 10 minutes. It intentionally does not auto-stage or auto-commit live work.

## Current Control-Repo Signal

- Public control-repo workflow `CertaHealth Control Checks` is visible on GitHub and the latest public run observed on June 20, 2026 was successful.
- The latest visible overall run is `#94` on branch `codex/release-control-webapp-path-strict-20260620`, commit `7285e83`, success.
- The preceding visible public runs `#93`, `#92`, `#91`, and `#90` also succeeded on June 20, 2026 feature branches.
- The current local `origin/main` is `6f40b64`, `docs: refresh control workflow status`.
- Private-repo workflow outputs remain unavailable from this host until `gh` authentication is restored.

## Current Cloud/Local Split Blockers

- `MACROTBC` and `WV_COURTHOUSE_RESEARCHER` remain the substantive launch blockers because both have active uncommitted release-lane work.
- `CERTARD` and `CERTASURV_WEB_APP` are comparatively clean launch lanes; they mainly need push/review timing once current doc changes are finalized.
- Local verification is incomplete while the shared drive is unmounted and Node/npm are absent from PATH. Use cloud runners for repo checks where possible, but restore local paths before final handoff verification.
