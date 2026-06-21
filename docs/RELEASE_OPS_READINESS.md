# Certa Release Ops Readiness

Last updated: 2026-06-21 06:35 ET

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest visible overall run `#125` on June 21, 2026 succeeded on `codex/release-control-webapp-path-guard-20260621-automated`; latest verified `main` run remains `#41` on June 18, 2026 at `6f40b64` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo; local validation requires the `G:` shared-drive mount | Blocked locally if mount is absent |
| CERTARD and CERTASURV_WEB_APP | Both active workspaces have GitHub remotes; current launch focus is push/review timing rather than new control-repo repair | Review timing |
| MACROTBC | Git remote exists, but release readiness is still blocked by local working-tree churn and missing tracked package/shared-drive config files in the inspected workspace | Blocked |
| WV_COURTHOUSE_RESEARCHER | Active toolkit/runbook edits exist locally, but no remote/upstream was configured in the inspected workspace | Blocked |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; control scripts no longer fall back to retired `New project2` | Ready |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host as of June 21, 2026 | Blocked |
| Local Node/npm tooling | `node` and `npm` are not on PATH in this shell, even though GitHub Actions remains the preferred heavy-check lane | Blocked for local app checks |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials. Release-ops workers should keep these paths read-only unless copying generated documentation from committed repo files.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest visible overall public run during this pass: `#125`, branch `codex/release-control-webapp-path-guard-20260621-automated`, commit `8198c4f`, created `2026-06-21T10:24:16Z`, conclusion `success`
- Recent visible successful release/control runs also include `#124`, `#123`, `#122`, and `#121`
- Public REST API remains usable for public workflow visibility while `gh` is unauthenticated

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Resolve MACROTBC release blockers: restore or intentionally regenerate `C:\Users\SimpS\OneDrive\Documents\MACROTBC\package.json` and `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json`, then separate committed release fixes from generated/churn files.
4. Configure a GitHub remote/upstream for `WV_COURTHOUSE_RESEARCHER` before pushing its toolkit/runbook fixes for review.
5. Restore the `G:\Shared drives\CERTASURV_PROJECT DRIVE` mount before shared-drive handoff validation when absent.
6. Restore `node` and `npm` PATH access before local web/app release checks; keep GitHub Actions as the authoritative cloud check after push.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
- Treat CERTARD and CERTASURV_WEB_APP as review-timing items unless new workflow or remote evidence shows a release-blocking regression.
