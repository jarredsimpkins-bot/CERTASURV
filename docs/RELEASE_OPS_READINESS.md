# Certa Release Ops Readiness

Last updated: 2026-06-23 16:55

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh` shows latest `main` run `#41` on June 18, 2026 succeeded; latest observed feature-branch run `#202` on June 23, 2026 also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but the `G:` shared-drive mount was missing during the June 23 provisioning check | Blocked until mount restored |
| Web app workspace naming | Release scripts now resolve only `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; the provisioning check fails on legacy `New project2` script references | Ready |
| GitHub CLI access | `gh` is authenticated as `jarredsimpkins-bot`; visible token scopes are `gist`, `read:org`, and `repo` | Ready for repo inspection |
| Sibling repo focus | `CERTARD` and `CERTASURV_WEB_APP` are mostly push/review-timing items; `MACROTBC` and `WV_COURTHOUSE_RESEARCHER` remain the substantive release blockers | Blocked outside control repo |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified public `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified feature-branch run during this pass: `#202`, branch `codex/release-control-webapp-path-guard-20260623-1923`, commit `6edb114`, created `2026-06-23T20:37:53Z`, conclusion `success`
- Verified workflow coverage: single job `powershell-and-docs` validates tracked PowerShell parsing and required control files.

## Current Local Provisioning Signal

- `powershell -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` was run on June 23, 2026 and exited nonzero.
- Missing: `G:\Shared drives\CERTASURV_PROJECT DRIVE`, its command-center/project subfolders, and `npm` on PATH.
- Present: `git`, `gh`, `node`, `powershell`, `python`, local CERTAHEALTH/CERTARD/MACROTBC/AUTOMATIONS/CERTASURV_WEB_APP repositories, MACROTBC command manifest/config, CERTARD drive helpers, TBC live macros, TBC templates matrix, and Feature Definition Manager.
- `pwsh` is not on PATH in this shell; Windows PowerShell is available for local preflight, while GitHub Actions still runs the workflow with `pwsh` on `windows-latest`.
- Local `WV_COURTHOUSE_RESEARCHER` exists with uncommitted work but no configured remote; `gh repo view jarredsimpkins-bot/wv-courthouse-researcher` did not resolve a repository during this pass.

## Launch Blockers

1. Restore the `G:` shared-drive mount before any shared-drive handoff or generated-doc copy step.
2. Resolve `npm` PATH/tooling before web-app release checks that depend on Node package commands.
3. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
4. Finish MACROTBC and WV_COURTHOUSE_RESEARCHER blocker work in their own repos; WV currently has no configured local remote and the expected GitHub repository name did not resolve through `gh`.

## Non-Blocking Follow-Up

- Keep `gh auth status` in the release preflight so auth regressions are caught before private workflow/log inspection.
- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
