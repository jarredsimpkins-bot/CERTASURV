# Certa Release Ops Readiness

Last updated: 2026-06-21 13:25

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest `main` run `#41` on June 18, 2026 succeeded at `6f40b64`; latest visible overall run during this pass is `#123` on June 21, 2026 and also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted on this host | Blocked locally |
| CERTARD and CERTASURV_WEB_APP | Both have GitHub remotes and are on `codex/certasurv-unified-forward`; current launch focus is push/review timing rather than new control-repo work | Review timing |
| MACROTBC | Git remote exists, but local release readiness is blocked by unrelated working-tree churn plus missing tracked `package.json` and `certasurv_shared_drive.json` | Blocked |
| WV_COURTHOUSE_RESEARCHER | Active release-toolkit edits exist on `codex/wv-courthouse-researcher-cabell-lessons`, but the inspected workspace has no configured remote/upstream | Blocked |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references remain a risk only where sibling docs have not been normalized | Ready with follow-up |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host as of June 21, 2026 | Blocked |
| Local shell tooling | `node`, `npm`, and `pwsh` are not on PATH in this shell | Blocked for local release checks |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials. Local handoff validation is blocked until the `G:` mount is restored on this host.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest visible overall public run during this pass: `#123`, branch `codex/release-control-webapp-path-guard-20260621-1320`, commit `2862f65`, created `2026-06-21T09:24:15Z`, conclusion `success`
- Recent visible successful release-ops/control runs also include `#122`, `#121`, `#120`, and `#119`
- Public REST API remains usable for public workflow visibility while `gh` is unauthenticated

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Resolve MACROTBC release blockers: restore or intentionally regenerate `C:\Users\SimpS\OneDrive\Documents\MACROTBC\package.json` and `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json`, then separate committed release fixes from generated/churn files.
4. Configure a GitHub remote/upstream for `WV_COURTHOUSE_RESEARCHER` before pushing its toolkit/runbook fixes for review.
5. Restore the `G:\Shared drives\CERTASURV_PROJECT DRIVE` mount before shared-drive handoff validation.
6. Restore Node/npm and `pwsh` PATH access before local release checks from this shell.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
- Treat CERTARD and CERTASURV_WEB_APP as review-timing items unless new workflow or remote evidence shows a release-blocking regression.
