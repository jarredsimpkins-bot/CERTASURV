# Certa Control Repo Launch Checklist

Last updated: 2026-06-22 06:31

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#40`, commit `e0cd20b`, success; latest visible release-ops run on June 22, 2026 is `#161`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Paths aligned, but local `G:` mount was missing on June 22, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo access on the host used for release operations | Verified on June 22, 2026 as `jarredsimpkins-bot` |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| WV courthouse remote configured | `WV_COURTHOUSE_RESEARCHER` release branch can be pushed for review | Blocked: checked release worktree has no remote |
| MACROTBC branch published | Local release commits are on the private GitHub remote | Blocked: latest cloud-readiness run fails repo-readiness |
| CERTASURV_WEB_APP CI green | Latest pushed web-app branch passes CI | Blocked: latest inspected run fails Ubuntu path handling test |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Use `gh run list` and `gh run view --log-failed` to inspect private workflow failures before release push decisions.
7. Push or PR MACROTBC only after its repo-local readiness checks pass.
8. Configure the WV courthouse upstream before rerunning the WV release-doc push.
9. Remount Google Drive for Desktop before final shared-drive handoff validation.

## Current Launch Blockers

1. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
2. `WV_COURTHOUSE_RESEARCHER` release docs are committed locally but blocked from review because no remote is configured in the checked worktree.
3. `MACROTBC` has two local commits ahead of origin and latest private cloud-readiness run `27926919931` fails repo-readiness.
4. `CERTASURV_WEB_APP` latest inspected private CI run `27802010837` fails `tests/test_survey_storage.py::test_associated_drive_survey_export_dir_uses_active_project_lane`.
5. `G:\Shared drives\CERTASURV_PROJECT DRIVE` was not mounted during the June 22, 2026 local provisioning check.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27769753846`
- Latest visible overall run during this pass: `#161` on branch `codex/release-control-wv-path-inventory-20260622-0904`, success on June 22, 2026
- Latest verified `main` run retained from prior pass: `#40` on branch `main`, success on June 18, 2026; prior feature-branch run `#39` also succeeded
- MACROTBC private workflow evidence: `https://github.com/jarredsimpkins-bot/macrotbc/actions/runs/27926919931`
- CERTASURV_WEB_APP private workflow evidence: `https://github.com/jarredsimpkins-bot/certasurv-web-app/actions/runs/27802010837`
