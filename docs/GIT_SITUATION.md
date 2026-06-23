# Git Situation

Last updated: 2026-06-23

## Fixed Locally

- Global git identity is set to `jarredsimpkins-bot`.
- Global git email is set to `286102097+jarredsimpkins-bot@users.noreply.github.com`.
- Default branch for new repositories is set to `main`.
- Git credential helper is set to `manager`.

## Active Local Repositories

| Repo | Path | Remote Status |
| --- | --- | --- |
| CERTAHEALTH | `C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH` | `origin` -> `https://github.com/jarredsimpkins-bot/CERTASURV.git` |
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | `origin` -> `https://github.com/jarredsimpkins-bot/certard.git` |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | `origin` -> `https://github.com/jarredsimpkins-bot/macrotbc.git` |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-automations.git` |
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | Local-only; remote creation/push is blocked until a destination is assigned |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |

## Planned Remote Names

| Local Repo | GitHub Remote |
| --- | --- |
| CERTAHEALTH | `https://github.com/jarredsimpkins-bot/certahealth.git` |
| CERTARD | `https://github.com/jarredsimpkins-bot/certard.git` |
| MACROTBC | `https://github.com/jarredsimpkins-bot/macrotbc.git` |
| AUTOMATIONS | `https://github.com/jarredsimpkins-bot/certasurv-automations.git` |
| WV_COURTHOUSE_RESEARCHER | Remote intentionally unassigned |
| CERTASURV_WEB_APP | `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |

All planned repositories with assigned destinations now exist. `CERTASURV` is public; the assigned launch support repositories are private. `WV_COURTHOUSE_RESEARCHER` remains local-only until a remote destination is explicitly chosen.

## Current Release-Ops Notes

- `CERTAHEALTH` currently pushes to public `CERTASURV.git`, but the planned dedicated target remains `certahealth.git`.
- Release-control scripts must resolve the active web app only through `CERTASURV_WEB_APP`; script-side `New project2` fallback is blocked by CI.
- `WV_COURTHOUSE_RESEARCHER` is inventory-only for release control and must not be pushed by automation until its remote is assigned.
- GitHub CLI is installed locally but was unauthenticated during the June 17, 2026 release-ops pass, so private-repo workflow inspection still requires `gh auth login`.
