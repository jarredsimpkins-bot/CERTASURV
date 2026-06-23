# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green | Latest `CertaHealth Control Checks` run is successful | Verified on June 23, 2026: run `#180`, branch `codex/release-control-webapp-path-guard-20260623`, commit `5fc5261`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Path is not mounted in this worktree context on June 23, 2026; verify before live handoff |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Ready on this host as `jarredsimpkins-bot` with `repo` scope |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC readiness green | Latest `CertaSurv TBC Cloud Readiness` run passes | Blocked: run `#31` fails `Shared config TBC control root exists` |
| WV courthouse upstream connected | WV_COURTHOUSE_RESEARCHER has an `origin` and visible GitHub repo | Blocked: no local `origin`; planned repo missing or inaccessible |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest control workflow run is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Recheck `gh auth status` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Require a green MACROTBC readiness run and a WV courthouse remote before declaring release operations unblocked.

## Current Launch Blockers

1. MACROTBC `CertaSurv TBC Cloud Readiness` run `#31` fails because `Shared config TBC control root exists` is missing in the GitHub runner context.
2. WV_COURTHOUSE_RESEARCHER has no configured `origin`, and the expected GitHub repo name is missing or inaccessible from this host.
3. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and a dedicated `certahealth.git`; the dedicated repo is not visible to `gh` from this host.
4. `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted in this worktree context, so live shared-drive handoff must wait for local mount verification.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified control run during this pass: `#180` on branch `codex/release-control-webapp-path-guard-20260623`, success on June 23, 2026
- Latest verified release-ops refresh run: `#179` on branch `codex/release-ops-readiness-refresh-20260623`, success on June 23, 2026
- Latest verified MACROTBC blocker run: `https://github.com/jarredsimpkins-bot/macrotbc/actions/runs/28000398484`
