# Certa Release Ops Readiness

Last updated: 2026-06-22 06:31

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest visible run `#161` on June 22, 2026 succeeded on branch `codex/release-control-wv-path-inventory-20260622-0904`; recent release-ops runs `#157` through `#161` all succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but `G:` is not mounted in this session | Blocked locally |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is authenticated as `jarredsimpkins-bot` with `repo` scope and can inspect private run lists/logs | Ready |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC publication | Local MACROTBC branch is ahead of origin by two commits; latest private workflow run `27926919931` failed repo-readiness on folder-map parsing and shared config TBC control root | Blocked |
| WV courthouse publication | WV_COURTHOUSE_RESEARCHER release worktree has no configured Git remote | Blocked |
| CERTASURV_WEB_APP CI | Latest inspected private workflow run `27802010837` failed `tests/test_survey_storage.py::test_associated_drive_survey_export_dir_uses_active_project_lane` | Fix needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

During the June 22, 2026 local provisioning check, the `G:` shared-drive mount was not available in this shell. Treat the references as path-aligned but not locally revalidated until Google Drive for Desktop is mounted again.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest visible public run: `#161`, branch `codex/release-control-wv-path-inventory-20260622-0904`, commit `d1aae1f`, created `2026-06-22T10:09:31Z`, conclusion `success`
- Recent release-ops runs checked by public API on June 22, 2026: `#157`, `#158`, `#159`, `#160`, and `#161`, all `success`
- Latest verified prior `main` run in these docs remains `#40`, branch `main`, commit `e0cd20b`, created `2026-06-18T15:17:34Z`, conclusion `success`

## Launch Blockers

1. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
2. Add or confirm the intended remote for `WV_COURTHOUSE_RESEARCHER`, then push `codex/release-ops-wv-readiness-20260622-449926` for review.
3. Fix MACROTBC repo-readiness failures for folder-map parsing and shared config TBC control root before publishing the two local commits on `codex/certasurv-unified-forward`.
4. Fix CERTASURV_WEB_APP Ubuntu path handling in `associated_drive_survey_export_dir` before treating the pushed web-app branch as CI-clean.
5. Remount `G:\Shared drives\CERTASURV_PROJECT DRIVE` before final shared-drive handoff validation.

## Non-Blocking Follow-Up

- Keep using the public REST API as a fallback for public workflow visibility when GitHub CLI is unavailable.
- Leave existing dirty/untracked CERTARD and CERTASURV_WEB_APP workspace changes untouched unless a focused release task owns them.
