# Certa Control Repo Launch Checklist

Last updated: 2026-06-19

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 19, 2026: run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` and the `G:` mount is available on the active release host | Blocked on this host: refs exist, mount missing on June 19, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| Cross-repo blocker split confirmed | `CERTASURV_WEB_APP` is clean, `CERTARD` has only one modified liaison brief, and `MACROTBC` plus `WV_COURTHOUSE_RESEARCHER` remain the substantive blockers | Verified on June 19, 2026 |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools, auth gaps, or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Confirm `CERTARD` is intentionally left with only `drive/CERTASURV_LIAISON_BRIEF.md` modified, or clean it before release cutover.
7. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. The `G:\Shared drives\CERTASURV_PROJECT DRIVE` mount is missing on this host, so shared-drive staging and handoff validation cannot complete here.
2. `gh` is not authenticated on this host, so private workflow runs and logs cannot be inspected here.
3. `MACROTBC` still has substantive local changes, and `WV_COURTHOUSE_RESEARCHER` is still dirty with no `origin`.
4. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27803937263`
- Latest verified overall run during this pass: `#67` on branch `codex/release-ops-doc-refresh-20260619-0102`, success on June 19, 2026
