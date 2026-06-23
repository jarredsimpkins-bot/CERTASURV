# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `27773432493`, commit `6f40b64`, success |
| Current release-control branch green | Latest pushed release-control feature branch passes the same checks | Verified on June 23, 2026: run `28032389759`, commit `a7ee586`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts; workflow blocks `New project2` script fallback |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo access on the host used for release operations | Verified on June 23, 2026 as `jarredsimpkins-bot` |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC release blocker cleared | Command-center/TBC production review is complete and dirty files are intentional | Blocked by active `command_center/tbc/command_usage_log.csv` change |
| WV courthouse release blocker cleared | Remote/readiness approval exists and dirty files are intentional | Blocked by no visible remote in local status output and multiple modified docs/scripts/templates |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` and the current release-control branch are green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Use `gh` to inspect private workflow/log state before treating MACROTBC, WV_COURTHOUSE_RESEARCHER, CERTARD, or CERTASURV_WEB_APP as push-ready.

## Current Launch Blockers

1. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
2. MACROTBC still needs command-center/TBC production review before release handoff.
3. WV_COURTHOUSE_RESEARCHER still needs remote/readiness approval and dirty-tree review before release handoff.
4. Shared-drive handoff remains dependent on `G:` mount availability.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified release-control feature run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/28032389759`
