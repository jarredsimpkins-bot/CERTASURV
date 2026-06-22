# Git Situation

Last updated: 2026-06-22 12:20

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
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | Local branch `codex/wv-courthouse-researcher-cabell-lessons`; upstream not shown by current status |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-automations.git` |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |

## Planned Remote Names

| Local Repo | GitHub Remote |
| --- | --- |
| CERTAHEALTH | `https://github.com/jarredsimpkins-bot/certahealth.git` |
| CERTARD | `https://github.com/jarredsimpkins-bot/certard.git` |
| MACROTBC | `https://github.com/jarredsimpkins-bot/macrotbc.git` |
| WV_COURTHOUSE_RESEARCHER | Remote target needs confirmation before launch handoff |
| AUTOMATIONS | `https://github.com/jarredsimpkins-bot/certasurv-automations.git` |
| CERTASURV_WEB_APP | `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` |

All planned repositories now exist. `CERTASURV` is public; the remaining launch support repositories are private.

## Current Release-Ops Notes

- `CERTAHEALTH` currently pushes to public `CERTASURV.git`, but the planned dedicated target remains `certahealth.git`.
- `CERTASURV_WEB_APP` is the active local workspace name; any lingering `New project2` references should be treated as legacy docs only.
- GitHub CLI is installed locally but was unauthenticated during the June 17, 2026 release-ops pass, so private-repo workflow inspection still requires `gh auth login`.
- MACROTBC and WV_COURTHOUSE_RESEARCHER are the active release-blocker repos as of June 22, 2026; close their repo-local diffs before treating the stack as launch-ready.
- The current provisioning run also reports the `G:` shared-drive mount missing and MACROTBC `certasurv_shared_drive.json` missing, so handoff validation is blocked until those are restored or intentionally replaced.
