# Certa Control Repo Launch Checklist

Last updated: 2026-06-22

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 22, 2026: latest `main` run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Control scripts now use the canonical path directly |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Verified on June 22, 2026 for CERTARD, MACROTBC, and CERTASURV_WEB_APP metadata |
| MACROTBC release checks | Latest private cloud-readiness run is green | Blocked: run `27970712914` failed in `validate-package` |
| WV courthouse release ownership | Local changes are clean or intentionally committed and the target remote is known | Blocked: local workspace has uncommitted changes and no `origin` remote reported here |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open; `certahealth` did not resolve through `gh repo view` |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Inspect MACROTBC and WV_COURTHOUSE_RESEARCHER blockers before treating the stack as release-ready.

## Current Launch Blockers

1. MACROTBC private workflow `CertaSurv TBC Cloud Readiness` is failing on branch `codex/certasurv-unified-forward`.
2. WV_COURTHOUSE_RESEARCHER has uncommitted local release/tooling changes and no `origin` remote reported in this pass.
3. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and a dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall public run during this pass: `#172` on branch `codex/release-ops-live-blockers-20260622-1230`, success on June 22, 2026
- Latest observed MACROTBC failure: `https://github.com/jarredsimpkins-bot/macrotbc/actions/runs/27970712914`
