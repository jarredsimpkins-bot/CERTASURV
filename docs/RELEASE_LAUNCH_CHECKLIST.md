# Certa Control Repo Launch Checklist

Last updated: 2026-06-22

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on release branch | Latest visible `CertaHealth Control Checks` run is successful | Verified on June 22, 2026: run `27974270514`, branch `codex/release-control-webapp-path-guard-20260622-141558`, commit `a93a0d17bac095386acd0968ca7404e502972ba7`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References still align, but local `G:` mount is missing on June 22, 2026 |
| GitHub access for private repos | `gh` is authenticated on the host used for release operations | Authenticated as `jarredsimpkins-bot`; repo reads work, but token scope should be reviewed before workflow writes |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC private workflow green | Latest `CertaSurv TBC Cloud Readiness` run succeeds on the active release branch | Blocked: run `27974315508` failed command registry, operator workflow HTML, and tabulated workflow checks |
| WV courthouse remote ready | `WV_COURTHOUSE_RESEARCHER` has a configured `origin` and intended launch changes are committed | Blocked: local repo has no origin and contains local changes |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest visible control workflow run is green before handing off notes or switching remotes.
4. Restore or verify the `G:` shared-drive mount before any local handoff copy/stage operation.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Confirm `gh auth status` still reads private repos and add `workflow` scope only if workflow writes or dispatches are required.
7. Do not mark release ready until MACROTBC private CI is green, WV_COURTHOUSE_RESEARCHER has an intentional remote/branch path, and the shared-drive handoff path is reachable.

## Current Launch Blockers

1. MACROTBC private readiness CI is failing on the active branch.
2. WV_COURTHOUSE_RESEARCHER has no `origin` remote and has local uncommitted changes.
3. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
4. GitHub CLI is authenticated for repo reads, but release operators should confirm whether `workflow` scope is needed before workflow write operations.
5. The local shared-drive mount `G:\Shared drives\CERTASURV_PROJECT DRIVE` is missing on this host.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified visible control run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27974270514`
- Latest verified MACROTBC blocker run: `https://github.com/jarredsimpkins-bot/macrotbc/actions/runs/27974315508`
