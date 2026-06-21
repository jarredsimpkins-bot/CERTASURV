# Certa Release Ops Readiness

Last updated: 2026-06-21 18:20

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest visible run `#137` on June 21, 2026 succeeded; latest visible `main` run is `#41`, commit `6f40b64`, success on June 18, 2026 | Ready |
| Control repo docs | Core launch docs are present in repo and tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo, but `G:` is not mounted in this host session | Blocked until Drive mount returns |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| CERTARD release timing | Local branch has remote tracking; current launch brief treats it as clean enough for push/review timing rather than release engineering | Ready for review timing |
| CERTASURV_WEB_APP release timing | Active workspace has remote tracking and the path rename is aligned in this repo; current launch brief treats it as push/review timing | Ready for review timing |
| MACROTBC release blocker | Local MACROTBC workspace has deleted tracked files plus large untracked/generated output sets, so release handoff needs a scoped cleanup or branch split before push/review | Blocked |
| WV_COURTHOUSE_RESEARCHER release blocker | Local WV_COURTHOUSE_RESEARCHER workspace exists with modified toolkit docs/scripts but no configured Git remote/upstream | Blocked |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

June 21 provisioning scan could not inspect the live `G:` shared-drive folders because the mount is not currently present in this host session.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#137`, branch `codex/release-control-webapp-path-guard-20260621-2115`, commit `d008373`, created `2026-06-21T22:02:31Z`, conclusion `success`
- Latest verified `main` run: `#41`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified public workflow path remains `CertaHealth Control Checks`; private-repo job logs remain blocked without `gh` authentication

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Split or clean the MACROTBC release branch so deleted tracked files, generated outputs, and command-center usage updates are intentionally staged.
4. Add and push the WV_COURTHOUSE_RESEARCHER remote/upstream after confirming the target repository slug, then review the modified toolkit docs/scripts.
5. Restore the `G:` shared-drive mount before final handoff verification.

## Non-Blocking Follow-Up

- Keep CERTARD and CERTASURV_WEB_APP in push/review timing lanes unless new functional changes appear.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
