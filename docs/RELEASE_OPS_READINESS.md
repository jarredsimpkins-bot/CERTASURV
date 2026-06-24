# Certa Release Ops Readiness

Last updated: 2026-06-24 00:47

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh run list` shows latest `main` run `#41` on June 18, 2026 succeeded at `6f40b64`; latest release-ops branch run checked was `#203` on June 23, 2026 and also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops; current provisioning check could not see the `G:` shared-drive mount | Blocked until mount is restored |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` 2.92.0 is installed and authenticated as `jarredsimpkins-bot` with `repo` scope; workflow scope was not listed by `gh auth status` | Mostly ready; add workflow scope if dispatch/log operations fail |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release state | Local checkout has an uncommitted change in `command_center/tbc/command_usage_log.csv`; production/AppSheet/TBC paths remain substantive launch scope | Blocked pending review/stage decision |
| WV_COURTHOUSE_RESEARCHER release state | Local checkout has no remote listed, is on `codex/wv-courthouse-researcher-cabell-lessons`, and has uncommitted docs/scripts/tool-registry changes | Blocked pending remote/upstream and dirty-tree review |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest verified release-ops branch run during this pass: `#203`, branch `codex/release-ops-current-readiness-20260623-2045`, commit `03465ff`, created `2026-06-23T20:50:06Z`, conclusion `success`
- Recent branch runs `#199` through `#203` were all reported as successful by `gh run list`.

## Launch Blockers

1. Restore or remount `G:\Shared drives\CERTASURV_PROJECT DRIVE`; repo-local provisioning currently reports the shared-drive mount, command-center root, and projects folder as missing.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Review MACROTBC's dirty command usage log before release packaging or AppSheet/TBC handoff.
4. Assign WV_COURTHOUSE_RESEARCHER a remote/upstream and resolve its dirty working tree before release review.

## Non-Blocking Follow-Up

- Normalize any remaining operator-facing references to `CERTASURV_WEB_APP` across sibling repos so release handoff docs all use the same workspace name.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
- Add `workflow` scope to the GitHub CLI token only if release operations need workflow dispatch or private Actions log access beyond the current `repo` scope.
