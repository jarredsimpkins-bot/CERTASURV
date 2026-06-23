# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green | Latest visible `CertaHealth Control Checks` runs are successful | Verified on June 23, 2026: run `28004863391`, branch `codex/release-control-path-gh-refresh-20260623-0125`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References are intact, but the `G:` shared drive mount is missing in this session |
| GitHub access for repo checks | `gh` is authenticated with repo access on the host used for release operations | `gh auth status` succeeds for `jarredsimpkins-bot`; workflow list check succeeds for public control repo |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC release state decided | Dirty runtime/log changes are committed only if intentional release evidence | Blocked: `command_center/tbc/command_usage_log.csv` is modified |
| WV courthouse upstream ready | Local researcher branch has an `origin` remote and pushed branch for review | Blocked: no `origin` remote; six modified files remain local |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest visible control workflow run is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Keep `gh auth status` green before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Resolve MACROTBC and WV_COURTHOUSE_RESEARCHER blockers before declaring the full stack launch-ready.

## Current Launch Blockers

1. MACROTBC still has a modified `command_center/tbc/command_usage_log.csv`; classify it as release evidence or local runtime noise.
2. WV_COURTHOUSE_RESEARCHER has no `origin` remote and has six modified local files on `codex/wv-courthouse-researcher-cabell-lessons`.
3. The local shared-drive mount `G:\Shared drives\CERTASURV_PROJECT DRIVE` is unavailable in this session.
4. `npm` is still missing from PATH in this shell.
5. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified visible run during this pass: `28004863391` on branch `codex/release-control-path-gh-refresh-20260623-0125`, success on June 23, 2026
