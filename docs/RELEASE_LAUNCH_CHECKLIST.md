# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#40`, commit `e0cd20b`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| CERTARD launch lane | Coordination repo has no known local blocker beyond push/review timing | Current launch focus says clean locally |
| CERTASURV_WEB_APP launch lane | Web app repo has no known local blocker beyond push/review timing | Current launch focus says clean locally |
| MACROTBC launch lane | TBC release branch has no unresolved dirty files or command-center evidence questions | Blocked: `command_center/tbc/command_usage_log.csv` dirty during June 23 pass |
| WV_COURTHOUSE_RESEARCHER launch lane | Courthouse researcher branch has reviewed, verified, and pushed docs/scripts/template registry changes | Blocked: dirty docs/scripts/templates during June 23 pass |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. In `MACROTBC`, review `command_center/tbc/command_usage_log.csv` and decide whether it is release evidence to commit or transient output to regenerate/discard.
6. In `WV_COURTHOUSE_RESEARCHER`, review and verify the active branch changes before push: `docs/certasurv_project_prep_machine.md`, `docs/certasurv_toolkit_runbook.md`, `ortho_lidar_to_tbc_basemap/docs/workflow.md`, `scripts/certasurv_toolbox.ps1`, `scripts/certasurv_toolbox.py`, and `templates/certasurv_tool_registry.json`.
7. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
8. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. MACROTBC has an unresolved dirty command usage log in the active release branch.
2. WV_COURTHOUSE_RESEARCHER has unresolved dirty docs/scripts/template registry changes in the active release branch.
3. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
4. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27769753846`
- Latest verified overall run during this pass: `#40` on branch `main`, success on June 18, 2026; prior feature-branch run `#39` also succeeded
