# Certa Control Repo Launch Checklist

Last updated: 2026-06-20

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References are known, but the drive was not mounted during the June 20 local provisioning check |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC release blocker cleared | `MACROTBC` has only intended committed/reviewed launch changes | Blocked: local uncommitted changes remain |
| WV courthouse researcher upstream ready | `WV_COURTHOUSE_RESEARCHER` has a known remote/upstream and committed launch docs/tooling | Blocked: local changes remain and no remote was surfaced |
| Local runtime tools available | Local release shell can run repo checks and web tooling | Blocked: `node`/`npm` are not on PATH; use `powershell` locally because `pwsh` is not on PATH |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts. Use `pwsh` only after PowerShell 7 is installed and on PATH.
3. Confirm the latest public control workflow run is green before handing off notes or switching remotes. On June 20, 2026, the latest visible public run was `#94`, successful on `codex/release-control-webapp-path-strict-20260620`; `origin/main` was `6f40b64`.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. `MACROTBC` still has active uncommitted release-lane work.
4. `WV_COURTHOUSE_RESEARCHER` still has active uncommitted runbook/tooling work and needs a confirmed upstream.
5. The shared-drive mount was not available during the latest local provisioning check.
6. `node` and `npm` were not on PATH during the latest local provisioning check.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified visible run during this pass: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27870720356`
- Latest verified `main` run during this pass: `#41` on branch `main`, success on June 18, 2026
- Latest verified overall run during this pass: `#94` on branch `codex/release-control-webapp-path-strict-20260620`, success on June 20, 2026
