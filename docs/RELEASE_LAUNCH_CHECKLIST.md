# Certa Control Repo Launch Checklist

Last updated: 2026-06-24

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 24, 2026: latest `main` run is `#41`, commit `6f40b64`, success on June 18 |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References exist, but `G:` shared-drive mount is missing in the current provisioning check |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | `gh` is authenticated as `jarredsimpkins-bot` with `repo` scope; add `workflow` scope if needed |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC release blocker reviewed | Command-center/TBC changes are either committed, intentionally ignored, or documented for owner review | Dirty working tree: `command_center/tbc/command_usage_log.csv` modified |
| WV_COURTHOUSE_RESEARCHER remote/upstream ready | Release branch has a remote and clear upstream path before review | Blocked: no remote listed and working tree has docs/scripts/tool-registry changes |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -NoProfile -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Confirm `gh auth status` still shows `jarredsimpkins-bot`; add `workflow` scope only if release operations require workflow dispatch or private Actions log inspection.
7. Recheck MACROTBC and WV_COURTHOUSE_RESEARCHER with `git status --short --branch` before release packaging.

## Current Launch Blockers

1. The `G:` shared-drive mount is not visible in the current provisioning check.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. MACROTBC has an uncommitted command usage log change.
4. WV_COURTHOUSE_RESEARCHER has no remote listed and has uncommitted release-related changes.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified release-ops branch run during this pass: `#203`, branch `codex/release-ops-current-readiness-20260623-2045`, success on June 23, 2026
