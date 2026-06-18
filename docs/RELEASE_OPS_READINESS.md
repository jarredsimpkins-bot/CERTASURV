# Certa Release Ops Readiness

Last updated: 2026-06-18 13:48

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest overall run `#43` on June 18, 2026 succeeded; latest `main` run `#41` on June 18, 2026 also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but `gh auth status` still reports no logged-in host on June 18, 2026 | Blocked |
| Local host provisioning | `scripts/Test-CertaProjectProvisioning.ps1 -Detailed` passes path and mount checks, but `node` and `npm` are still missing from `PATH` | Ready with host gap |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#43`, branch `codex/wv-courthouse-launch-alignment-20260618`, commit `fb84a2d`, created `2026-06-18T17:30:50Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified job summary for run `#41`: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax` and `Verify required control files`

## Local Provisioning Signal

- Command run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed`
- Verified local repo/workspace paths: `CERTAHEALTH`, `CERTARD`, `MACROTBC`, `AUTOMATIONS`, and `CERTASURV_WEB_APP`
- Verified external path dependencies: shared-drive mount, command-center root, Apps Script deploy notes, and command manifest
- Remaining host gaps: `node` and `npm` are not on `PATH` on this release-ops host as of June 18, 2026

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
- Add `node` and `npm` to the standard release-ops laptop `PATH` if this host will also be used for web-app release or validation work.
