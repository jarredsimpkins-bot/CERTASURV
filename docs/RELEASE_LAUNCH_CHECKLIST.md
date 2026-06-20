# Certa Control Repo Launch Checklist

Last updated: 2026-06-20

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green | Latest public `CertaHealth Control Checks` run is successful | Verified on June 20, 2026: run `#95`, branch `codex/release-ops-blocker-map-20260620b`, commit `b667b15`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` and mount is available locally | Blocked; `G:` shared-drive mount missing on June 20, 2026 provisioning run |
| MACROTBC release branch classified | Deleted tracked roots, missing shared-drive config, build outputs, and generated packages are separated before release push | Blocked pending owner review |
| WV courthouse remote attached | `WV_COURTHOUSE_RESEARCHER` has an `origin` remote and upstream branch | Blocked; no remote observed on June 20, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Restore or verify the `G:` shared-drive mount before staging or handoff validation.
6. For MACROTBC, separate intended release deletions from generated `dist`, backup, package outputs, and the missing shared-drive config before any push.
7. For WV_COURTHOUSE_RESEARCHER, attach the planned remote and set upstream before handing WV release work to review.
8. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
9. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. The `G:` shared-drive mount is unavailable on this host during the June 20, 2026 provisioning run.
4. MACROTBC still needs release-branch cleanup/review before push timing, including the missing `certasurv_shared_drive.json`.
5. WV_COURTHOUSE_RESEARCHER has no observed remote/upstream, so WV work cannot be pushed for review from the normal launch lane.
6. Node/npm are unavailable in this shell, so web tooling verification must run elsewhere until PATH/install is repaired.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27872786268`
- Latest verified overall run during this pass: `#95` on branch `codex/release-ops-blocker-map-20260620b`, success on June 20, 2026; recent runs `#91` through `#95` also succeeded
