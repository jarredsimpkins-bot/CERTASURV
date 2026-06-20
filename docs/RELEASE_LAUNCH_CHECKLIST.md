# Certa Control Repo Launch Checklist

Last updated: 2026-06-20

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 20, 2026: latest `main` run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References exist, but `G:` is not mounted in this session |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| Local release tools visible | `pwsh`, Node, npm, git, gh, and Python are visible to the release shell | `pwsh`, Node, and npm missing from PATH in this session |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts. If `pwsh` is not available, run the same script with Windows PowerShell and treat missing `pwsh` as a release-tooling gap.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. `G:` shared drive, `pwsh`, Node, and npm are not available in this shell, so final handoff and web-app validation need host PATH/mount repair.
4. MACROTBC and WV_COURTHOUSE_RESEARCHER remain the substantive stack blockers; CERTARD and CERTASURV_WEB_APP are locally clean enough for push/review timing.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall run during this pass: `#80` on branch `codex/release-control-webapp-path-hardening-20260620`, success on June 20, 2026
