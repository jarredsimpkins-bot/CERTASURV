# Certa Control Repo Launch Checklist

Last updated: 2026-06-22

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| CERTARD/web app lanes | `certard` and `certasurv-web-app` have known remotes and are mainly waiting on push/review timing | Ready for push/review timing |
| MACROTBC lane | `macrotbc.git` target and command-center handoff inputs are represented in release docs/scripts | Needs private check/log review and missing shared-drive config closeout |
| WV courthouse lane | `WV_COURTHOUSE_RESEARCHER` is represented in release docs/scripts and provisioning checks | Needs remote/upstream closeout |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Blocked locally on June 22, 2026 because `G:` was not mounted |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. For MACROTBC, confirm the release branch is pushed, private workflow checks are green, and command-center package evidence is current, including `certasurv_shared_drive.json`.
6. For WV_COURTHOUSE_RESEARCHER, confirm `origin` points to `wv-courthouse-researcher.git`, push the active release branch, and resolve the current local changes before review.
7. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
8. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. MACROTBC still needs private release evidence review before it can be treated as launch-ready.
3. WV_COURTHOUSE_RESEARCHER still needs remote/upstream closeout and review of local uncommitted changes.
4. The local shared drive mount is unavailable, blocking shared-drive handoff verification.
5. Node/npm are missing from PATH in this shell, which can affect web tooling even though the web-app lane is otherwise clean.
6. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall run during this pass: `#153` on branch `codex/release-control-webapp-path-guard-20260622-run2`, success on June 22, 2026
