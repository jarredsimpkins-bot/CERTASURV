# Certa Release Ops Readiness

Last updated: 2026-06-19 23:55

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest `main` run `#41` and latest visible overall run `#77` succeeded on June 20, 2026 | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Repo-local references remain read-only, but `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted on this host during this pass | Blocked until mount is available |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| Courthouse research repo | `WV_COURTHOUSE_RESEARCHER` exists locally on `codex/wv-courthouse-researcher-cabell-lessons`, but no `origin` is configured | Blocked |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`
- `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

During the June 19, 2026 local verification pass, the `G:` shared-drive mount and command-center folders were not available from this host, so external handoff verification is limited to repo-local path references until Drive Desktop is mounted again.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified visible overall run: `#77`, branch `codex/control-launch-path-guard-20260620`, commit `2825e5f`, created `2026-06-20T02:55:12Z`, conclusion `success`
- Verified public workflow signal: recent runs `#77`, `#76`, `#75`, `#74`, and `#73` all completed successfully

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Create or provide `https://github.com/jarredsimpkins-bot/wv-courthouse-researcher.git`, attach it as `origin`, and push `codex/wv-courthouse-researcher-cabell-lessons`.
3. Restore the `G:\Shared drives\CERTASURV_PROJECT DRIVE` mount before final handoff validation.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
