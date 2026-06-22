# Certa Control Repo Launch Checklist

Last updated: 2026-06-22

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on control branches | Latest visible public `CertaHealth Control Checks` runs are successful | Verified on June 22, 2026: runs `#147`-`#151` all succeeded; latest `#151`, commit `d2019e4` |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Blocker register current | MACROTBC and WV_COURTHOUSE_RESEARCHER have explicit blocker status and next gates | Required by workflow after this pass |
| Shared-drive handoff references intact | External staging/deploy references should point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Blocked in this shell because `G:` is not mounted |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` or Windows PowerShell equivalent and record any missing tools or mounts.
3. Confirm the latest public control workflow run is green before handing off notes or switching remotes.
4. Check `docs/RELEASE_BLOCKER_REGISTER.md` and close MACROTBC plus WV_COURTHOUSE_RESEARCHER before final launch signoff.
5. Verify external handoff references remain read-only unless copying from committed repo docs.
6. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
7. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. `G:` shared drive is not mounted in this shell, so staged handoff folders cannot be verified.
2. MACROTBC has an unreconciled working tree with tracked deletions plus generated/untracked outputs, and `certasurv_shared_drive.json` is missing locally.
3. WV_COURTHOUSE_RESEARCHER has modified toolkit/runbook/registry files awaiting review, smoke test, commit, and push; local git has no remote configured.
4. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
5. Node/npm are not on PATH in this shell.
6. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified visible run during this pass: `#151` on branch `codex/release-control-wv-path-hardening-20260622`, success on June 22, 2026
