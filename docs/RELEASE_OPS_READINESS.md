# Certa Release Ops Readiness

Last updated: 2026-06-22 12:30

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest visible control run `#171` on branch `codex/release-ops-wv-macrotbc-readiness-20260622-1430` succeeded; latest `main` run `#41` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Handoff references still exist outside this repo, but the `G:` shared-drive mount was missing during the June 22 provisioning check | Blocked until mount returns |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh auth status` reports account `jarredsimpkins-bot` authenticated over HTTPS with `repo` scope | Ready for private repo inspection |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| Substantive release blockers | `MACROTBC` latest unified-forward workflow failed; `WV_COURTHOUSE_RESEARCHER` has local uncommitted toolkit/docs changes and no configured remote | Blocked |
| Clean local repos | `CERTARD` main workflow is green; `CERTASURV_WEB_APP` remains a push/review timing lane despite older unified-forward CI failures | Timing dependent |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE`, but that mount was not available locally during this run. Treat the shared drive as the system of record once the mount is restored; do not copy handoff material until then.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified public control run: `#171`, branch `codex/release-ops-wv-macrotbc-readiness-20260622-1430`, commit `380ec30`, created `2026-06-22T16:01:01Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Private workflow visibility works through `gh`; latest MACROTBC unified-forward run `27967041962` failed on June 22, 2026, while latest CERTARD `main` run `27937122339` succeeded.

## Launch Blockers

1. Fix the MACROTBC `codex/certasurv-unified-forward` workflow failure and finish the production-integration package/runbook review before treating the TBC lane as releasable.
2. Confirm or create the WV_COURTHOUSE_RESEARCHER GitHub remote, set `origin`, push `codex/wv-courthouse-researcher-cabell-lessons`, and review the local toolkit/docs changes before handoff.
3. Restore the `G:` shared-drive mount before validating or copying staged handoff material against the shared-drive system of record.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Normalize Node/npm PATH separately from release blocker closeout; this run found `node` through the Codex runtime but `npm` missing from PATH.
