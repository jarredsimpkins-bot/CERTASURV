# Certa Release Ops Readiness

Last updated: 2026-06-21 20:15

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest visible run `#133` on June 21, 2026 succeeded on branch `codex/release-control-webapp-path-guard-20260621-1900`; `main` remains at commit `6f40b64` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release state | Local `MACROTBC` branch `codex/certasurv-unified-forward` has deleted tracked root files plus generated/untracked artifacts; remote exists | Blocked until local tree is triaged |
| WV courthouse researcher state | Local `WV_COURTHOUSE_RESEARCHER` branch `codex/wv-courthouse-researcher-cabell-lessons` has release-relevant edits and no `origin` remote configured | Blocked until remote is added and branch is pushed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`
- `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#133`, branch `codex/release-control-webapp-path-guard-20260621-1900`, commit `8fdcec3`, created `2026-06-21T20:03:01Z`, conclusion `success`
- Latest verified prior public run: `#132`, branch `codex/release-ops-current-blockers-20260621-1920`, commit `b617bfe`, created `2026-06-21T19:09:55Z`, conclusion `success`
- Private-repo workflow outputs remain unavailable because `gh auth status` reports no logged-in GitHub hosts.

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Triage `MACROTBC` local deletions and generated artifacts before release review; do not sweep `%TEMP%`, caches, `dist`, `models`, backups, or command logs into a release commit without explicit intent.
4. Add/push the `WV_COURTHOUSE_RESEARCHER` remote after confirming the intended private GitHub slug, then review and commit the current runbook/toolkit edits.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
- Use `scripts\Set-CertaGitRemotes.ps1` as the dry-run source of truth before applying any remote URL changes across the stack.
