# Certa Release Ops Readiness

Last updated: 2026-06-20 08:42

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest visible overall run `#94` on June 20, 2026 succeeded on `codex/release-control-webapp-path-strict-20260620`; latest local `origin/main` is `6f40b64` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` visibility is unresolved from this unauthenticated host | Decision needed |
| MACROTBC release lane | Local repo is on `codex/certasurv-unified-forward` with uncommitted changes in `README.md`, `package.json`, and `scripts/Test-CertaSurvRepoReadiness.ps1`; command-center manifest exists locally | Substantive blocker |
| WV courthouse researcher lane | Local `WV_COURTHOUSE_RESEARCHER` workspace exists with uncommitted runbook/tooling changes and no remote surfaced by the local status check | Substantive blocker |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#94`, branch `codex/release-control-webapp-path-strict-20260620`, commit `7285e83`, created `2026-06-20T12:08:27Z`, conclusion `success`
- Latest verified public `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Recent preceding public runs `#93`, `#92`, `#91`, and `#90` also completed successfully on June 20, 2026 feature branches
- Latest local `origin/main`: `6f40b64`, `docs: refresh control workflow status`

## Current Host Provisioning Signal

- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` ran on June 20, 2026 and exited nonzero because the shared drive mount paths were unavailable and `node`/`npm` were not on PATH.
- The same check confirmed local repo folders and remotes for `CERTAHEALTH`, `CERTARD`, `MACROTBC`, `AUTOMATIONS`, and `CERTASURV_WEB_APP`, plus the `MACROTBC` command manifest and shared-drive config.
- `pwsh` is not on PATH on this host; use Windows PowerShell locally unless PowerShell 7 is installed, while GitHub Actions continues to run `pwsh` on `windows-latest`.

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover, then verify/create the target with authenticated GitHub access.
3. Clear or intentionally commit/review the active `MACROTBC` release-lane changes before using it as the launch source of truth.
4. Assign/publish the `WV_COURTHOUSE_RESEARCHER` upstream and finish the active runbook/tooling changes before treating it as release-ready.
5. Restore the shared-drive mount and normalize Node/npm PATH before local release verification is considered complete.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
