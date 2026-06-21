# Certa Control Repo Launch Checklist

Last updated: 2026-06-21

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow visible and green | Latest visible public `CertaHealth Control Checks` run is successful; latest verified `main` run is also successful | Overall run `#128`, commit `dc80fd4`, success on June 21, 2026; `main` run `#41`, commit `6f40b64`, success on June 18, 2026 |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| CERTARD release lane | Repo remote and local path are known; release state mainly needs push/review timing | Ready with review timing |
| CERTASURV_WEB_APP release lane | Repo remote and active renamed workspace are known; release state mainly needs push/review timing | Ready with review timing |
| MACROTBC release lane | Production integration repo has intended remote, but dirty/untracked production artifacts still need curated release review | Blocked |
| WV_COURTHOUSE_RESEARCHER release lane | Repo exists locally as a Git worktree, but `origin` is not configured and dirty toolkit/runbook edits need review | Blocked |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. For MACROTBC, stage only intended release artifacts and avoid sweeping local generated output or runtime logs into the launch commit.
8. For WV_COURTHOUSE_RESEARCHER, set `origin` to `https://github.com/jarredsimpkins-bot/wv-courthouse-researcher.git`, push the active branch, and review the runbook/toolkit edits.

## Current Launch Blockers

1. MACROTBC remains the main production integration blocker because local dirty/untracked artifacts need curated release review before push.
2. WV_COURTHOUSE_RESEARCHER remains blocked by missing `origin` on this host plus dirty runbook/toolkit edits that need review.
3. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
4. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest visible overall run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27903398654`
- Latest verified overall run during this pass: `#128` on branch `codex/release-ops-wv-macrotbc-control-readiness-20260621`, success on June 21, 2026
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
