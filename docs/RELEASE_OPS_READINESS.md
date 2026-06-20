# Certa Release Ops Readiness

Last updated: 2026-06-20 02:15

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest `main` run `#41` on June 18, 2026 succeeded at `6f40b64`; latest overall run `#83` on June 20, 2026 also succeeded on a release-ops branch | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Staging and Apps Script deployment references exist outside this repo; current local provisioning check reports `G:` shared-drive paths unmounted | Blocked on local mount |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| Provisioning Git checks | `scripts\Test-CertaProjectProvisioning.ps1` now asks Git for repo and origin state, so normal clones and `.git` file worktrees are handled consistently | Ready |
| Release blocker repos | `MACROTBC` is clean on its release branch, while `WV_COURTHOUSE_RESEARCHER` has uncommitted local launch-toolkit edits and no configured remote in this host's checkout | Blocked for WV remote/upstream |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Local PowerShell runtime | Windows PowerShell is available and can run provisioning checks; `pwsh` is not on `PATH` in this shell | Ready with local fallback |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` public run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified overall public run: `#83`, branch `codex/release-control-worktree-provisioning-20260620`, commit `4edcd61`, created `2026-06-20T06:00:49Z`, conclusion `success`
- Latest verified overall public job: `powershell-and-docs` succeeded, including `Validate PowerShell syntax` and `Verify required control files`
- Local syntax verification on June 20, 2026: `scripts\Test-CertaProjectProvisioning.ps1` parses cleanly after Git worktree-safe remote detection changes
- Local provisioning check on June 20, 2026: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` runs and reports expected gaps for the unmounted shared drive plus missing `node`/`npm`

## Launch Blockers

1. Mount `G:\Shared drives\CERTASURV_PROJECT DRIVE` before shared-drive release checks or handoff staging.
2. Add Node/npm to `PATH` if local web/app checks must run from this control host.
3. Install PowerShell 7 or use the Windows PowerShell fallback command for local provisioning checks on this host.
4. Configure and publish `WV_COURTHOUSE_RESEARCHER` once its local launch-toolkit edits are reviewed; this checkout currently has no remote/upstream.
5. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
6. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
