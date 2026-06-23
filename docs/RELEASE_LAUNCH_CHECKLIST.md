# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Current scripts no longer fall back to `New project2`; provisioning check guards script regressions |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References verified read-only on June 23, 2026; local `G:` mount is currently missing |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Authenticated as `jarredsimpkins-bot`; visible scopes are `gist`, `read:org`, `repo` |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| Blocker repos scoped | MACROTBC and WV_COURTHOUSE_RESEARCHER readiness is tracked separately from control-repo readiness | Blocked outside this repo; WV local repo has no configured remote |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` locally and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Run `gh auth status` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. The local shared-drive mount `G:\Shared drives\CERTASURV_PROJECT DRIVE` is missing, so shared-drive handoff/copy steps are blocked.
2. `npm` is not on PATH, so any local web-app release check that depends on package commands is blocked until PATH/tooling is fixed.
3. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
4. MACROTBC and WV_COURTHOUSE_RESEARCHER remain the substantive launch blockers; WV also needs a remote decision/configuration.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified feature-branch run during this pass: `#202`, branch `codex/release-control-webapp-path-guard-20260623-1923`, success on June 23, 2026
