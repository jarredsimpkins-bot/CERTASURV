# Git Situation

Last updated: 2026-06-18 21:45 EDT

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
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | No `origin` remote configured |

## Planned Remote Names

| Local Repo | GitHub Remote |
| --- | --- |
| CERTAHEALTH | `https://github.com/jarredsimpkins-bot/certahealth.git` |
| CERTARD | `https://github.com/jarredsimpkins-bot/certard.git` |
| MACROTBC | `https://github.com/jarredsimpkins-bot/macrotbc.git` |
| AUTOMATIONS | `https://github.com/jarredsimpkins-bot/certasurv-automations.git` |
| CERTASURV_WEB_APP | `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |
| WV_COURTHOUSE_RESEARCHER | `https://github.com/jarredsimpkins-bot/wv-courthouse-researcher.git` |

`CERTASURV` is public. The current launch assumption is that the remaining support repositories stay private, but `WV_COURTHOUSE_RESEARCHER` still needs an upstream target confirmed and connected locally.

## Current Release-Ops Notes

- `CERTAHEALTH` currently pushes to public `CERTASURV.git`, but the planned dedicated target remains `certahealth.git`.
- `CERTARD` and `CERTASURV_WEB_APP` are both clean on branch `codex/certasurv-unified-forward` and only need push/review timing.
- `MACROTBC` is on branch `codex/certasurv-unified-forward` with uncommitted tracked edits and untracked files, so it remains a substantive release blocker.
- `WV_COURTHOUSE_RESEARCHER` is on branch `codex/wv-courthouse-researcher-cabell-lessons` with active edits and no `origin`, so upstream creation/selection is still required.
- `CERTASURV_WEB_APP` is the active local workspace name; any lingering `New project2` references should be treated as legacy docs only.
- GitHub CLI is installed locally but remains unauthenticated on this host, so private-repo workflow inspection still requires `gh auth login`.
