# Certa Release Ops Readiness

Last updated: 2026-06-20 06:58

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest overall run `#40` on June 18, 2026 succeeded on `main`; the preceding feature-branch run `#39` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted in this run | Blocked locally |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; control scripts no longer fall back to legacy `New project2` | Ready |
| WV courthouse researcher | Local workspace exists at `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`; current branch has uncommitted release-prep docs/scripts and no configured remote observed during this pass | Blocked |
| MACROTBC | Local workspace exists at `C:\Users\SimpS\OneDrive\Documents\MACROTBC`, branch `codex/certasurv-unified-forward`, remote `jarredsimpkins-bot/macrotbc.git`, clean during this pass | Needs review/push timing |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references are expected to align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE`, but the drive is not mounted in this run, so live shared-drive contents were not modified or revalidated.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#40`, branch `main`, commit `e0cd20b`, created `2026-06-18T15:17:34Z`, conclusion `success`
- Latest verified prior feature-branch run: `#39`, branch `codex/adaptive-worktree-launch-hardening-20260618`, commit `422cbb5`, created `2026-06-18T14:19:31Z`, conclusion `success`
- Verified job summary for run `#40`: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax` and `Verify required control files`

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Configure and push the `WV_COURTHOUSE_RESEARCHER` remote after reviewing its local uncommitted release-prep changes.
3. Remount `G:\Shared drives\CERTASURV_PROJECT DRIVE` before copying generated handoff docs or validating live release staging.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Keep sibling repos normalized to `CERTASURV_WEB_APP`; repo-local control scripts now treat missing `CERTASURV_WEB_APP` as a provisioning gap instead of silently using a legacy path.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
