# Certa Release Ops Readiness

Last updated: 2026-06-22 14:26

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | GitHub CLI shows latest visible `CertaHealth Control Checks` run `27974270514` on June 22, 2026 succeeded on branch `codex/release-control-webapp-path-guard-20260622-141558` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops, but the `G:` shared-drive mount is currently missing on this host | Blocked for local handoff copy/stage |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh auth status` now shows account `jarredsimpkins-bot` authenticated for HTTPS Git operations with `repo`, `read:org`, and `gist` scopes; explicit `workflow` scope is not present | Ready for read/repo work; scope review before workflow writes |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release lane | Local repo is clean and has `origin` -> `https://github.com/jarredsimpkins-bot/macrotbc.git`, but latest private readiness workflow is failing | Blocked |
| WV courthouse researcher lane | Local repo exists at `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`, has local changes, and has no `origin`; expected GitHub repo name was not resolvable | Blocked |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

Current local provisioning check on June 22, 2026 found the shared-drive filesystem mount missing at `G:\Shared drives\CERTASURV_PROJECT DRIVE`, so release operators must restore Google Drive for Desktop or use browser/API handoff until the mount returns.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified visible control run: `27974270514`, branch `codex/release-control-webapp-path-guard-20260622-141558`, commit `a93a0d17bac095386acd0968ca7404e502972ba7`, created `2026-06-22T18:16:43Z`, conclusion `success`
- Verified job summary for run `27974270514`: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax`, `Block legacy web app workspace path in scripts`, and `Verify required control files`
- Latest visible MACROTBC run: `27974315508`, branch `codex/certasurv-unified-forward`, created `2026-06-22T18:17:31Z`, conclusion `failure`; failed required end-to-end checks are `Command registry`, `TBC operator workflow HTML`, and `TBC tabulated workflow`
- Latest visible CERTARD run on `main`: `27937122339`, created `2026-06-22T07:38:22Z`, conclusion `success`
- Latest visible Drive Automation run: `27943592552`, branch `codex/certasurv-unified-forward`, created `2026-06-22T09:39:09Z`, conclusion `success`
- Latest visible web app run: `27802010837`, branch `codex/certasurv-unified-forward`, created `2026-06-19T02:39:15Z`, conclusion `failure`; failed test was `tests/test_survey_storage.py::test_associated_drive_survey_export_dir_uses_active_project_lane`

## Launch Blockers

1. Fix MACROTBC readiness failures for command registry, operator workflow HTML, and tabulated workflow before treating the TBC production integration lane as release-ready.
2. Assign or create the WV_COURTHOUSE_RESEARCHER remote, then decide which local changes belong in the launch branch before pushing.
3. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
4. Review whether the authenticated GitHub token needs `workflow` scope for release operations that edit or dispatch workflows.
5. Restore the local `G:` shared-drive mount before any local copy/stage release handoff.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Before final web-app release review, reconcile the local dirty tree in `CERTASURV_WEB_APP` and rerun the failing survey storage test on the active branch.
