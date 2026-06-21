# Certa Control Repo Launch Checklist

Last updated: 2026-06-20

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 20, 2026 via public API: run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References align, but current host provisioning is blocked because `G:` is not mounted |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host; CLI is installed but unauthenticated |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC release blocker cleared | Active MACROTBC branch is reviewed, root tracked files/config are resolved, and generated/runtime outputs are separated | Blocked: active OneDrive worktree has deleted tracked root files, missing shared-drive config, modified telemetry, and untracked outputs |
| WV_COURTHOUSE_RESEARCHER release blocker cleared | Active courthouse researcher branch changes are reviewed and committed or intentionally held | Blocked: active branch has modified docs, scripts, templates, and ortho/LiDAR workflow docs |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` when PowerShell 7 is available, or `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` on this host, and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. Shared drive `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted on this host, so shared-drive handoff verification is blocked.
2. Active MACROTBC release worktree needs cleanup/review before release.
3. Active WV_COURTHOUSE_RESEARCHER branch changes need review before release.
4. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
5. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified public run during this pass: `#41` on branch `main`, success on June 18, 2026
