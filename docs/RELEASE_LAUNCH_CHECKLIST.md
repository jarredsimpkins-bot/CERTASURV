# Certa Control Repo Launch Checklist

Last updated: 2026-06-24

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green | Latest visible `CertaHealth Control Checks` run is successful | Verified on June 24, 2026: run `28084364917`, branch `codex/release-control-webapp-path-guard-20260624-0715`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts; legacy fallback removed from release helpers |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References remain documented, but `G:` was not mounted during the June 24 provisioning check |
| GitHub access for private repos | `gh` is authenticated with repo access on the host used for release operations | Ready on this host |
| MACROTBC readiness | Latest private workflow run for MACROTBC is green | Blocked: run `28081546239` failed three required checks |
| WV courthouse researcher remote | Local repo has an intended GitHub `origin` and published branch | Blocked: local repo has no remote |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest control workflow run is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Use `gh` to inspect private workflow/log status before declaring MACROTBC, CERTARD, web app, or WV researcher ready.

## Current Launch Blockers

1. MACROTBC `CertaSurv TBC Cloud Readiness` is failing on command registry, TBC operator workflow HTML, and TBC tabulated workflow checks.
2. `WV_COURTHOUSE_RESEARCHER` has no configured remote and no resolvable GitHub repo under `jarredsimpkins-bot/WV_COURTHOUSE_RESEARCHER`.
3. Shared-drive mount paths under `G:\Shared drives\CERTASURV_PROJECT DRIVE` are unavailable on this host session.
4. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified visible control run during this pass: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/28084364917`
- Latest verified MACROTBC failure: `https://github.com/jarredsimpkins-bot/macrotbc/actions/runs/28081546239`
