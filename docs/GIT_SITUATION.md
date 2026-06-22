# Git Situation

Last updated: 2026-06-22

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
| WV_COURTHOUSE_RESEARCHER release worktree | `C:\Users\SimpS\.codex\worktrees\79c0\WV_COURTHOUSE_RESEARCHER` | No remote configured in checked release worktree |

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
- Public control workflow visibility is available through the GitHub REST API when GitHub CLI is unavailable.
- GitHub CLI is authenticated locally as `jarredsimpkins-bot` with `repo` scope during the June 22, 2026 release-ops check, so private run lists and failed logs are inspectable from this host.
- `WV_COURTHOUSE_RESEARCHER` has local release-readiness docs committed on branch `codex/release-ops-wv-readiness-20260622-449926`, but the checked worktree has no upstream remote to push.
- `MACROTBC` is on `codex/certasurv-unified-forward` and was two commits ahead of `origin/codex/certasurv-unified-forward` during the June 22, 2026 release-ops check.
- Latest inspected MACROTBC private workflow run `27926919931` failed repo-readiness on folder-map parsing and the shared config TBC control root check.
- Latest inspected CERTASURV_WEB_APP private workflow run `27802010837` failed `tests/test_survey_storage.py::test_associated_drive_survey_export_dir_uses_active_project_lane` on Ubuntu path handling.
