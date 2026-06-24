# Certa Release Ops Readiness

Last updated: 2026-06-24 02:25

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | GitHub Actions shows latest overall run `#214` on June 24, 2026 succeeded on `codex/release-control-webapp-path-guard-20260624-d012`; latest `main` run `#41` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Repo-local references are preserved, but the `G:\Shared drives\CERTASURV_PROJECT DRIVE` mount is unavailable on this host during this pass | External mount needed |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed and authenticated as `jarredsimpkins-bot` with `repo` scope on this host | Ready |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| CERTARD release lane | Private repo `jarredsimpkins-bot/certard` exists with default branch `main`; local workspace has only unrelated handoff-doc drift observed this pass | Push/review timing |
| CERTASURV_WEB_APP release lane | Private repo `jarredsimpkins-bot/certasurv-web-app` exists with default branch `codex/land-opportunity-radar-mvp`; active local path is normalized | Push/review timing |
| MACROTBC release lane | Private repo `jarredsimpkins-bot/macrotbc` exists and was pushed June 24, 2026; local workspace still has `command_center/tbc/command_usage_log.csv` modified | Blocked until local change is reviewed |
| WV_COURTHOUSE_RESEARCHER release lane | Local workspace exists but has no `origin`; `gh repo view jarredsimpkins-bot/wv-courthouse-researcher` cannot resolve a repo, and multiple runbook/toolkit edits are uncommitted | Blocked |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#214`, branch `codex/release-control-webapp-path-guard-20260624-d012`, commit `4a82b53`, created `2026-06-24T06:06:21Z`, conclusion `success`
- Latest verified `main` run: `#41`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified job summary for run `#214`: single job `powershell-and-docs` succeeded, including `Validate PowerShell syntax` and `Verify required control files`

## Launch Blockers

1. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
2. Review and either commit or intentionally discard the modified MACROTBC command usage log before treating MACROTBC as release-ready.
3. Create or confirm the WV_COURTHOUSE_RESEARCHER GitHub repository, set its `origin`, then review and commit the current local runbook/toolkit edits.
4. Restore the `G:` shared-drive mount before copying generated release notes or validating staged handoff packages.
5. Normalize `npm` availability on PATH before web-app release checks that depend on Node package scripts.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` is unavailable on a future host.
