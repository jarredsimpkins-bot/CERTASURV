# Certa Release Ops Readiness

Last updated: 2026-06-20 18:08

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest overall run `#103` on June 20, 2026 succeeded on `codex/release-control-webapp-path-guard-20260620`; latest `main` run `#41` also succeeded | Ready with GitHub CLI blocker |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Repo-local references still point at the shared-drive system of record, but `G:\Shared drives\CERTASURV_PROJECT DRIVE` was not mounted in this session | Ready with external mount dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; control scripts now fail against that canonical path instead of falling back to legacy `New project2` | Ready |
| CERTARD and CERTASURV_WEB_APP | Local release focus is push/review timing; no new control-repo blocker found in this pass | Ready with review timing |
| MACROTBC | Local repo has substantial dirty state on `codex/certasurv-unified-forward` while `origin` points to `macrotbc.git`; release handoff still needs an intentional cleanup/publish decision | Blocking |
| WV_COURTHOUSE_RESEARCHER | Local repo exists on `codex/wv-courthouse-researcher-cabell-lessons` with dirty docs/scripts and no configured remote observed from this host | Blocking |
| Local tool/path provisioning | Windows PowerShell can run the provisioning script; `pwsh`, `node`, and `npm` are not on PATH, the shared drive is unmounted, and `MACROTBC\certasurv_shared_drive.json` is missing locally | Blocking for local release execution |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`
- `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER\docs\certasurv_toolkit_runbook.md`

These references still align on the expected shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE`. The drive mount itself was not available in this session, so live shared-drive contents were not modified or revalidated.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#103`, branch `codex/release-control-webapp-path-guard-20260620`, commit `da60bcf`, created `2026-06-20T21:31:20Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified prior blocker-map run: `#102`, branch `codex/release-ops-wv-remote-guard-20260620f`, commit `2dbc2d4`, created `2026-06-20T21:10:04Z`, conclusion `success`
- Verified public workflow still covers PowerShell syntax and required control-file checks; private workflow/log inspection remains blocked by `gh` authentication.

## Launch Blockers

1. Resolve MACROTBC release state: decide what to preserve from the dirty local tree, publish the intended branch to `macrotbc.git`, and verify any workflow/runbook outputs needed for TBC handoff.
2. Resolve WV_COURTHOUSE_RESEARCHER remote readiness: set the GitHub remote, decide which local docs/scripts are release material, push the branch, and add workflow visibility once available.
3. Restore local release tooling and mounts needed for handoff verification: `pwsh`, Node/npm PATH, shared-drive mount, and `MACROTBC\certasurv_shared_drive.json`.
4. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
5. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Keep CERTARD and CERTASURV_WEB_APP in push/review timing mode; avoid broad cleanup unless a specific release review asks for it.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
