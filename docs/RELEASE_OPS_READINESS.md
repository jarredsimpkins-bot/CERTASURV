# Certa Release Ops Readiness

Last updated: 2026-06-20 22:20 ET

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest overall run `#107` on June 21, 2026 UTC succeeded on `codex/release-control-webapp-strict-main-20260621`; latest `main` run `#41` also succeeded | Ready with GitHub CLI blocker |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Repo-local references still point at the shared-drive system of record, but `Test-CertaProjectProvisioning.ps1` now reports the `G:` shared-drive mount missing on this host | Blocked locally |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; control scripts now use that canonical path instead of falling back to legacy `New project2` | Ready |
| CERTARD and CERTASURV_WEB_APP | Local release focus is push/review timing; both observed with configured `origin` remotes and dirty/generated local state outside this control repo | Ready with review timing |
| MACROTBC | Local repo remains on `codex/certasurv-unified-forward` with `origin` configured, but tracked root files are deleted locally and generated/cache outputs are mixed with command-center logs | Blocking |
| WV_COURTHOUSE_RESEARCHER | Local repo remains on `codex/wv-courthouse-researcher-cabell-lessons` with dirty docs/scripts and no configured remote observed again from this host on June 20, 2026 ET | Blocking |
| Local release tools | Windows PowerShell and `gh` are installed; `node`, `npm`, and `pwsh` are not currently on PATH | Blocked locally |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`
- `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER\docs\certasurv_toolkit_runbook.md`

These references still align on the expected shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#107`, branch `codex/release-control-webapp-strict-main-20260621`, commit `11baa9e`, created `2026-06-21T01:18:29Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified job summary for run `#107`: single job `powershell-and-docs` succeeded, including PowerShell syntax and required control-file checks

## Launch Blockers

1. Resolve MACROTBC release state: decide whether the local deletions of `.gitattributes`, `.gitignore`, `README.md`, `package.json`, and `certasurv_shared_drive.json` are intentional; preserve or discard the modified command-center usage CSVs; then publish the intended branch to `macrotbc.git`.
2. Resolve WV_COURTHOUSE_RESEARCHER remote readiness: set the GitHub remote, decide whether the dirty docs/scripts on `codex/wv-courthouse-researcher-cabell-lessons` are release material, push the branch, and add workflow visibility once available.
3. Restore the local release execution environment: remount `G:\Shared drives\CERTASURV_PROJECT DRIVE`, restore/regenerate `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json`, and put `node`, `npm`, and `pwsh` back on PATH or explicitly use recorded fallbacks.
4. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
5. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Blocker Triage Detail

### MACROTBC

Current local evidence from `C:\Users\SimpS\OneDrive\Documents\MACROTBC`:

- Branch: `codex/certasurv-unified-forward`, tracking `origin/codex/certasurv-unified-forward`.
- Remote: `origin` -> `https://github.com/jarredsimpkins-bot/macrotbc.git`.
- Tracked root files deleted locally: `.gitattributes`, `.gitignore`, `README.md`, `package.json`, and `certasurv_shared_drive.json`.
- Modified release-adjacent logs: `command_center/tbc/command_usage_log.csv` and `command_center/tbc/command_usage_summary.csv`.
- Untracked/generated buckets present: `%TEMP%`, `backups`, `dist`, `models`, Python `__pycache__` folders, AppSheet liaison briefs, and TBC video-intake outputs.

Release handoff should not push this tree as-is. First recover or intentionally commit root-file deletions, then split release docs/config/source from generated outputs. The missing `certasurv_shared_drive.json` also blocks local proof of the shared-drive target until restored or regenerated.

### WV_COURTHOUSE_RESEARCHER

Current local evidence from `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`:

- Branch: `codex/wv-courthouse-researcher-cabell-lessons`.
- Remote: no configured `origin` observed from this host.
- Dirty release-adjacent files: `docs/certasurv_project_prep_machine.md`, `docs/certasurv_toolkit_runbook.md`, `ortho_lidar_to_tbc_basemap/docs/workflow.md`, `scripts/certasurv_toolbox.ps1`, `scripts/certasurv_toolbox.py`, and `templates/certasurv_tool_registry.json`.

Release handoff should first add or verify `https://github.com/jarredsimpkins-bot/wv-courthouse-researcher.git`, then review and commit the dirty docs/scripts as a coherent release branch before any checklist marks WV as push-ready.

## Non-Blocking Follow-Up

- Keep CERTARD and CERTASURV_WEB_APP in push/review timing mode; avoid broad cleanup unless a specific release review asks for it.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
