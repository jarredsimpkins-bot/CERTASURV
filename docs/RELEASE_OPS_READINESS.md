# Certa Release Ops Readiness

Last updated: 2026-06-22 01:25 ET

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest visible run `#151` on June 22, 2026 succeeded on `codex/release-control-wv-path-hardening-20260622`; recent runs `#147`-`#151` all succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Staging and Apps Script deployment references exist outside this repo and remain read-only during release ops; `G:` was not mounted in this shell | Blocked until mount returns |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| CERTARD and CERTASURV_WEB_APP launch posture | Current launch focus treats both as clean enough locally and mainly waiting on push/review timing | Ready for timing/review |
| MACROTBC release blocker | Local repo is present, but broad tracked deletions, generated/untracked outputs, and missing `certasurv_shared_drive.json` need reconciliation before release confidence | Blocked |
| WV_COURTHOUSE_RESEARCHER release blocker | Local repo is present with modified runbook, toolkit, workflow, and registry files pending review; no remote is configured locally | Blocked |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`
- `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER\docs\certasurv_toolkit_runbook.md`

These references remain the release handoff evidence set. Shared-drive paths could not be reverified in this shell because `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not currently mounted.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified visible public run: `#151`, branch `codex/release-control-wv-path-hardening-20260622`, commit `d2019e4`, created `2026-06-22T05:09:29Z`, conclusion `success`
- Recent visible public runs `#147`, `#148`, `#149`, `#150`, and `#151` all completed successfully.
- `gh auth status` still reports no authenticated GitHub host, so private workflow/log inspection remains blocked here.

## Launch Blockers

1. Reconnect Google Drive Desktop / `G:` before any shared-drive staging or generated handoff copy.
2. Reconcile and validate the MACROTBC working tree before treating TBC command-center/macro release packages as review-ready.
3. Review, smoke test, commit, and push the WV_COURTHOUSE_RESEARCHER toolkit/runbook changes after configuring its remote.
4. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
5. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Use `docs/RELEASE_BLOCKER_REGISTER.md` as the release-ops source of truth for blocker triage until MACROTBC and WV_COURTHOUSE_RESEARCHER are closed out.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
