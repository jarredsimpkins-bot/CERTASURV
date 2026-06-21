# Certa Release Ops Readiness

Last updated: 2026-06-21 09:10

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest overall run `#119` on June 21, 2026 succeeded on branch `codex/release-control-webapp-path-guard-20260621b`; prior release-ops blocker-map run `#118` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo; current host does not have `G:` mounted | Ready with external dependency |
| Web app workspace naming | Release scripts now use `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` directly, and the control workflow guards against reintroducing `New project2` script references | Ready after this alignment |
| CERTARD and web app lanes | Both have configured origins and remain push/review-timing lanes, but current sibling worktrees show pre-existing local churn that was not modified here | Ready pending review timing |
| MACROTBC lane | Remote exists, but production integration hardening and workflow evidence remain launch-critical | Blocked |
| WV courthouse research lane | Local workspace exists with active branch `codex/wv-courthouse-researcher-cabell-lessons`, local changes, and no observed `origin` | Blocked |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Local Node tooling | `node` and `npm` were not on PATH during the June 21 provisioning check | Blocked for local web tooling |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#119`, branch `codex/release-control-webapp-path-guard-20260621b`, commit `9f157f9`, created `2026-06-21T07:22:17Z`, conclusion `success`
- Latest verified release-ops blocker-map run: `#118`, branch `codex/release-ops-wv-blocker-alignment-20260621`, commit `8c3d5c6`, created `2026-06-21T06:26:38Z`, conclusion `success`
- Verified job summary for run `#119`: single job `powershell-and-docs` succeeded at `2026-06-21T07:22:35Z`

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Finish MACROTBC release-blocking production integration review before declaring the TBC lane launch-ready.
4. Create or confirm the `WV_COURTHOUSE_RESEARCHER` upstream, set `origin`, and push its active branch for review.
5. Restore local launch host prerequisites: mount `G:`, restore `MACROTBC\certasurv_shared_drive.json`, and put `node`/`npm` on PATH or use the explicit Node install path.

## Non-Blocking Follow-Up

- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
