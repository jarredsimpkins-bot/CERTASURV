# Certa Release Ops Readiness

Last updated: 2026-06-18 21:45 EDT

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public GitHub API shows latest overall run `#59` succeeded on branch `codex/remove-legacy-webapp-fallback-20260618`; latest `main` run `#41` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## Cross-Repo Launch Lanes

| Repo | Verified local state | Launch impact |
| --- | --- | --- |
| CERTARD | Branch `codex/certasurv-unified-forward` is clean and `ahead 5` of `origin/codex/certasurv-unified-forward` | Ready for push/review timing only |
| CERTASURV_WEB_APP | Branch `codex/certasurv-unified-forward` is clean and `ahead 2` of `origin/codex/certasurv-unified-forward` | Ready for push/review timing only |
| MACROTBC | Branch `codex/certasurv-unified-forward` is `ahead 3` but has tracked edits plus untracked TBC parser assets | Substantive release blocker until work is triaged, committed, and reviewed |
| WV_COURTHOUSE_RESEARCHER | Branch `codex/wv-courthouse-researcher-cabell-lessons` has tracked edits and no `origin` remote configured | Substantive release blocker until upstream/repo target is created and the branch is reviewed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials. `WV_COURTHOUSE_RESEARCHER` also exists locally at `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#59`, branch `codex/remove-legacy-webapp-fallback-20260618`, commit `e053ee9`, created `2026-06-19T01:38:03Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified job summary for run `#59`: single job `powershell-and-docs` succeeded from `2026-06-19T01:38:05Z` to `2026-06-19T01:38:20Z`, including PowerShell syntax and required-file validation

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Triage and commit the current `MACROTBC` working tree so its ahead branch can be pushed for release review.
4. Create or choose the upstream target for `WV_COURTHOUSE_RESEARCHER`, add `origin`, and review the current branch before launch.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
