# Certa Release Ops Readiness

Last updated: 2026-06-20 03:00

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API now shows latest `main` run `#41` on June 18, 2026 succeeded; latest visible overall run `#85` on June 20, 2026 also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Local repo references still target the shared-drive root, but `G:` is not mounted in this session | Blocked until mount returns |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Node/npm host PATH | Provisioning check reports `node` and `npm` missing from PATH on this host | Blocked for local web tooling |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| CERTARD and web app timing | Both have configured remotes on `codex/certasurv-unified-forward`; local dirty files are doc/checklist changes only | Push/review timing |
| MACROTBC release blocker | Repo is clean locally on `codex/certasurv-unified-forward`, but production-integration readiness remains the substantive launch blocker | Blocked pending review |
| WV_COURTHOUSE_RESEARCHER release blocker | Local repo has no `origin` and six uncommitted operational/runbook/tooling files on `codex/wv-courthouse-researcher-cabell-lessons` | Blocked |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE`, but the `G:` mount was unavailable during the June 20, 2026 local provisioning check. Treat shared-drive handoff verification as blocked until the mount returns.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` public run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified overall public run: `#85`, branch `codex/provisioning-webapp-path-guard-20260620`, commit `8298eaf`, conclusion `success`
- Prior release-ops run `#84`, branch `codex/release-ops-blocker-evidence-20260620`, commit `77f04a9`, conclusion `success`

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Finish MACROTBC production-integration review before release packaging.
4. Add/push WV_COURTHOUSE_RESEARCHER remote after its current operational changes are reviewed and committed.
5. Restore the shared-drive `G:` mount and Node/npm PATH before local release tooling or handoff verification.

## Non-Blocking Follow-Up

- Keep CERTARD and CERTASURV_WEB_APP focused on push/review timing; do not expand them into launch blockers unless new test or workflow evidence changes.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
