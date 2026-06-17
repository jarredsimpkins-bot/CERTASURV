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

## Launch Readiness Note

`CERTAHEALTH` is still shown above with the legacy public `CERTASURV` remote in local status captures. The intended launch target for this repo is `https://github.com/jarredsimpkins-bot/certahealth.git`; use `scripts/Set-CertaGitRemotes.ps1` when the local checkout should be flipped to the dedicated repo.
