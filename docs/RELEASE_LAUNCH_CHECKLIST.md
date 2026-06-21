# Certa Control Repo Launch Checklist

Last updated: 2026-06-21

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on public branches | Latest public `CertaHealth Control Checks` run is successful | Verified on June 21, 2026: run `#133`, branch `codex/release-control-webapp-path-guard-20260621-1900`, commit `8fdcec3`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC release tree triaged | Root file deletions, generated artifacts, command logs, caches, and build outputs are either intentionally committed or cleaned before review | Blocked |
| WV courthouse remote ready | `WV_COURTHOUSE_RESEARCHER` has an `origin` remote and the active branch is pushed for review | Blocked |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Run `.\scripts\Set-CertaGitRemotes.ps1` before applying remote changes; confirm `WV_COURTHOUSE_RESEARCHER` maps to the intended private repository.
8. Before MACROTBC review, inspect `git status --short` and separate source/runbook changes from generated folders, command logs, caches, and build output.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. `MACROTBC` is not ready for broad release commit/push until dirty tracked deletions and generated artifacts are triaged.
4. `WV_COURTHOUSE_RESEARCHER` has no configured remote in the local checkout and cannot be pushed until that is resolved.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified public run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27915895529`
- Latest verified overall run during this pass: `#133` on branch `codex/release-control-webapp-path-guard-20260621-1900`, success on June 21, 2026; prior run `#132` also succeeded
