# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#40`, commit `e0cd20b`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| GitHub access for private repos | `gh` is authenticated on the host used for release operations | Authenticated as `jarredsimpkins-bot` with repo scope on June 23, 2026 |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Confirm `gh auth status` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. The `G:` shared-drive mount is not currently visible on this host, so shared-drive release handoff paths cannot be verified here.
2. `npm` is not on PATH for this host, so Node package workflows need PATH repair before web-app release checks.
3. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27769753846`
- Latest verified overall run during this pass: `#40` on branch `main`, success on June 18, 2026; prior feature-branch run `#39` also succeeded
