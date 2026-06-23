# Git Situation

Last updated: 2026-06-23

## Fixed Locally

- Global git identity is set to `jarredsimpkins-bot`.
- Global git email is set to `286102097+jarredsimpkins-bot@users.noreply.github.com`.
- Default branch for new repositories is set to `main`.
- Git credential helper is set to `manager`.
- GitHub CLI is authenticated as `jarredsimpkins-bot` on this host and can list private workflow runs.

## Active Local Repositories

| Repo | Path | Remote Status |
| --- | --- | --- |
| CERTAHEALTH | `C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH` | `origin` -> `https://github.com/jarredsimpkins-bot/CERTASURV.git` |
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | `origin` -> `https://github.com/jarredsimpkins-bot/certard.git` |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | `origin` -> `https://github.com/jarredsimpkins-bot/macrotbc.git` |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-automations.git` |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | No remote configured during the June 23, 2026 release-ops pass |

## Planned Remote Names

| Local Repo | GitHub Remote |
| --- | --- |
| CERTAHEALTH | `https://github.com/jarredsimpkins-bot/certahealth.git` |
| CERTARD | `https://github.com/jarredsimpkins-bot/certard.git` |
| MACROTBC | `https://github.com/jarredsimpkins-bot/macrotbc.git` |
| AUTOMATIONS | `https://github.com/jarredsimpkins-bot/certasurv-automations.git` |
| CERTASURV_WEB_APP | `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |

All planned repositories now exist. `CERTASURV` is public; the remaining launch support repositories are private.

## Current Release-Ops Notes

- `CERTAHEALTH` currently pushes to public `CERTASURV.git`, but the planned dedicated target remains `certahealth.git`.
- `CERTASURV_WEB_APP` is the active local workspace name; any lingering `New project2` references should be treated as legacy docs only.
- MACROTBC remains the primary workflow blocker: latest visible `CertaSurv TBC Cloud Readiness` run `28000398484` failed on June 23, 2026.
- WV_COURTHOUSE_RESEARCHER remains the primary remote/upstream blocker because no local remote is configured.
