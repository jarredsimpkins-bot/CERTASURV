# Certa Release Ops Readiness

Last updated: 2026-06-23 00:58

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh` shows latest `CertaHealth Control Checks` run `#180` on June 23, 2026 succeeded on branch `codex/release-control-webapp-path-guard-20260623` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops; `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted in this worktree context | Blocked on local mount for live handoff |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh auth status` succeeds for `jarredsimpkins-bot` with `repo` scope, so private workflow summaries and failed logs are inspectable | Ready |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; `gh repo view jarredsimpkins-bot/certahealth` is missing or inaccessible from this host | Decision and/or remote creation needed |
| MACROTBC release workflow | Latest `CertaSurv TBC Cloud Readiness` run `#31` failed on June 23, 2026; all package checks passed except `Shared config TBC control root exists` | Blocked |
| WV courthouse researcher remote | Local `WV_COURTHOUSE_RESEARCHER` worktree has no `origin`; `gh repo view jarredsimpkins-bot/wv-courthouse-researcher` is missing or inaccessible | Blocked |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified control run: `#180`, branch `codex/release-control-webapp-path-guard-20260623`, commit `5fc5261`, created `2026-06-23T04:36:04Z`, conclusion `success`
- Latest verified release-ops refresh run: `#179`, branch `codex/release-ops-readiness-refresh-20260623`, commit `09b8ec6`, created `2026-06-23T04:03:35Z`, conclusion `success`
- Latest verified MACROTBC blocker run: `#31`, branch `codex/macro-launch-readiness-20260621`, commit `6fe6b0e`, created `2026-06-23T03:37:01Z`, conclusion `failure`; failed check: `Shared config TBC control root exists`
- Latest verified CERTARD run: `#31`, branch `main`, commit `b2d1e59`, created `2026-06-22T07:38:22Z`, conclusion `success`

## Launch Blockers

1. Fix the MACROTBC readiness failure around the shared config TBC control root, then rerun `CertaSurv TBC Cloud Readiness`.
2. Create or connect the WV_COURTHOUSE_RESEARCHER remote/upstream before release review can track its launch branch.
3. Decide whether the control repo should keep using public `CERTASURV.git` or move to a dedicated `certahealth.git` remote; the planned dedicated repo is not visible to `gh` from this host.
4. Mount or otherwise verify `G:\Shared drives\CERTASURV_PROJECT DRIVE` before copying any committed release documentation into live handoff folders.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using `gh run list` and `gh run view --log-failed` for private workflow evidence while the current authentication remains valid.
