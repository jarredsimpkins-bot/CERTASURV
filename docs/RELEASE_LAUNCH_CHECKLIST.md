# Certa Control Repo Launch Checklist

Last updated: 2026-06-22

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 22, 2026: latest `main` run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` and scripts do not fall back to `New project2` | Verified in current repo docs/scripts |
| CERTARD/CERTASURV_WEB_APP launch lane | Confirm CERTARD stays green and CERTASURV_WEB_APP gets a fresh green rerun after push/review timing | CERTARD ready; web-app rerun needed |
| MACROTBC release evidence | Owning repo has current workflow/status, command-center manifest, shared-drive config, and install/runbook evidence | Release blocker: latest run `#20` failed |
| WV_COURTHOUSE_RESEARCHER release evidence | Owning workspace has remote/upstream, runbook/install notes, and smoke-test or workflow evidence | Release blocker |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References intact; mount missing in this automation context |
| GitHub access for private repos | `gh` is authenticated with repo access on the host used for release operations | Ready for workflow inspection |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.
7. Treat MACROTBC and WV_COURTHOUSE_RESEARCHER as the active launch blockers until their owning repos provide fresh push/review/runbook evidence.

## Current Launch Blockers

1. MACROTBC still needs owning-repo release evidence before launch cutover; latest failure is folder-map/shared-config path readiness.
2. WV_COURTHOUSE_RESEARCHER still needs remote/upstream and runbook evidence before launch cutover.
3. CERTASURV_WEB_APP needs a fresh pushed CI rerun; latest remote failure is the Windows-style project path basename test on Linux.
4. Final-host provisioning is incomplete: shared drive is not mounted, MACROTBC shared-drive config is missing locally, and `node`/`npm` are not on PATH.
5. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall run during this pass: `#157` on branch `codex/release-control-webapp-path-guard-20260622-automation`, success on June 22, 2026
- Latest sibling-repo workflow notes: CERTARD `#31` success; MACROTBC `#20` failure; CERTASURV_WEB_APP `#6` failure pending clean rerun
