# Certa Release Ops Readiness

Last updated: 2026-06-20 15:45

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest visible run `#99` on June 20, 2026 succeeded on `codex/release-control-webapp-path-strict-20260620c`; latest visible `main` run `#41` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; release docs should treat legacy `New project2` references as fallback-only | Ready |
| Release blocker split | `CERTARD` and `CERTASURV_WEB_APP` have remotes and are mainly waiting on push/review timing; `MACROTBC` and `WV_COURTHOUSE_RESEARCHER` remain the substantive release blockers | In progress |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified visible public run: `#99`, branch `codex/release-control-webapp-path-strict-20260620c`, commit `1edd2f4`, created `2026-06-20T19:29:15Z`, conclusion `success`
- Latest verified visible `main` run: `#41`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Recent visible release-ops runs `#95`, `#96`, `#97`, `#98`, and `#99` all completed successfully on June 20, 2026.
- `gh auth status` still reports no logged-in GitHub hosts, so private workflow/log inspection remains blocked on this machine.

## Current Release Blocker Triage

| Repo | Current release-ops signal | Launch impact |
| --- | --- | --- |
| `CERTARD` | Remote is configured as `https://github.com/jarredsimpkins-bot/certard.git`; local working tree contains generated-output churn that should be reviewed before push | Mostly push/review timing |
| `CERTASURV_WEB_APP` | Remote is configured as `https://github.com/jarredsimpkins-bot/certasurv-web-app.git`; active workspace path is `CERTASURV_WEB_APP` | Mostly push/review timing |
| `MACROTBC` | Remote is configured, but the local tree has deleted tracked root files plus many untracked/generated outputs | Substantive release blocker |
| `WV_COURTHOUSE_RESEARCHER` | Current local workspace has release-readiness edits and no remote printed during the prior automation run | Substantive release blocker until remote/branch is confirmed and pushed |

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Resolve the `MACROTBC` tracked-file deletions and generated-output policy before treating it as release-ready.
4. Confirm and set the intended `WV_COURTHOUSE_RESEARCHER` remote/branch, then push its release-readiness docs for review.

## Non-Blocking Follow-Up

- Keep legacy `New project2` handling as script fallback only; operator-facing release docs should use `CERTASURV_WEB_APP`.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
