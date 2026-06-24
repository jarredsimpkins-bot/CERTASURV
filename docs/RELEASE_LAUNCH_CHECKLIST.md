# Certa Control Repo Launch Checklist

Last updated: 2026-06-24

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 24, 2026: latest `main` run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Repo references intact; `G:` mount unavailable on this host during June 24 check |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Ready on this host as `jarredsimpkins-bot` |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC release blocker cleared | Local MACROTBC changes are reviewed and either committed or intentionally left out of launch | Blocked: command usage log modified |
| WV_COURTHOUSE_RESEARCHER remote ready | GitHub repo exists, `origin` is set, and local runbook/toolkit edits are committed or triaged | Blocked: no remote/repo resolved |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Confirm `gh auth status` still shows `jarredsimpkins-bot` before private workflow/log inspection or release push.
7. Run `git -C C:\Users\SimpS\OneDrive\Documents\MACROTBC status --short --branch` and clear the command usage log decision.
8. Run `git -C C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER remote -v` and create/set the missing remote before launch packaging.

## Current Launch Blockers

1. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
2. MACROTBC still has a local modified command usage log that needs an owner decision before release handoff.
3. WV_COURTHOUSE_RESEARCHER has no configured remote and no resolved GitHub repo under the expected slug.
4. The shared-drive `G:` mount is unavailable on this host, so staged handoff packages cannot be verified here yet.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified overall run during this pass: `#211` on branch `codex/release-ops-gh-refresh-20260624`, success on June 24, 2026
