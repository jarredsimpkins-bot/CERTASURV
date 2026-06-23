# Certa Release Ops Readiness

Last updated: 2026-06-23 03:25 EDT

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | Public API shows latest `main` run `#41` succeeded on June 18, 2026; latest observed feature-branch run `#184` also succeeded on June 23, 2026 | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | External staging and Apps Script deployment references still exist, but `G:` is not mounted in this session | Blocked until Drive Desktop mount is restored |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh auth status` reports `jarredsimpkins-bot` logged in with `repo` scope; token does not list `workflow` scope | Ready for repo reads/pushes; workflow-scope actions may still need reauth |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release state | Local repo has an active edit in `command_center/tbc/command_usage_log.csv` on `codex/certasurv-unified-forward`; production integration remains a launch blocker | Blocked |
| WV_COURTHOUSE_RESEARCHER release state | Local repo has active docs/script/registry edits and no `origin` remote configured on `codex/wv-courthouse-researcher-cabell-lessons` | Blocked |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE` and confirm that the shared drive remains the system of record for staged releases and install materials.

During the June 23, 2026 pass, `scripts\Test-CertaProjectProvisioning.ps1 -Detailed` could inspect the local helper paths but reported the shared-drive mount, command-center root, and project folder missing because `G:` was not available in this session.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b646511c11693232e2e1d11f61362cd1ce79`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Latest observed overall public run: `#184`, branch `codex/release-control-webapp-path-guard-20260623-impl`, commit `eeb4400fa5649384a482b2480aa01716c635ba3b`, created `2026-06-23T06:39:08Z`, conclusion `success`
- Verified job coverage remains `powershell-and-docs`, including `Validate PowerShell syntax` and `Verify required control files`

## Launch Blockers

1. Restore the `G:\Shared drives\CERTASURV_PROJECT DRIVE` mount before shared-drive handoff validation or copied release materials are produced.
2. Clear MACROTBC release blockers by reviewing the active command-center log edit, confirming the intended release branch, and pushing only committed production-safe changes.
3. Create or confirm access to `https://github.com/jarredsimpkins-bot/wv-courthouse-researcher.git`, then configure and push WV_COURTHOUSE_RESEARCHER or record the alternate upstream before release cutover.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Re-run `gh auth refresh -s workflow` only if release work needs workflow dispatch or workflow file mutation through GitHub CLI.
- Keep using the public REST API as a fallback for public control workflow visibility.
