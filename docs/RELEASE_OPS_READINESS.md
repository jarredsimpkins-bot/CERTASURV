# Certa Release Ops Readiness

Last updated: 2026-06-23 14:45 ET

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh run list` shows the latest visible `CertaHealth Control Checks` run `#198` on June 23, 2026 succeeded on branch `codex/launch-webapp-path-guard-20260623`; the prior release-ops blocker run `#197` also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but `Test-CertaProjectProvisioning.ps1 -Detailed` reports the local `G:` mount and command-center folders missing in this session | Blocked locally; external docs remain read-only |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh auth status` succeeds for `jarredsimpkins-bot` with `repo` scope on this host; token does not list `workflow` scope | Ready for repo inspection; workflow-file pushes still blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release lane | Latest five visible `CertaSurv TBC Cloud Readiness` runs in `jarredsimpkins-bot/macrotbc` failed on June 22-23, 2026; local worktree also has a modified command usage log | Blocked |
| WV courthouse researcher lane | Local `WV_COURTHOUSE_RESEARCHER` worktree has release/tooling edits but no configured `origin`; `gh repo view jarredsimpkins-bot/wv-courthouse-researcher` cannot resolve a repository | Blocked on remote/upstream setup |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest visible control workflow run checked with `gh`: run `28048277418`, run number `#198`, branch `codex/launch-webapp-path-guard-20260623`, commit `4c9ca96`, created `2026-06-23T18:34:12Z`, conclusion `success`
- Latest release-ops blocker run checked with `gh`: run `28045178871`, run number `#197`, branch `codex/release-ops-current-blockers-20260623`, commit `caa4655`, created `2026-06-23T17:41:13Z`, conclusion `success`
- Latest visible MACROTBC readiness run checked with `gh`: run `28010372533`, run number `#33`, branch `codex/certasurv-unified-forward`, commit `2c20f0f`, created `2026-06-23T07:40:35Z`, conclusion `failure`.
- Local provisioning check on June 23, 2026 failed only on expected environment gaps: missing `G:` shared-drive mount/command-center folders and `npm` not on PATH.

## Launch Blockers

1. Fix MACROTBC readiness failures before treating TBC package/install output as launchable.
2. Configure or confirm the `WV_COURTHOUSE_RESEARCHER` upstream remote before release workers can push/review that lane.
3. Restore or confirm the local Google Drive Desktop `G:` shared-drive mount before copying or staging release handoff material.
4. Add `workflow` scope to the GitHub CLI token before pushing workflow-file changes from automation.
5. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility if another shell or host lacks `gh` authentication.
