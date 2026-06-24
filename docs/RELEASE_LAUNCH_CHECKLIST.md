# Certa Control Repo Launch Checklist

Last updated: 2026-06-24

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on release branches | Latest visible `CertaHealth Control Checks` run is successful | Verified on June 24, 2026: run `#208`, commit `227a526`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References present, but local `G:` mount missing on June 24, 2026 |
| GitHub access for private repos | `gh` is authenticated with enough access to inspect private repo workflow runs | Ready for inspection on this host |
| MACROTBC readiness workflow | Latest `CertaSurv TBC Cloud Readiness` run is green | Blocked: run `#37` failed three required checks |
| WV courthouse researcher remote | Local repo has a configured remote and reviewable branch | Blocked: no remote configured locally |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest visible control workflow run is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Re-check `gh auth status` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Do not mark release green until MACROTBC and WV_COURTHOUSE_RESEARCHER have reviewable remote branches and passing readiness checks.
8. Treat CERTASURV_WEB_APP as a cleanup/review lane until deleted repo files and generated data/cache artifacts are either committed intentionally or excluded.

## Current Launch Blockers

1. `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted on this host, so shared-drive handoff validation is blocked.
2. MACROTBC run `#37` is failing required readiness checks: Command registry, TBC operator workflow HTML, and TBC tabulated workflow.
3. WV_COURTHOUSE_RESEARCHER has no configured local Git remote and contains uncommitted runbook/tool changes.
4. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified control run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/28072097120`
- Latest verified MACROTBC blocker run: `https://github.com/jarredsimpkins-bot/macrotbc/actions/runs/28069874521`
