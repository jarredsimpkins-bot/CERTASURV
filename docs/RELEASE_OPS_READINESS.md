# Certa Release Ops Readiness

Last updated: 2026-06-20 23:22

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest `main` run `#41` on June 18, 2026 succeeded for commit `6f40b64` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but the `G:` shared-drive mount is not present in the current local provisioning check | Blocked locally until mount restored |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release blocker | OneDrive repo is on `codex/certasurv-unified-forward` with deleted tracked root files, missing `certasurv_shared_drive.json`, and untracked generated/runtime outputs | Blocked until repo cleanup/review |
| WV_COURTHOUSE_RESEARCHER release blocker | Repo is on `codex/wv-courthouse-researcher-cabell-lessons` with multiple modified release docs/scripts/templates | Blocked until owned changes are reviewed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials. The mount itself was not available during the June 20, 2026 local provisioning check, so shared-drive verification remains blocked on this host until the drive is restored.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified public `main` run: `#41`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified prior public `main` run: `#40`, commit `e0cd20b`, created `2026-06-18T15:17:34Z`, conclusion `success`
- Verified via public GitHub API because `gh` is still unauthenticated locally.

## Current Local Provisioning Signal

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` failed on June 20, 2026 with these launch-relevant gaps:

- `G:\Shared drives\CERTASURV_PROJECT DRIVE` and required command-center/project subfolders are not mounted.
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json` is missing in the active OneDrive MACROTBC worktree.
- `node`, `npm`, and `pwsh` are not available on PATH in this shell.

## Launch Blockers

1. Restore or remount `G:\Shared drives\CERTASURV_PROJECT DRIVE` before any shared-drive release handoff.
2. Clean and review MACROTBC before release: restore or intentionally remove tracked root files, resolve the missing shared-drive config, and separate generated/runtime outputs from source changes.
3. Review and finish WV_COURTHOUSE_RESEARCHER branch changes before treating it as release-ready.
4. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
5. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
