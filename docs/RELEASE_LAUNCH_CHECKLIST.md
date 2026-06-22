# Certa Control Repo Launch Checklist

Last updated: 2026-06-22

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#40`, commit `e0cd20b`, success; latest visible run on June 22, 2026 is `#155`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts; retired `New project2` fallback is not accepted |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Repo-local references align, but live `G:` mount is missing on this host |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC blocker closed | Private workflow/release evidence, command-center manifest, and install/runbook handoff are reviewed | Still substantive launch blocker |
| WV_COURTHOUSE_RESEARCHER blocker closed | Remote/upstream mapping and release-readiness evidence are reviewed | Still substantive launch blocker |
| Host provisioning clean | `scripts\Test-CertaProjectProvisioning.ps1 -Detailed` exits cleanly | Blocked by missing `G:` mount, MACROTBC shared-drive config, and Node PATH |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Treat CERTARD and CERTASURV_WEB_APP as push/review-timing lanes unless new evidence appears; focus release-blocker work on MACROTBC and WV_COURTHOUSE_RESEARCHER.
8. Re-run provisioning after mounting the shared drive and restoring Node PATH; keep the failure output with release evidence if it still fails.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. MACROTBC remains blocked on private release evidence and install/runbook review.
4. WV_COURTHOUSE_RESEARCHER remains blocked on remote/upstream readiness evidence.
5. Host provisioning is blocked by missing shared-drive mount, missing MACROTBC shared-drive config, and Node tooling absent from PATH.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27769753846`
- Latest visible public run during this pass: `#155`, branch `codex/release-control-webapp-path-guard-20260622-impl`, success on June 22, 2026
- Latest visible release-blocker evidence run during this pass: `#154`, branch `codex/release-ops-wv-macrotbc-readiness-20260622-2358`, success on June 22, 2026
