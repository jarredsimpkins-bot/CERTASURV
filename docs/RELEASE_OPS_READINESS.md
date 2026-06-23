# Certa Release Ops Readiness

Last updated: 2026-06-23 08:05

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Latest visible `CertaHealth Control Checks` run observed by `gh run list` on June 23, 2026 succeeded for `codex/release-control-webapp-path-guard-20260623-automation-run` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but `G:\Shared drives\CERTASURV_PROJECT DRIVE` was not mounted during this run | Blocked until drive mount returns |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; control scripts now use that canonical path only | Ready |
| GitHub CLI access | `gh auth status` reports authenticated access for `jarredsimpkins-bot` over HTTPS with `repo` scope | Ready |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release lane | Local repo is on `codex/certasurv-unified-forward` with remote tracking, but has an uncommitted `command_center/tbc/command_usage_log.csv` change | Blocked pending review/cleanup |
| WV_COURTHOUSE_RESEARCHER release lane | Local repo is on `codex/wv-courthouse-researcher-cabell-lessons`, has multiple uncommitted docs/scripts/templates, and no remote was listed by `git remote -v` | Blocked pending remote/upstream and worktree cleanup |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified visible run: database id `28010374469`, branch `codex/release-control-webapp-path-guard-20260623-automation-run`, commit `a6cd0dcc76ab8c7ab4b41417701b88c19a7efa1b`, created `2026-06-23T07:40:37Z`, conclusion `success`
- Recent visible release-ops run: database id `28008751810`, branch `codex/release-ops-wv-blocker-refresh-20260623-0325`, commit `176ecb7a8e1e412e5c84677a336711082039e5ee`, conclusion `success`
- Local provisioning test on June 23, 2026 exited nonzero because the `G:` shared-drive mount and `npm` on PATH were missing; project repo paths and Git remotes otherwise checked OK for the control inventory.

## Launch Blockers

1. Restore or verify the `G:\Shared drives\CERTASURV_PROJECT DRIVE` mount before any shared-drive handoff or staging pass.
2. Clean or intentionally commit the MACROTBC `command_usage_log.csv` change before release tagging/review.
3. Decide the WV_COURTHOUSE_RESEARCHER remote/upstream path and reconcile its uncommitted release-readiness edits.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Put `npm` on PATH for shells that run web-app release checks, or document the bundled Node/npm invocation path.
- Keep using `gh run list` for workflow visibility while authenticated; fall back to public REST only if auth disappears.
