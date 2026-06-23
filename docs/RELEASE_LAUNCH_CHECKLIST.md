# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on current release branch | Latest visible `CertaHealth Control Checks` run is successful | Verified on June 23, 2026: run `28048277418`, run `#198`, branch `codex/launch-webapp-path-guard-20260623`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Blocked locally on June 23, 2026: provisioning check reports `G:` shared-drive mount missing |
| GitHub access for private repos | `gh` is authenticated with repo access on the host used for release operations | Verified on this host for `jarredsimpkins-bot`; token lacks `workflow` scope |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC cloud readiness | Latest visible `CertaSurv TBC Cloud Readiness` run is successful | Blocked: latest five visible runs failed June 22-23, 2026 |
| WV courthouse upstream | `WV_COURTHOUSE_RESEARCHER` has a configured GitHub remote and accessible repo | Blocked: local worktree has no visible `origin`; matching GitHub repo was not accessible |
| Shared-drive mount | Local release host can see `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Blocked in this session |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest visible control workflow run is green before handing off notes or switching remotes.
4. Verify the `G:` shared-drive mount is present before copying from committed repo docs into external handoff locations.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Re-run `gh auth status` before any private workflow/log inspection or release push that depends on GitHub CLI; add `workflow` scope before pushing `.github/workflows` changes.
7. Confirm MACROTBC readiness is green and WV_COURTHOUSE_RESEARCHER has an upstream before final launch review.

## Current Launch Blockers

1. MACROTBC readiness remains the primary release blocker before package handoff; latest visible run `28010372533` failed.
2. WV_COURTHOUSE_RESEARCHER is missing accessible upstream/remote readiness for push/review.
3. The local shared-drive mount is unavailable in this session, so staging/copy handoff work is blocked locally.
4. The GitHub CLI token lacks `workflow` scope, so workflow-file pushes remain blocked until re-auth.
5. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified visible control run during this pass: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/28048277418`
- Latest verified release-ops blocker run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/28045178871`
- Latest verified visible MACROTBC readiness signal: latest five `CertaSurv TBC Cloud Readiness` runs failed, ending with run `28010372533` on June 23, 2026.
- Local provisioning check: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` failed because the `G:` shared-drive mount, command-center folders, and `npm` on PATH were missing.
