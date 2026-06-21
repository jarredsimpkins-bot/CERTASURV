# Certa Control Repo Launch Checklist

Last updated: 2026-06-21

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 21, 2026 via public API: latest `main` run `#41`, commit `6f40b64`, success |
| Latest release branch workflow green | Latest visible public feature/release branch run is successful | Verified on June 21, 2026: run `#137`, commit `d008373`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Push/review timing lanes separated | CERTARD and CERTASURV_WEB_APP are treated as review-timing items unless new functional changes appear | Ready |
| MACROTBC release branch scoped | Dirty/generated/deleted local state has been reduced to an intentional pushable change set | Blocked |
| WV courthouse remote ready | WV_COURTHOUSE_RESEARCHER has a configured remote and upstream branch | Blocked: local repo has no remote |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Blocked in this session: `G:` shared drive is not mounted |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Run `.\scripts\Set-CertaGitRemotes.ps1` first as a dry run and verify WV_COURTHOUSE_RESEARCHER maps to the intended GitHub repository before using `-Apply`.
8. Treat MACROTBC generated outputs and deleted tracked files as a release split decision, not an automatic bulk commit.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. MACROTBC has unresolved local release scope: deleted tracked files, generated outputs, and command-center usage updates need intentional staging.
4. WV_COURTHOUSE_RESEARCHER has modified launch/toolkit files but no configured remote/upstream.
5. The `G:` shared-drive mount is unavailable in this host session, blocking final shared-drive handoff verification.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified visible feature run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27918857885`
