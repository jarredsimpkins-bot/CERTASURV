# Certa Control Repo Launch Checklist

Last updated: 2026-06-22 12:20

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 22, 2026: latest `main` run is `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Legacy web app path blocked | Workflow rejects `New project2` references in control PowerShell scripts | Added to control workflow |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Expected target still documented; current host mount is missing |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| Sibling repo blocker scope | CERTARD/WEB_APP are review-timing items once their intended clean release branch/worktree is selected; MACROTBC/WV_COURTHOUSE_RESEARCHER remain substantive release blockers | Needs shared-drive mount, MACROTBC, and WV closeout |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Confirm the clean release branch/worktree for CERTARD and CERTASURV_WEB_APP before treating either repo as push/review-only; the live OneDrive roots can contain generated local clutter.
8. Restore the `G:` shared-drive mount and command-center folders before validating or copying handoff materials.
9. In MACROTBC, resolve tracked package/config deletions, restore or replace `certasurv_shared_drive.json`, generated outputs, and command-center CSV deltas before release handoff.
10. In WV_COURTHOUSE_RESEARCHER, finish or intentionally clear the active toolkit/runbook/tool registry edits, set/confirm upstream tracking, and rerun the repo smoke checks before release handoff.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. The `G:` shared-drive mount and command-center folders are missing in the current provisioning run.
4. MACROTBC and WV_COURTHOUSE_RESEARCHER still need repo-local closeout before they can be considered launch-ready.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall run during this pass: `#149` on branch `codex/release-control-webapp-path-guard-20260622-0004`, success on June 22, 2026
