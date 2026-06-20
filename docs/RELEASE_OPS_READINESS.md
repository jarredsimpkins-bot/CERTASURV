# Certa Release Ops Readiness

Last updated: 2026-06-20 01:18

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest `main` run `#41` on June 18, 2026 succeeded; latest visible overall run `#80` on June 20, 2026 also succeeded on a feature branch | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops; `G:` is not mounted in this worktree session | Blocked on local mount |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; unauthenticated remote probe cannot verify private `certahealth.git` from this host | Decision needed |
| Local tool PATH | `powershell`, `git`, `gh`, and `python` are visible; `pwsh`, `node`, and `npm` are not on PATH in this session | Blocked for Node/web and checklist parity |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` public run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified overall public run: `#80`, branch `codex/release-control-webapp-path-hardening-20260620`, commit `703c73d`, created `2026-06-20T04:59:24Z`, conclusion `success`
- Current local `HEAD`: `6f40b64`, matching `origin/main`; worktree is detached, so release edits should be committed on an explicit branch before push.

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Restore the `G:` shared-drive mount before final handoff validation or generated documentation copies.
4. Restore `pwsh`, `node`, and `npm` on PATH before running web-app or PowerShell Core launch checks locally.
5. Keep MACROTBC and WV_COURTHOUSE_RESEARCHER as the substantive release blockers; CERTARD and CERTASURV_WEB_APP were clean enough locally for push/review timing in this pass.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
