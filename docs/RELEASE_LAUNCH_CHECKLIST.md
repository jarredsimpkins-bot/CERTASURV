# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green | Latest visible `CertaHealth Control Checks` run is successful | Verified on June 23, 2026: run `28010374469`, commit `a6cd0dcc76ab8c7ab4b41417701b88c19a7efa1b`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts; legacy fallback removed from control scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Blocked in this run because `G:` was not mounted |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Ready for `jarredsimpkins-bot` with `repo` scope |
| MACROTBC release branch clean | TBC release branch has only intentional changes and tracks remote | Blocked: `command_center/tbc/command_usage_log.csv` is modified locally |
| WV courthouse researcher branch clean | WV researcher branch has remote/upstream and only intentional release edits | Blocked: multiple local modifications and no remote listed in this workspace |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest visible control workflow run is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Confirm `gh auth status` is still authenticated before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Resolve MACROTBC and WV_COURTHOUSE_RESEARCHER dirty-worktree/remote state before marking the stack launch-ready.

## Current Launch Blockers

1. `G:\Shared drives\CERTASURV_PROJECT DRIVE` was not mounted during the June 23, 2026 provisioning check.
2. MACROTBC has an uncommitted release-lane artifact change that needs review or cleanup.
3. WV_COURTHOUSE_RESEARCHER has uncommitted release-readiness edits and no configured remote listed in this workspace.
4. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified visible run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/28010374469`
- Latest verified overall run during this pass: branch `codex/release-control-webapp-path-guard-20260623-automation-run`, success on June 23, 2026
