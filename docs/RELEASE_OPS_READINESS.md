# Certa Release Ops Readiness

Last updated: 2026-06-23 08:45

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh` and the public API show latest visible run `#188` on June 23, 2026 succeeded on feature branch `codex/release-control-strict-webapp-wv-20260623-1102`; latest verified `main` run remains `#40` from June 18, 2026 | Ready for feature review; `main` needs merge timing |
| Control repo docs | Core launch docs are present in repo and tracked by workflow required-file validation, including release checklist and connection matrix | Ready |
| Shared-drive handoff docs | Repo-local references exist, but this host currently does not have `G:\Shared drives\CERTASURV_PROJECT DRIVE` mounted | Blocked by local Drive mount |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| CERTARD / web app timing | CERTARD and `CERTASURV_WEB_APP` have remotes and active feature branches; release risk is mainly review/push timing, not control-doc structure | Monitor |
| MACROTBC release lane | Local MACROTBC worktree has a modified command-center usage log and remains the TBC production integration lane | Blocking until reviewed/stabilized |
| WV courthouse researcher lane | `WV_COURTHOUSE_RESEARCHER` has no approved remote in the control matrix and currently carries multiple local modified files | Blocking until remote/readiness path is approved |
| GitHub CLI access | `gh auth status` succeeds for `jarredsimpkins-bot` with `repo` scope on this host | Ready |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE`, but the drive itself was not mounted during the June 23 provisioning check. Treat the shared drive as the system of record once Google Drive Desktop restores the mount.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified visible run: `#188`, branch `codex/release-control-strict-webapp-wv-20260623-1102`, commit `d457e02`, created `2026-06-23T12:08:15Z`, conclusion `success`
- Latest verified recent blocker-refresh run: `#187`, branch `codex/release-ops-current-blockers-20260623-0805`, commit `3bc4cf1`, created `2026-06-23T08:36:19Z`, conclusion `success`
- Latest verified `main` run: `#40`, branch `main`, commit `e0cd20b`, created `2026-06-18T15:17:34Z`, conclusion `success`
- Verified workflow command: `gh run list --repo jarredsimpkins-bot/CERTASURV --workflow certahealth-control-checks.yml --limit 5`

## Launch Blockers

1. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
2. Review and stabilize MACROTBC command-center/TBC production changes before treating the stack as launch-ready.
3. Approve the WV_COURTHOUSE_RESEARCHER remote/readiness path before any release automation expects it to publish upstream.
4. Restore the `G:` shared-drive mount before staging or validating external handoff packages.

## Non-Blocking Follow-Up

- Keep CERTARD and `CERTASURV_WEB_APP` feature branches moving through push/review timing; do not let their generated artifacts or local data folders enter release-control commits.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` is unavailable on another host.
