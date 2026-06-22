# Certa Release Ops Readiness

Last updated: 2026-06-22 03:33

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest visible run `#155` on June 22, 2026 succeeded; current `main` tip is `6f40b64` and the latest visible release-blocker run `#154` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Repo-local references exist, but this host currently lacks the `G:` shared-drive mount for live handoff verification | Blocked on mount |
| Web app workspace naming | Release scripts now use only `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; retired `New project2` fallback paths are blocked from control tooling | Ready |
| CERTARD / CERTASURV_WEB_APP | Local launch focus is clean; both mainly need push/review timing rather than more control-repo changes | Ready for timing decision |
| MACROTBC | Production integration remains a substantive blocker until branch/release evidence is reviewed with authenticated private-repo access | Blocked |
| WV_COURTHOUSE_RESEARCHER | Courthouse researcher release lane remains a substantive blocker until remote/readiness evidence is visible and reviewed | Blocked |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Host provisioning | `scripts\Test-CertaProjectProvisioning.ps1 -Detailed` reports missing shared-drive mount, missing MACROTBC shared-drive config, and `node`/`npm` absent from PATH | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

Live shared-drive verification was not possible during the June 22, 2026 pass because `G:\Shared drives\CERTASURV_PROJECT DRIVE` was not mounted on this host.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Current checked control commit during this pass: `6f40b64`, matching `origin/main`
- Latest verified visible public run: `#155`, branch `codex/release-control-webapp-path-guard-20260622-impl`, commit `34fdfb0`, created `2026-06-22T07:05:34Z`, conclusion `success`
- Latest verified visible release-blocker run: `#154`, branch `codex/release-ops-wv-macrotbc-readiness-20260622-2358`, commit `4d3fe50`, created `2026-06-22T06:33:52Z`, conclusion `success`
- Latest verified `main` run remains `#40`, branch `main`, commit `e0cd20b`, created `2026-06-18T15:17:34Z`, conclusion `success`

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Review and close MACROTBC release evidence, including command-center manifest, private workflow status, branch target, and install/runbook readiness.
4. Review and close WV_COURTHOUSE_RESEARCHER release evidence, including remote/upstream mapping and any workflow or handoff-output status.
5. Restore the shared-drive mount and MACROTBC shared-drive config before final handoff verification.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
