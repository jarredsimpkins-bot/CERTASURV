# Certa Control Repo Launch Checklist

Last updated: 2026-06-21

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#40`, commit `e0cd20b`, success |
| Latest visible workflow green | Latest public `CertaHealth Control Checks` run visible through the REST API is successful | Verified on June 21, 2026 ET / June 22 UTC: run `#143`, branch `codex/release-control-webapp-path-guard-20260622`, commit `5f36c19`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| Substantive blocker split recorded | CERTARD and CERTASURV_WEB_APP are push/review timing items; MACROTBC and WV_COURTHOUSE_RESEARCHER remain release blockers | Current as of June 21, 2026 |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Resolve MACROTBC shared-drive config/package readiness before cutting install materials.
8. Add or confirm the WV_COURTHOUSE_RESEARCHER GitHub remote before relying on cloud review for that branch.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. MACROTBC provisioning is missing `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json` and the shared-drive mount is unavailable on this host.
4. WV_COURTHOUSE_RESEARCHER has no `origin` remote configured locally, so its current branch cannot be pushed/reviewed from the standard release path.
5. `node` and `npm` are not on PATH, limiting local smoke coverage for CERTASURV_WEB_APP until PATH is restored.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27769753846`
- Latest verified visible run during this pass: `#143` on branch `codex/release-control-webapp-path-guard-20260622`, success on June 22, 2026 UTC
- Latest verified `main` run: `#40` on branch `main`, success on June 18, 2026; prior feature-branch run `#39` also succeeded
