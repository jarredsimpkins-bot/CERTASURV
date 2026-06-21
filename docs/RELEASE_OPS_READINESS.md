# Certa Release Ops Readiness

Last updated: 2026-06-21 04:45

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest visible runs `#117` through `#121` on June 21, 2026 all completed successfully; latest visible run is `#121` on `codex/release-control-webapp-path-guard-20260621-rerun` | Ready |
| Control repo docs | Core launch docs are present in repo and tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but the `G:` shared-drive mount is currently missing on this host | Blocked locally |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; release scripts now use this path directly and CI guards against `New project2` script references | Ready |
| CERTARD and CERTASURV_WEB_APP | Both have GitHub remotes and are on `codex/certasurv-unified-forward`; local worktrees contain substantial unrelated churn that should be reviewed before release pushes | Review timing |
| MACROTBC | Git remote exists, but release readiness is blocked by local churn and missing tracked shared-drive config `certasurv_shared_drive.json` | Blocked |
| WV_COURTHOUSE_RESEARCHER | Local release-toolkit edits exist on `codex/wv-courthouse-researcher-cabell-lessons`, but no remote is configured in the inspected workspace | Blocked |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host as of June 21, 2026 | Blocked |
| Node/npm shell access | `node` and `npm` are not on PATH in this shell | Blocked for web tooling |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest visible public run: `#121`, branch `codex/release-control-webapp-path-guard-20260621-rerun`, commit `510f658`, created `2026-06-21T08:25:03Z`, conclusion `success`
- Recent visible successful runs: `#120` on `codex/release-ops-remote-readiness-20260621`, `#119` on `codex/release-control-webapp-path-guard-20260621b`, `#118` on `codex/release-ops-wv-blocker-alignment-20260621`, and `#117` on `codex/release-control-webapp-path-guard-20260621-mainline`
- Public API remains usable for public control workflow visibility while `gh` is unauthenticated

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Resolve MACROTBC release blockers: restore or replace `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json`, then separate committed release fixes from local generated/churn files.
4. Configure a GitHub remote/upstream for `WV_COURTHOUSE_RESEARCHER` before pushing its toolkit/runbook fixes for review.
5. Restore the `G:\Shared drives\CERTASURV_PROJECT DRIVE` mount before shared-drive handoff validation.
6. Restore Node/npm PATH access before running web-app release checks from this shell.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name; the control repo now guards its scripts.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
