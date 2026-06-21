# Release Blocker Exit Criteria - 2026-06-21

Use this as the short, operator-facing definition of "done enough for launch review" for the current Certa/CertaSurv release blockers.

## Current Readiness Split

| Project | Current lane | Exit criteria |
| --- | --- | --- |
| CERTARD | Push/review timing | Branch to review is selected, generated/unrelated churn is excluded, and any release notes copied to shared drive come from committed repo files |
| CERTASURV_WEB_APP | Push/review timing | Branch to review is selected, `node`/`npm` checks can run from the release shell, and renamed workspace references use `CERTASURV_WEB_APP` |
| MACROTBC | Release blocker | Missing tracked `package.json` and `certasurv_shared_drive.json` are restored or intentionally regenerated, generated output is separated from source changes, and repo checks can run before push |
| WV_COURTHOUSE_RESEARCHER | Release blocker | GitHub remote/upstream is configured, active toolkit/runbook edits are pushed to a review branch, and the TBC basemap/runbook path changes are reviewed together |

## Host-Level Gates

| Gate | Exit criteria |
| --- | --- |
| GitHub CLI | `gh auth status` succeeds with repo and workflow access before private workflow/log inspection |
| Shared drive | `G:\Shared drives\CERTASURV_PROJECT DRIVE` is mounted before handoff validation or generated-doc copy operations |
| Node/npm | `node` and `npm` resolve on PATH before web-app release checks are treated as complete |
| PowerShell Core | `pwsh` resolves on PATH before local checks are treated as equivalent to GitHub Actions |
| Control repo remote | Release owner decides whether `CERTAHEALTH` stays on public `CERTASURV.git` or moves to dedicated `certahealth.git` before launch cutover |

## Review Order

1. Unblock MACROTBC source/config state first because it carries the highest TBC integration release risk.
2. Configure the WV_COURTHOUSE_RESEARCHER remote next so current toolkit edits can enter normal review.
3. Schedule CERTARD and CERTASURV_WEB_APP push/review after the blocker repos have a clean path, unless a new workflow failure changes their status.
