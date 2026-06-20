# Certa Control Repo Launch Checklist

Last updated: 2026-06-20

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 20, 2026: latest `main` run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Provisioning check is worktree-safe | Git remotes are detected through `git -C <path>` instead of direct `.git/config` inspection | Verified locally on June 20, 2026 |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Blocker repo state known | MACROTBC and WV_COURTHOUSE_RESEARCHER local git state is checked before release handoff | MACROTBC clean; WV has local edits and no remote/upstream |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Blocked locally until `G:` shared drive is mounted |
| Node/npm available for app-adjacent checks | Local shell can run Node/npm when release control calls app tooling | Blocked on this host; not on `PATH` |
| Local provisioning shell available | Release host can run the provisioning script locally | Windows PowerShell works; `pwsh` is not on `PATH` |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed`; if `pwsh` is unavailable on this host, use `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed`.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Check `MACROTBC` and `WV_COURTHOUSE_RESEARCHER` git status; do not treat the stack as release-ready while WV has no remote/upstream.
5. Verify external handoff references remain read-only unless copying from committed repo docs.
6. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
7. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. `G:\Shared drives\CERTASURV_PROJECT DRIVE` is not mounted on this host, so shared-drive release checks cannot pass locally.
2. `node` and `npm` are not on `PATH`, so app-adjacent local checks need PATH repair or a different host.
3. `pwsh` is not on `PATH`; local provisioning checks currently need Windows PowerShell fallback or PowerShell 7 installation.
4. `WV_COURTHOUSE_RESEARCHER` has uncommitted launch-toolkit edits and no configured remote/upstream in this checkout.
5. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
6. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall run during this pass: `#83` on branch `codex/release-control-worktree-provisioning-20260620`, success on June 20, 2026
