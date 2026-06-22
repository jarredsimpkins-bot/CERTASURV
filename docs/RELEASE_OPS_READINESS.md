# Certa Release Ops Readiness

Last updated: 2026-06-22 08:30

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest visible overall run `#164` on June 22, 2026 succeeded on release branch `codex/release-control-webapp-path-guard-20260622-673d`; latest `main` run `#41` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and tracked by workflow required-file validation, including this repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but the `G:` shared-drive mount is not visible on this host during this pass | Blocked for live drive verification |
| CERTARD / web app timing | CERTARD and `CERTASURV_WEB_APP` are locally present with remotes; current launch risk is review/push timing, not missing local control coverage | Ready with review timing |
| MACROTBC release lane | `MACROTBC` local repo and private GitHub remote are reachable; this remains a substantive production integration release lane | Active blocker lane |
| WV courthouse release lane | `WV_COURTHOUSE_RESEARCHER` exists locally, but no GitHub repo/remote is currently resolvable as `jarredsimpkins-bot/wv-courthouse-researcher` | Blocked |
| GitHub CLI access | `gh auth status` succeeds for `jarredsimpkins-bot` with `repo` scope | Ready |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; `jarredsimpkins-bot/certahealth` is not currently resolvable through `gh repo view` | Blocked / decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`
- `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER\docs\certasurv_toolkit_runbook.md`

These references confirm that the shared drive remains the system of record for staged releases and install materials. This pass could not verify live shared-drive contents because `G:\Shared drives\CERTASURV_PROJECT DRIVE` was not mounted.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#164`, branch `codex/release-control-webapp-path-guard-20260622-673d`, commit `d63dbc7`, created `2026-06-22T12:09:55Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified job summary for run `#164`: single job `powershell-and-docs` succeeded, including PowerShell syntax and required-file validation

## Launch Blockers

1. Create or identify the `WV_COURTHOUSE_RESEARCHER` GitHub repository, set its `origin`, and push the active branch after reviewing the existing dirty local changes.
2. Decide whether the control repo should keep using public `CERTASURV.git` or move to a dedicated `certahealth.git` remote, then create/verify that destination before cutover.
3. Restore or sign in to the `G:` shared-drive mount before any live staged-release verification.

## Non-Blocking Follow-Up

- Keep MACROTBC as the primary production-integration release blocker until its TBC/AppSheet/shared-drive package has review evidence.
- Keep CERTARD and `CERTASURV_WEB_APP` in push/review timing mode unless their branch checks regress.
- Keep using the public REST API as a fallback for public workflow visibility when GitHub CLI auth is unavailable on another host.
