# Certa Release Ops Readiness

Last updated: 2026-06-23 13:37 ET

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh` shows the latest visible control workflow run on June 23, 2026 succeeded on branch `codex/release-control-webapp-path-guard-20260623-7459` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but `Test-CertaProjectProvisioning.ps1 -Detailed` reports the local `G:` mount and command-center folders missing in this session | Blocked locally; external docs remain read-only |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh auth status` succeeds for `jarredsimpkins-bot` with `repo` scope on this host | Ready for repo/workflow inspection |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release lane | Latest five visible `CertaSurv TBC Cloud Readiness` runs in `jarredsimpkins-bot/macrotbc` are failures on June 22-23, 2026 | Blocked |
| WV courthouse researcher lane | Local `WV_COURTHOUSE_RESEARCHER` worktree has release/tooling edits but no configured `origin`; `jarredsimpkins-bot/wv-courthouse-researcher` is not accessible through `gh repo view` | Blocked on remote/upstream setup |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest visible control workflow run checked with `gh`: run `28044688213`, branch `codex/release-control-webapp-path-guard-20260623-7459`, created `2026-06-23T17:32:59Z`, conclusion `success`
- Latest visible prior control runs on June 23, 2026 also succeeded for release-control and blocker-alignment branches.
- `CERTARD Checks` latest visible `main` run succeeded on June 22, 2026; the active `codex/certasurv-unified-forward` branch still has older failed runs and should be reviewed before promotion.
- `CertaSurv TBC Cloud Readiness` in `MACROTBC` is still failing across the latest visible branch runs and remains the primary release-ops workflow blocker.

## Launch Blockers

1. Fix MACROTBC readiness failures before treating TBC package/install output as launchable.
2. Configure or confirm the `WV_COURTHOUSE_RESEARCHER` upstream remote before release workers can push/review that lane.
3. Restore or confirm the local Google Drive Desktop `G:` shared-drive mount before copying or staging release handoff material.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility if `gh` authentication is unavailable in another shell or host.
