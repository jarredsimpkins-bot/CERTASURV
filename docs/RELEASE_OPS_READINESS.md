# Certa Release Ops Readiness

Last updated: 2026-06-22 09:35

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh` shows latest visible run `#166` succeeded on June 22, 2026; latest `main` run `#41` succeeded on June 18, 2026 | Ready |
| Control repo docs | Core launch docs are present and workflow validation now checks required files plus launch workspace inventory terms | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo; `G:` was not mounted during the June 22 provisioning check | Ready with external mount dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; release scripts now use that path directly | Ready |
| GitHub CLI access | `gh auth status` succeeds as `jarredsimpkins-bot` with `repo` scope on this host | Ready for repo/workflow inspection |
| MACROTBC release lane | Local repo exists with `origin` set to `https://github.com/jarredsimpkins-bot/macrotbc.git`; current branch is `codex/certasurv-unified-forward` | Substantive release blocker |
| WV courthouse researcher lane | Local repo exists on `codex/wv-courthouse-researcher-cabell-lessons` but has no configured remote; several local files are modified | Substantive release blocker |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified visible run: `#166`, branch `codex/release-control-wv-inventory-20260622-1207`, commit `a0e547b`, created `2026-06-22T13:13:14Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified job summary for run `#166`: `powershell-and-docs` succeeded, including `Validate PowerShell syntax`, `Verify required control files`, and `Verify launch workspace inventory`

## Launch Blockers

1. Finish MACROTBC release review on `codex/certasurv-unified-forward` and confirm the AppSheet/command-center handoff is ready for the launch package.
2. Configure and push the WV courthouse researcher remote/upstream once its local release edits are reviewed.
3. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Current Provisioning Gaps

- `G:\Shared drives\CERTASURV_PROJECT DRIVE` was not mounted in the June 22 automation shell, so shared-drive handoff verification remains an external mount check.
- `npm` was not on PATH in the June 22 automation shell, although Node was available through the Codex runtime.
- `WV_COURTHOUSE_RESEARCHER` is local-only until a remote is configured.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback if GitHub CLI credentials expire on this host.
