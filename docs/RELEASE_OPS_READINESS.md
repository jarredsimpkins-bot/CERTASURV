# Certa Release Ops Readiness

Last updated: 2026-06-23 02:03 -04:00

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh run list` shows the latest visible `CertaHealth Control Checks` runs succeeded on June 23, 2026, including run `28004863391` on `codex/release-control-path-gh-refresh-20260623-0125` | Ready |
| Control repo docs | Core launch docs are present in repo and now tracked by workflow required-file validation, including a repo-local launch checklist | Ready |
| Shared-drive handoff docs | Repo references are intact, but `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted in this session | Blocked until Drive mount returns |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; legacy `New project2` references were a release risk | Ready after this alignment |
| GitHub CLI access | `gh auth status` succeeds for `jarredsimpkins-bot` with `repo` scope; workflow list inspection succeeds for the public control repo | Ready for visible repo checks |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |
| MACROTBC release lane | Repo has `origin` configured and branch is tracking remote, but local `command_center/tbc/command_usage_log.csv` is modified | Blocked until local release decision |
| WV courthouse researcher lane | Local branch has no `origin` remote and has six modified release/tooling files | Blocked on remote/upstream setup |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`
- `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER\docs\certasurv_toolkit_runbook.md`
- `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER\templates\certasurv_tool_registry.json`

These references still align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE`. During this pass the local `G:` mount itself was missing, so shared-drive verification must be repeated after Google Drive Desktop remounts the project drive.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified visible run: `28004863391`, branch `codex/release-control-path-gh-refresh-20260623-0125`, created `2026-06-23T05:39:43Z`, conclusion `success`
- Other June 23 visible runs also succeeded for release blocker refresh, web app path guard, readiness refresh, and strict web app/WV inventory work.
- `gh` authentication is restored enough for repo and public workflow inspection from this host.

## Launch Blockers

1. Resolve MACROTBC release state: decide whether the modified `command_center/tbc/command_usage_log.csv` is release evidence to commit or a local runtime artifact to ignore/reset outside this automation.
2. Create/choose the WV courthouse researcher GitHub remote, set `origin`, and push/review the current `codex/wv-courthouse-researcher-cabell-lessons` work.
3. Restore the `G:\Shared drives\CERTASURV_PROJECT DRIVE` mount before shared-drive staging or handoff verification.
4. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Keep using the public REST API as a fallback for public workflow visibility if `gh` scope changes again on this host.
- Keep WV_COURTHOUSE_RESEARCHER in provisioning, remote, publish, and cloud-offload inventory so it remains visible as a release lane.
