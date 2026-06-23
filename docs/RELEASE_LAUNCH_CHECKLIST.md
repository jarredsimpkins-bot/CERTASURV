# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on reviewed branch | Latest visible `CertaHealth Control Checks` run is successful before merge/release | Verified on June 23, 2026: run `#188`, commit `d457e02`, success on `codex/release-control-strict-webapp-wv-20260623-1102` |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Last verified on June 18, 2026: run `#40`, commit `e0cd20b`, success; refresh after release-control merge |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References intact, but `G:` mount missing during June 23, 2026 provisioning check |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Ready on this host for `jarredsimpkins-bot` with `repo` scope |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC release blocker reviewed | TBC command-center changes are reviewed without touching live Trimble runtime folders | Blocking |
| WV researcher release path approved | `WV_COURTHOUSE_RESEARCHER` has an approved remote/readiness path before upstream publication | Blocking |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on the active release branch is green, then refresh `main` after merge.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Review sibling worktrees without staging their local generated data: CERTARD and web app are mainly push/review timing, while MACROTBC and WV researcher remain launch blockers.

## Current Launch Blockers

1. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
2. MACROTBC remains a substantive blocker until command-center/TBC production changes are reviewed and stabilized.
3. WV_COURTHOUSE_RESEARCHER remains a substantive blocker until its remote/readiness path is approved.
4. The shared-drive mount is missing on this host, so external handoff package validation is blocked until Drive Desktop restores `G:`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified visible run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/28025042959`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27769753846`
- Latest verified overall run during this pass: `#188` on branch `codex/release-control-strict-webapp-wv-20260623-1102`, success on June 23, 2026; latest recent blocker-refresh run `#187` also succeeded
- Latest local provisioning check: Windows PowerShell ran `.\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` on June 23, 2026 and found missing `G:` shared-drive paths, WV researcher `LOCAL_ONLY`, and `npm` missing from PATH
