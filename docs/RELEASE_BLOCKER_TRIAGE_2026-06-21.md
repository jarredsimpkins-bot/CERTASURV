# Release Blocker Triage - 2026-06-21

This note records the release-ops evidence checked from the control repo worktree on June 21, 2026. It is repo-local documentation only; no live shared-drive contents were modified.

## Current Readiness Call

| Lane | Evidence Checked | Launch Impact |
| --- | --- | --- |
| CERTAHEALTH control repo | `origin` points at `https://github.com/jarredsimpkins-bot/CERTASURV.git`; public workflow API shows `main` run `#41` succeeded and latest visible feature run `#113` succeeded | Control repo is green, but final remote destination is still a launch decision |
| CERTARD | Local repo has an `origin` remote at `https://github.com/jarredsimpkins-bot/certard.git` | Push/review timing remains the main release action |
| CERTASURV_WEB_APP | Local repo has an `origin` remote at `https://github.com/jarredsimpkins-bot/certasurv-web-app.git`; control scripts use `CERTASURV_WEB_APP` | Push/review timing remains the main release action |
| MACROTBC | Local repo has an `origin` remote at `https://github.com/jarredsimpkins-bot/macrotbc.git`, but the working tree has many local changes and `package.json` / `certasurv_shared_drive.json` are absent from the working tree during this check | Substantive release blocker; validation cannot be treated as complete |
| WV_COURTHOUSE_RESEARCHER | Local branch `codex/wv-courthouse-researcher-cabell-lessons` has active edits and no configured remote | Substantive release blocker; cloud review and push are blocked |
| Shared-drive handoff | `Test-CertaProjectProvisioning.ps1 -Detailed` reports `G:\Shared drives\CERTASURV_PROJECT DRIVE` missing | Shared-drive release staging cannot be verified from this host right now |
| Local toolchain | `gh` installed but unauthenticated; `node`, `npm`, and `pwsh` are not on PATH in this shell | Private workflow inspection and local JS/PowerShell Core validation are blocked |

## Immediate Release Order

1. Keep CERTAHEALTH control-doc changes repo-local and push them for review against the current public control repo.
2. Resolve MACROTBC local readiness before launch review: restore or intentionally replace `package.json`, restore or regenerate `certasurv_shared_drive.json`, then run the repo readiness checks.
3. Give `WV_COURTHOUSE_RESEARCHER` a remote or record a launch decision that it remains local-only, then push the active branch if cloud review is required.
4. Restore shared-drive mount access before copying generated release notes or validating staged handoff paths.
5. Authenticate `gh` with repo/workflow scopes before relying on private workflow logs or review-thread inspection.

## Verification Performed

- `git status --short --branch` in the control worktree: clean before edits, detached at `origin/main`.
- GitHub public API for `certahealth-control-checks.yml`: latest `main` run `#41` succeeded; latest visible overall run `#113` succeeded.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed`: failed on shared-drive mount, MACROTBC shared-drive config, and Node/npm PATH.
- `gh auth status`: not logged in.
- Sibling repo remote/status inspection for `CERTARD`, `MACROTBC`, `WV_COURTHOUSE_RESEARCHER`, and `CERTASURV_WEB_APP`.
