# Certa Control Repo Launch Checklist

Last updated: 2026-06-21

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green | Latest public `CertaHealth Control Checks` run is successful; confirm `main` again before final cutover | Latest visible public run on June 21, 2026: `#121`, commit `510f658`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Current repo scripts use the renamed path directly; workflow rejects `New project2` references in scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` and the mount is available locally | Blocked locally: `G:` mount is missing in the June 21 provisioning check |
| MACROTBC release blocker cleared | Shared-drive config and command-center release state are clean enough to push/review | Blocked: `certasurv_shared_drive.json` is deleted locally and unrelated generated/churn files are present |
| WV_COURTHOUSE_RESEARCHER remote ready | Toolkit/runbook branch has a configured remote/upstream before review | Blocked: inspected workspace has no remote |
| Node/npm available | Web-app release checks can run from the active shell | Blocked locally: `node` and `npm` are not on PATH |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. MACROTBC is not release-ready until the missing shared-drive config and local churn are triaged.
4. WV_COURTHOUSE_RESEARCHER needs a configured remote/upstream before its release-toolkit fixes can be pushed for review.
5. The shared-drive mount is missing in this shell, so shared-drive handoff validation cannot complete.
6. Node/npm are missing from PATH in this shell, so web tooling checks need PATH repair or an explicit Node runtime.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest visible public run during this pass: `#121`, branch `codex/release-control-webapp-path-guard-20260621-rerun`, success on June 21, 2026
- Recent visible public runs `#117` through `#121` all completed successfully on June 21, 2026
