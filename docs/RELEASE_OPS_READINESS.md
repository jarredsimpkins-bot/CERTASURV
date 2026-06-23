# Certa Release Ops Readiness

Last updated: 2026-06-23 00:08

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh` shows latest `main` run `27773432493` on June 18, 2026 succeeded; latest visible release-control branch run `28000329578` on June 23, 2026 also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Staging and Apps Script deployment references exist outside this repo, but the `G:` shared-drive mount was missing in the current provisioning check | External dependency blocked |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh auth status` succeeds for `jarredsimpkins-bot` with repo access; private workflow run listings are visible from this host | Ready for inspection |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| CERTARD | Latest visible `CERTARD Checks` run on `main` succeeded on June 22, 2026; local branch still had one modified liaison brief during this pass | Review timing |
| CERTASURV_WEB_APP | Remote exists, but latest visible `Land Radar Python CI` run failed on June 19, 2026 and the local tree contains generated/untracked artifacts | Review timing with cleanup needed |
| MACROTBC | Latest visible `CertaSurv TBC Cloud Readiness` run failed on June 23, 2026 | Blocking |
| WV_COURTHOUSE_RESEARCHER | Local branch exists with active edits, but no remote was configured during this pass | Blocking remote/upstream setup |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `27773432493`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified release-control branch run: `28000329578`, branch `codex/release-control-strict-webapp-wv-inventory-20260623`, created `2026-06-23T03:35:00Z`, conclusion `success`
- Latest verified MACROTBC run: `28000398484`, branch `codex/macro-launch-readiness-20260621`, commit `6fe6b0e`, created `2026-06-23T03:37:01Z`, conclusion `failure`
- Latest verified CERTARD run: `27937122339`, branch `main`, commit `b2d1e59`, created `2026-06-22T07:38:22Z`, conclusion `success`
- Latest verified CERTASURV_WEB_APP run: `27802010837`, branch `codex/certasurv-unified-forward`, commit `fc51358`, created `2026-06-19T02:39:15Z`, conclusion `failure`

## Launch Blockers

1. Fix the failing MACROTBC cloud-readiness workflow before treating TBC integration as release-ready.
2. Configure a remote/upstream for `WV_COURTHOUSE_RESEARCHER` and review its active local edits before launch handoff.
3. Restore or reconnect `G:\Shared drives\CERTASURV_PROJECT DRIVE` before any shared-drive handoff validation or staging.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep public REST API checks available as a fallback, but prefer `gh run list` while the current authenticated session remains available.
