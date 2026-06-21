# Certa Release Ops Readiness

Last updated: 2026-06-21

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest `main` run `#41` at commit `6f40b64` succeeded; latest overall checked run `#110` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; scripts now reject legacy `New project2` fallback in CI | Ready |
| WV courthouse researcher | Control inventory includes `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`; this host reports it as local-only | Remote-blocked locally |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` public run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified overall public run: `#110`, branch `codex/release-ops-blocker-triage-20260621`, commit `cda54ad`, conclusion `success`
- Verified locally during this pass: PowerShell syntax, required control file presence, script-side retired-path guard, remote dry run, and provisioning check

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Configure `WV_COURTHOUSE_RESEARCHER` `origin` after the private target is ready.

## Non-Blocking Follow-Up

- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
