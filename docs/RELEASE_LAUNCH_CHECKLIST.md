# Certa Control Repo Launch Checklist

Last updated: 2026-06-23

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#40`, commit `e0cd20b`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Blocked on current host: provisioning check did not find the `G:` shared-drive mount |
| GitHub access for private repos | `gh` is authenticated with repo access on the host used for release operations | Verified on June 23, 2026; private run listings work |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC cloud readiness | Latest `CertaSurv TBC Cloud Readiness` run is successful | Blocking: run `28000398484` failed on June 23, 2026 |
| WV courthouse researcher upstream | Local repo has a configured remote/upstream and reviewed release edits | Blocking: no remote listed during this pass |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Use `gh run list` to recheck CERTARD, CERTASURV_WEB_APP, MACROTBC, and control-repo workflows before launch review.
7. Keep sibling repo dirty trees out of control-repo commits; only copy generated release docs from committed repo files.

## Current Launch Blockers

1. MACROTBC cloud-readiness workflow is still failing.
2. WV_COURTHOUSE_RESEARCHER needs remote/upstream setup and review of active local edits.
3. Shared-drive handoff validation is blocked until `G:\Shared drives\CERTASURV_PROJECT DRIVE` is mounted again.
4. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified release-control branch run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/28000329578`
- Latest verified MACROTBC failed run: `https://github.com/jarredsimpkins-bot/macrotbc/actions/runs/28000398484`
