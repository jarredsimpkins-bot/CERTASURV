# Certa Release Ops Readiness

Last updated: 2026-06-22 17:30

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest `main` run `#41` on June 18, 2026 succeeded at commit `6f40b64`; latest overall observed feature-branch run `#172` also succeeded on June 22, 2026 | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; control scripts now use that canonical path without the retired `New project2` fallback | Ready |
| GitHub CLI access | `gh auth status` succeeds for `jarredsimpkins-bot`; private repo workflow metadata is visible for CERTARD, MACROTBC, and CERTASURV_WEB_APP | Ready for inspection |
| CERTARD release lane | Private repo `jarredsimpkins-bot/certard` has latest observed `main` workflow run `27937122339` successful on June 22, 2026 | Ready pending normal push/review timing |
| CERTASURV_WEB_APP release lane | Local repo is on `codex/certasurv-unified-forward` with large uncommitted/generated working-tree changes; latest observed private workflow run still failed on June 19, 2026 | Needs cleanup before release push/review |
| MACROTBC release lane | Private repo `jarredsimpkins-bot/macrotbc` is reachable, but latest observed cloud-readiness run `27970712914` failed in `validate-package` / `Run documented repo validation` | Blocked |
| WV_COURTHOUSE_RESEARCHER release lane | Local workspace exists on `codex/wv-courthouse-researcher-cabell-lessons` with uncommitted runbook/tool changes and no `origin` remote reported in this pass | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; `jarredsimpkins-bot/certahealth` was not resolvable through `gh repo view` in this pass | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` public run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified overall public run observed during this pass: `#172`, branch `codex/release-ops-live-blockers-20260622-1230`, commit `3aa0977`, created `2026-06-22T16:36:17Z`, conclusion `success`
- Verified control workflow gate remains the single `powershell-and-docs` job, including `Validate PowerShell syntax` and `Verify required control files`

## Launch Blockers

1. Fix MACROTBC cloud-readiness validation: latest observed private run `27970712914` failed in `validate-package` at `Run documented repo validation`.
2. Resolve WV_COURTHOUSE_RESEARCHER release ownership: local workspace has uncommitted runbook/tool changes and no `origin` remote reported during this pass.
3. Decide whether the control repo should keep using public `CERTASURV.git` or switch to a dedicated `certahealth.git` remote before launch cutover; `gh repo view jarredsimpkins-bot/certahealth` did not resolve here.

## Non-Blocking Follow-Up

- Keep normalizing operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility if `gh` authentication is unavailable on another host.
