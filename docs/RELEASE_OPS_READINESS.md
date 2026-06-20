# Certa Release Ops Readiness

Last updated: 2026-06-20 08:00

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest visible run `#92` on June 20, 2026 succeeded on branch `codex/certa-launch-provisioning-worktree-git`; latest visible `main` run remains green in prior evidence | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted in this run | Blocked locally |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references remain fallback-only in local helper scripts | Ready |
| CERTARD / web app | Both sibling repos have remotes; observed local changes are limited to docs/checklist files and mainly need review/push timing | Ready with review timing |
| MACROTBC | Local workspace exists at `C:\Users\SimpS\OneDrive\Documents\MACROTBC`, branch `codex/certasurv-unified-forward`, remote `jarredsimpkins-bot/macrotbc.git`, clean during this pass | Needs review/push timing |
| WV courthouse researcher | Local workspace exists at `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`; current branch has uncommitted release-prep docs/scripts and no configured remote observed during this pass | Blocked |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references are expected to align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE`, but the drive is not mounted in this run, so live shared-drive contents were not modified or revalidated.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified public run: `#92`, branch `codex/certa-launch-provisioning-worktree-git`, commit `c902ed3`, created `2026-06-20T11:07:49Z`, conclusion `success`
- Latest verified WV inventory run: `#91`, branch `codex/release-ops-wv-inventory-20260620`, commit `17b5d9f`, created `2026-06-20T11:05:26Z`, conclusion `success`
- Latest verified `main` evidence in this repo remains run `#40`, commit `e0cd20b`, conclusion `success`

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Configure and push the `WV_COURTHOUSE_RESEARCHER` remote after reviewing its local uncommitted release-prep changes.
3. Remount `G:\Shared drives\CERTASURV_PROJECT DRIVE` before copying generated handoff docs or validating live release staging.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Use the updated control scripts to include `WV_COURTHOUSE_RESEARCHER` in provisioning, remote setup, publish, and cloud-offload checks.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
