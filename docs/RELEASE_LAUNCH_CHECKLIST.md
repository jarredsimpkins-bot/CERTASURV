# Certa Control Repo Launch Checklist

Last updated: 2026-06-20

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Local release shell available | `pwsh` is available for operator commands, or Windows PowerShell fallback is recorded | `pwsh` is now reported by provisioning checks |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Repo-local references checked June 20, 2026 ET; current host provisioning reports the `G:` mount missing |
| MACROTBC release branch intentional | Dirty local TBC command-center and generated artifacts are sorted into commit/ignore/defer buckets before push | Blocking |
| WV courthouse repo remotely publishable | `WV_COURTHOUSE_RESEARCHER` has a configured `origin` and a reviewed release branch | Blocking |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts. If `pwsh` is unavailable on this host, use `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and keep `pwsh` in the gap list.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. For MACROTBC, capture the intended release branch and explicitly separate generated/cache output from handoff docs, command-center config, and macro source changes.
6. For WV_COURTHOUSE_RESEARCHER, configure the remote, review the dirty docs/scripts, then push the selected release branch.
7. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
8. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. MACROTBC has a dirty local release branch and needs an intentional publish/cleanup decision before TBC handoff.
2. WV_COURTHOUSE_RESEARCHER has no observed `origin` and needs remote setup plus release-branch review.
3. Local release execution is blocked until missing tools/mounts reported by `Test-CertaProjectProvisioning.ps1` are restored or explicitly deferred: shared-drive `G:` mount, MACROTBC shared-drive config, `node`, `npm`, and `pwsh`.
4. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
5. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall run during this pass: `#107` on branch `codex/release-control-webapp-strict-main-20260621`, success on June 21, 2026 UTC; latest `main` run `#41` also succeeded
