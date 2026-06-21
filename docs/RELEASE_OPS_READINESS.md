# Certa Release Ops Readiness

Last updated: 2026-06-21 19:11

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest overall visible run `#139` on June 21, 2026 succeeded on branch `codex/release-control-webapp-path-guard-20260621-2300`; latest visible `main` run `#41` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but `G:\Shared drives\CERTASURV_PROJECT DRIVE` was not mounted during this pass | Blocked until drive mount returns |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references are retained only as fallback paths in helper scripts | Ready |
| CERTARD release lane | Local repo has `origin` set to `https://github.com/jarredsimpkins-bot/certard.git`; current worktree has unrelated/uncommitted generated changes outside this control repo | Ready for push/review timing after sibling worktree owner review |
| CERTASURV_WEB_APP release lane | Local repo has `origin` set to `https://github.com/jarredsimpkins-bot/certasurv-web-app.git`; current worktree has unrelated/uncommitted generated changes outside this control repo | Ready for push/review timing after sibling worktree owner review |
| MACROTBC release lane | Local repo has `origin` set to `https://github.com/jarredsimpkins-bot/macrotbc.git`, but provisioning reports missing `certasurv_shared_drive.json` and the shared-drive mount is unavailable | Blocked |
| WV courthouse researcher lane | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` exists, but no `origin`/upstream is configured in the local git checkout | Blocked |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials. During the June 21, 2026 pass, the shared-drive root itself was not mounted locally, so shared-drive contents were not modified or revalidated.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#139`, branch `codex/release-control-webapp-path-guard-20260621-2300`, commit `8761497`, created `2026-06-21T23:04:00Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Public REST API was used because `gh` is still unauthenticated on this host.

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Restore the `G:` shared-drive mount before staging or verifying generated handoff copies.
4. Restore or document `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json` before MACROTBC release packaging.
5. Configure `WV_COURTHOUSE_RESEARCHER` remote/upstream before treating that lane as release-ready.

## Non-Blocking Follow-Up

- Keep sibling worktree dirty-state review separate from this control repo; CERTARD and CERTASURV_WEB_APP already have remotes but contain local generated/uncommitted changes.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
