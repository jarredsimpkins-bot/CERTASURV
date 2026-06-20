# Certa Release Ops Readiness

Last updated: 2026-06-20

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest visible overall run `#73` on June 19, 2026 succeeded; latest visible `main` run is `#41` and also succeeded | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo and remain read-only during release ops | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| CERTARD release posture | Branch tracks `origin/codex/certasurv-unified-forward`; local change is limited to the liaison brief | Ready with push/review timing |
| CERTASURV_WEB_APP release posture | Branch tracks `origin/codex/certasurv-unified-forward` with no local changes observed | Ready with push/review timing |
| MACROTBC release posture | Branch tracks `origin/codex/certasurv-unified-forward`, but substantive tracked and untracked release work remains open | Blocked |
| WV_COURTHOUSE_RESEARCHER release posture | Local branch has no configured remote/upstream and tracked release/runbook/tooling changes remain local | Blocked |
| GitHub CLI access | `gh` is installed locally but unauthenticated on this host | Blocked |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## Current Cross-Repo Signal

- `CERTARD`: branch `codex/certasurv-unified-forward`, upstream `origin/codex/certasurv-unified-forward`; local diff currently limited to `drive/CERTASURV_LIAISON_BRIEF.md`.
- `CERTASURV_WEB_APP`: branch `codex/certasurv-unified-forward`, upstream `origin/codex/certasurv-unified-forward`; no local changes observed.
- `MACROTBC`: branch `codex/certasurv-unified-forward`, upstream `origin/codex/certasurv-unified-forward`; active local changes remain across shared-drive config/map files, TBC usage logs, macro source, sync tooling, and new parser-hotkey artifacts.
- `WV_COURTHOUSE_RESEARCHER`: branch `codex/wv-courthouse-researcher-cabell-lessons`; no `origin` remote or upstream tracking configured, with tracked setup/runbook/toolkit changes still local.

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified overall public run: `#73`, branch `codex/certard-remote-alignment-20260619`, commit `4bf4f8b`, created `2026-06-19T18:04:36Z`, conclusion `success`
- Latest verified `main` public run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Recent release-ops/control runs `#72`, `#71`, `#70`, and `#69` also completed successfully on June 19, 2026.
- Verified job shape remains the single `powershell-and-docs` job covering `Validate PowerShell syntax` and `Verify required control files`.

## Launch Blockers

1. Authenticate `gh` on this host with repo and workflow scopes so private workflow runs and logs can be inspected directly.
2. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.
3. Finish, review, and push the substantive `MACROTBC` release work before treating the TBC integration lane as launch-ready.
4. Decide and configure the GitHub remote/upstream for `WV_COURTHOUSE_RESEARCHER`, then push its current branch so Release 1 review can happen against a real remote.
5. Clear the remaining WV setup/runbook/toolkit edits before copying any WV installer or handoff instructions into external systems.

## Non-Blocking Follow-Up

- Keep `CERTARD` and `CERTASURV_WEB_APP` on the push/review timing queue rather than the engineering blocker queue unless new workflow or review failures appear.
- Keep using the public REST API as a fallback for public workflow visibility when `gh` remains unauthenticated on this host.
