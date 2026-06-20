# Git Situation

Last updated: 2026-06-20

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
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | No remote configured; no upstream tracking |

## Planned Remote Names

| Local Repo | GitHub Remote |
| --- | --- |
| CERTAHEALTH | `https://github.com/jarredsimpkins-bot/certahealth.git` |
| CERTARD | `https://github.com/jarredsimpkins-bot/certard.git` |
| MACROTBC | `https://github.com/jarredsimpkins-bot/macrotbc.git` |
| AUTOMATIONS | `https://github.com/jarredsimpkins-bot/certasurv-automations.git` |
| CERTASURV_WEB_APP | `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |
| WV_COURTHOUSE_RESEARCHER | TBD before Release 1 launch cutover |

All planned repositories except the unresolved `WV_COURTHOUSE_RESEARCHER` destination are accounted for. `CERTASURV` is public; the remaining launch support repositories are private.

## Current Release-Ops Notes

- `CERTAHEALTH` currently pushes to public `CERTASURV.git`, but the planned dedicated target remains `certahealth.git`.
- `CERTASURV_WEB_APP` is the active local workspace name; any lingering `New project2` references should be treated as legacy docs only.
- `CERTARD` and `CERTASURV_WEB_APP` are currently timing/review items rather than substantive release blockers.
- `MACROTBC` is clean locally but still needs TBC integration release review/signoff.
- `WV_COURTHOUSE_RESEARCHER` remains the source-control blocker because it has local changes with no configured remote/upstream.
- GitHub CLI is installed locally but remains unauthenticated on this host, so private-repo workflow inspection still requires `gh auth login`.
