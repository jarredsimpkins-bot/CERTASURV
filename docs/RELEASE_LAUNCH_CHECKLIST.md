# Certa Control Repo Launch Checklist

Last updated: 2026-06-21

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verify read-only after the `G:` mount is available |
| CERTARD and web app review timing | `CERTARD` and `CERTASURV_WEB_APP` have remotes and no control-repo blocker | Push/review timing item |
| MACROTBC release blockers isolated | Missing package/config files and generated local churn are separated from reviewable release fixes | Blocked |
| WV courthouse researcher remote ready | `WV_COURTHOUSE_RESEARCHER` has a configured remote/upstream before review | Blocked |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Local Node/npm tooling | `node` and `npm` are available on PATH for local app checks | Blocked in this shell |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Keep MACROTBC and WV courthouse researcher work out of the release-ready bucket until their blocker rows above are resolved.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. MACROTBC has release-blocking local churn plus missing tracked package/config files in the inspected workspace.
4. `WV_COURTHOUSE_RESEARCHER` has local toolkit/runbook edits but no configured remote/upstream in the inspected workspace.
5. `node` and `npm` are missing from PATH in this shell, so local app checks remain blocked until PATH is restored or CI is used.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest visible overall run during this pass: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27901363118`
- Latest verified overall run during this pass: `#125` on branch `codex/release-control-webapp-path-guard-20260621-automated`, success on June 21, 2026
