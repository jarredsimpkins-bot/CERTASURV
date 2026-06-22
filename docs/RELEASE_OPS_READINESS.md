# Certa Release Ops Readiness

Last updated: 2026-06-22 23:58

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest overall run `#153` on June 22, 2026 succeeded on a release-control branch; latest `main` run `#41` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but the `G:` shared drive mount was not available during the June 22 local provisioning check | Blocked until mount returns |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| CERTARD and web app launch lanes | `certard` and `certasurv-web-app` are no longer the substantive local blockers; remaining work is push/review timing | Ready for push/review timing |
| MACROTBC release lane | Local production repo exists with GitHub target `macrotbc.git`, but `certasurv_shared_drive.json` was missing during the June 22 local provisioning check and final review still needs private workflow/log visibility | Blocking release review |
| WV courthouse research lane | `WV_COURTHOUSE_RESEARCHER` is now tracked in control provisioning docs/scripts; local branch has uncommitted work and no visible remote from this host | Blocking remote/upstream readiness |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#153`, branch `codex/release-control-webapp-path-guard-20260622-run2`, commit `063913c`, created `2026-06-22T06:06:07Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Prior `main` run `#40`, branch `main`, commit `e0cd20b`, created `2026-06-18T15:17:34Z`, also concluded `success`

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Resolve MACROTBC release evidence: confirm `codex/certasurv-command-center` is pushed, private checks are green, and the command-center manifest/shared-drive config are ready for handoff.
3. Resolve WV_COURTHOUSE_RESEARCHER release evidence: add or confirm `origin` for `wv-courthouse-researcher.git`, push `codex/wv-courthouse-researcher-cabell-lessons`, and close/review the local uncommitted docs/tooling changes.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
5. Restore the local `G:` shared-drive mount before copying or validating handoff packages against the shared-drive system of record.

## Non-Blocking Follow-Up

- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
- Normalize Node/npm PATH separately from launch blocker closeout; the June 22 provisioning check found both missing from PATH even though web-app release focus is otherwise clean.
