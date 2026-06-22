# Certa Control Repo Launch Checklist

Last updated: 2026-06-22

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 22, 2026: latest visible `main` run `#41`, commit `6f40b64`, success |
| Current public workflow signal | Latest visible public run is successful, even when it is not on `main` | Verified on June 22, 2026: run `#168`, branch `codex/release-control-webapp-path-guard-20260622-790c`, commit `f4144ce`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` and scripts do not fall back to `New project2` | Enforced by workflow guard |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| WV courthouse researcher release lane | `WV_COURTHOUSE_RESEARCHER` has reviewed local changes plus configured origin/upstream | Blocked: local changes exist and no remote is configured |
| Web app local hygiene | `CERTASURV_WEB_APP` status excludes generated/data/cache output from release commits | Needs cleanup before push from observed checkout |
| MACROTBC release lane | `MACROTBC` command-center/AppSheet handoff has release review and push timing confirmed | Still substantive launch blocker |
| GitHub access for private repos | `gh` is authenticated with repo access on the host used for release operations | Verified on this host as `jarredsimpkins-bot` |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Review `WV_COURTHOUSE_RESEARCHER` local changes, configure its remote, and push the selected branch before treating the courthouse lane as releasable.
6. Review `CERTASURV_WEB_APP` generated/data/cache changes before any release push from that repo.
7. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
8. Re-run `gh auth status` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. MACROTBC remains the main production integration release blocker until its command-center/AppSheet handoff is reviewed and pushed.
2. `WV_COURTHOUSE_RESEARCHER` is local-only in the observed checkout and has uncommitted release-prep files.
3. `CERTASURV_WEB_APP` has many generated/data/cache changes in this checkout and should not be swept into a release commit.
4. `G:\Shared drives\CERTASURV_PROJECT DRIVE` must be mounted before live shared-drive staging is revalidated.
5. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified visible run during this pass: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27959104024`, run `#168`, success on June 22, 2026
