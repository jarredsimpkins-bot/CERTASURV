# Certa Control Repo Launch Checklist

Last updated: 2026-06-21

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 21, 2026 via public API: latest `main` run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Blocked locally on June 21, 2026 because the `G:` shared-drive mount was missing |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC ready for release review | Repo readiness checks can run and shared-drive config/package files are present | Blocked locally: `package.json` and `certasurv_shared_drive.json` missing from working tree |
| WV courthouse researcher ready for review | Remote exists and active branch can be pushed for cloud review | Blocked locally: no remote configured |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Resolve MACROTBC readiness before launch review: restore or intentionally regenerate the missing package/config files, then run its repo checks.
8. Configure or explicitly defer the `WV_COURTHOUSE_RESEARCHER` remote before treating courthouse research as cloud-reviewable.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. Shared-drive mount `G:\Shared drives\CERTASURV_PROJECT DRIVE` was not available during the June 21 provisioning check.
4. MACROTBC local readiness is blocked by missing working-tree `package.json` and `certasurv_shared_drive.json`.
5. `WV_COURTHOUSE_RESEARCHER` has no configured remote, blocking push/review.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall run during this pass: `#115` on branch `codex/release-control-webapp-path-guard-20260621-2`, success on June 21, 2026
- Blocker triage: `docs/RELEASE_BLOCKER_TRIAGE_2026-06-21.md`
