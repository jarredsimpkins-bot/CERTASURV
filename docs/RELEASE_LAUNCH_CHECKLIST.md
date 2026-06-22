# Certa Control Repo Launch Checklist

Last updated: 2026-06-21

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 21, 2026: latest visible `main` run `#41`, commit `6f40b64`, success |
| Workflow green on active release branches | Latest public feature-branch control workflow run is successful | Verified on June 22, 2026 UTC: latest visible overall run `#141`, branch `codex/release-control-webapp-path-guard-20260621-2301`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts; CI blocks legacy script references |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Blocked locally on June 21, 2026 because `G:` was not mounted |
| MACROTBC shared-drive config present | `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json` exists before packaging | Missing during June 21, 2026 provisioning check |
| WV courthouse researcher remote ready | `WV_COURTHOUSE_RESEARCHER` has `origin` and upstream configured | Missing during June 21, 2026 git check |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts. Use `pwsh` when PowerShell 7 is available on PATH.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Do not cut MACROTBC or WV courthouse researcher release notes until their config/remote blockers are resolved or explicitly waived.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted in this session.
4. `MACROTBC\certasurv_shared_drive.json` is missing from the local MACROTBC checkout.
5. `WV_COURTHOUSE_RESEARCHER` has no local `origin`/upstream configured.
6. `node` and `npm` are not on PATH in this session.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall run during this pass: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27921789965`
