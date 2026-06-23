# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 23, 2026: latest `main` run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Local `G:` mount missing during June 23 provisioning check |
| GitHub access for private repos | `gh` is authenticated with repo access on the host used for release operations | `gh auth status` OK for `jarredsimpkins-bot`; workflow scope not listed |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| WV researcher upstream configured | `WV_COURTHOUSE_RESEARCHER` has a launch remote/upstream | Blocked: local repo has no `origin` remote |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts. Use `pwsh` only when PowerShell 7 is installed on PATH.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Refresh `gh` with workflow scope before workflow dispatch or workflow-file mutation if those actions are needed.

## Current Launch Blockers

1. `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted in this session, so shared-drive closeout validation is blocked.
2. `MACROTBC` still has active local release work in `command_center/tbc/command_usage_log.csv`.
3. `WV_COURTHOUSE_RESEARCHER` has active local release edits and no configured `origin` remote.
4. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest observed overall run during this pass: `#184` on branch `codex/release-control-webapp-path-guard-20260623-impl`, success on June 23, 2026
