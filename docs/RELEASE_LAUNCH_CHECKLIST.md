# Certa Control Repo Launch Checklist

Last updated: 2026-06-22

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 22, 2026: latest `main` run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Live `G:` mount missing on this host during June 22 check |
| GitHub access for private repos | `gh` is authenticated with repo access on the host used for release operations | Verified for `jarredsimpkins-bot` on June 22, 2026 |
| MACROTBC release lane | Private `macrotbc` remote exists and active branch remains production integration work | Substantive release blocker |
| WV courthouse release lane | Local `WV_COURTHOUSE_RESEARCHER` is included in control checks and needs remote readiness | Blocked: no resolvable `wv-courthouse-researcher` repo/remote yet |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Blocked: `certahealth` repo not resolvable via `gh repo view` |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Review dirty local changes in `WV_COURTHOUSE_RESEARCHER`, then create/assign its remote before pushing.
7. Treat MACROTBC and WV courthouse as the active release blockers; keep CERTARD and `CERTASURV_WEB_APP` focused on push/review timing unless their checks regress.

## Current Launch Blockers

1. `WV_COURTHOUSE_RESEARCHER` has local dirty work and no currently resolvable GitHub remote.
2. MACROTBC remains the substantive TBC/AppSheet/shared-drive integration blocker.
3. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and a dedicated `certahealth.git`; `certahealth` is not currently resolvable through GitHub CLI.
4. The `G:` shared-drive mount is missing on this host, so live staged-release verification is blocked.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall run during this pass: `#164` on branch `codex/release-control-webapp-path-guard-20260622-673d`, success on June 22, 2026
