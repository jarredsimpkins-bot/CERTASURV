# Git Situation

Last updated: 2026-06-17

## Fixed Locally

- Global git identity is set to `jarredsimpkins-bot`.
- Global git email is set to `286102097+jarredsimpkins-bot@users.noreply.github.com`.
- Default branch for new repositories is set to `main`.
- Git credential helper is set to `manager`.

## Live Remote Map

| Repo | Path | Current `origin` |
| --- | --- | --- |
| CERTAHEALTH | `C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH` | `https://github.com/jarredsimpkins-bot/CERTASURV.git` |
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | `https://github.com/jarredsimpkins-bot/certard.git` |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | `https://github.com/jarredsimpkins-bot/macrotbc.git` |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | `https://github.com/jarredsimpkins-bot/certasurv-automations.git` |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |

## Target Repo Map

| Local Repo | Target GitHub Remote | Notes |
| --- | --- | --- |
| CERTAHEALTH | `https://github.com/jarredsimpkins-bot/certahealth.git` | Planned dedicated repo; not the live public control remote yet |
| CERTARD | `https://github.com/jarredsimpkins-bot/certard.git` | Live |
| MACROTBC | `https://github.com/jarredsimpkins-bot/macrotbc.git` | Live |
| AUTOMATIONS | `https://github.com/jarredsimpkins-bot/certasurv-automations.git` | Live |
| CERTASURV_WEB_APP | `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` | Live; legacy `New project2` name should be treated as stale |

## Release Readiness Notes

- The public `CERTASURV` workflow `CertaHealth Control Checks` last completed successfully on 2026-06-17 at 09:12 UTC for branch `codex/certahealth-launch-readiness-20260617b`.
- Public GitHub Actions status is inspectable through the GitHub API without `gh` auth, but private-repo workflow inspection still needs authenticated access.
- Local control scripts should use `CERTASURV_WEB_APP` as the canonical web/dashboard workspace path.
