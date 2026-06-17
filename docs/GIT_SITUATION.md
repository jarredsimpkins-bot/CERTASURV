# Git Situation

Last updated: 2026-06-17

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

## Planned Remote Names

| Local Repo | GitHub Remote |
| --- | --- |
| CERTAHEALTH | `https://github.com/jarredsimpkins-bot/certahealth.git` |
| CERTARD | `https://github.com/jarredsimpkins-bot/certard.git` |
| MACROTBC | `https://github.com/jarredsimpkins-bot/macrotbc.git` |
| AUTOMATIONS | `https://github.com/jarredsimpkins-bot/certasurv-automations.git` |
| CERTASURV_WEB_APP | `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |

All planned repositories now exist. `CERTASURV` is public; the remaining launch support repositories are private.

## June 17 Notes

- `origin/main` for this repo still points to commit `b4ca310c3ccf12cf4e6807e8aee3e830be8583cc`; newer launch-readiness work currently lives on separate `codex/*` branches rather than on `main`.
- The local rename to `CERTASURV_WEB_APP` is live on this machine, and `C:\Users\SimpS\OneDrive\Documents\New project2` does not exist.
- CERTAHEALTH still uses the public `CERTASURV.git` remote today; the planned `certahealth.git` cutover remains future-state.
- `gh auth status` currently reports no authenticated GitHub host, which blocks private Actions and artifact review from this environment.
