# Certa Control Repo Launch Checklist

Last updated: 2026-06-20

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Last `main` evidence in this repo: June 18, 2026 run `#40`, commit `e0cd20b`, success |
| Current public workflow signal | Latest visible public run is successful, even when it is not on `main` | Verified on June 20, 2026: run `#92`, branch `codex/certa-launch-provisioning-worktree-git`, commit `c902ed3`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| WV courthouse researcher release lane | `WV_COURTHOUSE_RESEARCHER` has reviewed local changes plus configured origin/upstream | Blocked: local changes exist and no remote is configured |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Review `WV_COURTHOUSE_RESEARCHER` local changes, configure its remote, and push the selected branch before treating the courthouse lane as releasable.
6. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
7. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. `WV_COURTHOUSE_RESEARCHER` is local-only in the observed checkout and has uncommitted release-prep files.
3. `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted in this run, so live shared-drive staging cannot be revalidated.
4. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run in repo evidence: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27769753846`
- Latest verified visible run during this pass: `#92` on branch `codex/certa-launch-provisioning-worktree-git`, success on June 20, 2026
