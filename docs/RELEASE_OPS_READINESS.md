# Certa Release Ops Readiness

Last updated: 2026-06-20 15:07

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest overall run `#97` on June 20, 2026 succeeded; recent runs `#90` through `#97` are green | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Staging and Apps Script deployment references exist outside this repo, but current provisioning cannot see the `G:` shared-drive mount | Blocked pending Drive mount |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| MACROTBC release lane | Local repo exists with `origin` set to `macrotbc.git`, but it has release-generated artifacts, deleted tracked roots, untracked build/package outputs, and a missing `certasurv_shared_drive.json` | Blocked pending repo cleanup/review |
| WV courthouse research lane | Local repo exists on `codex/wv-courthouse-researcher-cabell-lessons`, but no `origin` remote was observed | Blocked pending remote/upstream setup |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host; public REST API remains usable for public control-workflow checks | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#97`, branch `codex/release-control-webapp-path-strict-20260620b`, commit `6b2ed53`, created `2026-06-20T18:32:19Z`, conclusion `success`
- Recent verified public runs: `#96` branch `codex/release-ops-wv-readiness-20260620`, `#95` branch `codex/release-ops-blocker-map-20260620b`, `#94` branch `codex/release-control-webapp-path-strict-20260620`, `#93` branch `codex/release-ops-wv-script-coverage-20260620`, `#92` branch `codex/certa-launch-provisioning-worktree-git`, `#91` branch `codex/release-ops-wv-inventory-20260620`, and `#90` branch `codex/release-control-git-state-hardening-20260620`; all concluded `success`
- Verified job summary for run `#97`: single job `powershell-and-docs` succeeded from `2026-06-20T18:32:21Z` to `2026-06-20T18:32:37Z`.

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Restore the `G:` shared-drive mount before shared-drive handoff or staging validation.
4. Cleanly classify MACROTBC's deleted tracked roots, missing shared-drive config, and generated build outputs before pushing its launch branch.
5. Create/confirm the `WV_COURTHOUSE_RESEARCHER` remote/upstream before WV release work can be pushed for review.
6. Restore Node/npm availability for web-app/tooling verification on this host, or keep that verification in GitHub Actions until local PATH is repaired.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
