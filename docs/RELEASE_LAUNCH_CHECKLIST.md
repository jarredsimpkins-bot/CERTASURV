# Certa Control Repo Launch Checklist

Last updated: 2026-06-19

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#40`, commit `e0cd20b`, success; latest visible overall run `#68` on June 19, 2026 also succeeded |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| Blocker repos inventoried | `MACROTBC` and `WV_COURTHOUSE_RESEARCHER` are explicitly represented in control-repo readiness checks | Verified in current repo docs/scripts |
| WV repo remote/upstream | `WV_COURTHOUSE_RESEARCHER` has an `origin` remote and upstream tracking branch | Blocked on this host |
| WV setup docs aligned | WV install/release docs no longer point at legacy `C:\Users\SimpS\OneDrive\Documents\New project` paths | Blocked outside this repo |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Check `MACROTBC` and `WV_COURTHOUSE_RESEARCHER` for remote/upstream readiness before calling the stack launch-ready; do not rely on the control repo alone.
6. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
7. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
8. Keep WV release/install instructions repo-local until the WV repo itself is updated off legacy `New project` paths.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. `MACROTBC` still has substantive local release work that has not been committed or reviewed.
4. `WV_COURTHOUSE_RESEARCHER` still has no remote/upstream on this host and its install docs still reference legacy `New project` paths.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27769753846`
- Latest verified overall run during this pass: `#68` on branch `codex/release-ops-readiness-20260619-0955`, success on June 19, 2026
