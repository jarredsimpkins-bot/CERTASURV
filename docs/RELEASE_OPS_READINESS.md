# Certa Release Ops Readiness

Last updated: 2026-06-23 10:30

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh` shows the latest release-control feature runs on June 23, 2026 succeeded, including run `28032389759`; latest `main` run remains June 18, 2026 success | Ready; merge/push timing remains |
| Control repo docs | Core launch docs are present and tracked by workflow required-file validation, including a repo-local launch checklist and legacy path guard | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; control scripts now avoid the legacy `New project2` fallback | Ready |
| GitHub CLI access | `gh auth status` succeeds for `jarredsimpkins-bot`; token has `repo` scope | Ready for private repo inspection |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| Stack blocker split | `CERTARD` and `CERTASURV_WEB_APP` mainly need push/review timing; `MACROTBC` and `WV_COURTHOUSE_RESEARCHER` still carry substantive release blockers | Active focus |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified release-control feature run: `28032389759`, branch `codex/release-control-webapp-path-guard-20260623-r3`, commit `a7ee586`, created `2026-06-23T14:08:44Z`, conclusion `success`
- Verified job summary for run `28032389759`: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax`, `Verify required control files`, and `Block legacy web app script paths`
- Latest verified `main` run: `27773432493`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`

## Launch Blockers

1. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
2. Finish MACROTBC command-center/TBC production review before treating the TBC integration lane as release-ready.
3. Resolve WV_COURTHOUSE_RESEARCHER remote/readiness approval and its current dirty working tree before launch handoff.
4. Mount or verify `G:\Shared drives\CERTASURV_PROJECT DRIVE` before copying release materials into shared-drive handoff locations.

## Non-Blocking Follow-Up

- Push/review timing remains for mostly clean CERTARD and CERTASURV_WEB_APP release branches.
- Keep the workflow legacy-path guard in place so `New project2` does not return to control scripts.
