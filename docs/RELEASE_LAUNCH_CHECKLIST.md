# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 23, 2026: latest `main` run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References exist, but the `G:` mount was missing on June 23, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Authenticated as `jarredsimpkins-bot`; no explicit `workflow` scope shown |
| WV courthouse release path | Local WV repo has a remote/upstream release destination | Blocked: local repo exists but has no configured remote |
| Current substantive blockers | MACROTBC and WV_COURTHOUSE_RESEARCHER are ready for release review | Blocked in sibling repos |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts. Use `pwsh` only on hosts where PowerShell 7 is installed.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Restore the `G:` shared-drive mount before copying generated docs into shared-drive handoff locations.
6. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
7. Confirm `gh` has all scopes needed for private workflow/log inspection or release pushes that depend on GitHub CLI.

## Current Launch Blockers

1. The shared-drive `G:` mount is missing on this host, so shared-drive release handoff steps are blocked.
2. `npm` is not on PATH in this shell, so Node package checks require PATH repair or an explicit npm path.
3. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
4. MACROTBC and WV_COURTHOUSE_RESEARCHER remain the substantive release blockers; WV also lacks a configured remote/upstream.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall public run during this pass: `#200` on branch `codex/release-control-webapp-path-guard-20260623-selfsafe`, success on June 23, 2026
