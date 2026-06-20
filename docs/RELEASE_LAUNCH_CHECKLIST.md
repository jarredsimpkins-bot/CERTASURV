# Certa Control Repo Launch Checklist

Last updated: 2026-06-20

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green | Latest visible public `CertaHealth Control Checks` release-ops run and latest visible `main` run are successful | Verified: release-ops run `#99` on June 20, 2026 and `main` run `#41` on June 18, 2026 both succeeded |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| Blocker repos triaged | `MACROTBC` and `WV_COURTHOUSE_RESEARCHER` are separated from timing-only push/review lanes | Current release blockers |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Review `MACROTBC` tracked-file deletions and generated outputs before any release push.
6. Confirm and set the intended `WV_COURTHOUSE_RESEARCHER` remote/branch before pushing its release-readiness docs.
7. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
8. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. `MACROTBC` still needs substantive release cleanup around tracked-file deletions and generated artifacts.
4. `WV_COURTHOUSE_RESEARCHER` still needs its intended remote/upstream confirmed before push/review.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified visible run during this pass: `#99` on branch `codex/release-control-webapp-path-strict-20260620c`, success on June 20, 2026: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27881535285`
- Latest verified visible `main` run: `#41`, success on June 18, 2026: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Recent visible release-ops runs `#95` through `#99` all succeeded on June 20, 2026.
