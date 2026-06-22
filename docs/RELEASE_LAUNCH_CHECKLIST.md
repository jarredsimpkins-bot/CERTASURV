# Certa Control Repo Launch Checklist

Last updated: 2026-06-22

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 22, 2026: latest `main` run `#41`, commit `6f40b64`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` and includes `WV_COURTHOUSE_RESEARCHER` in local release inventories | Required by workflow inventory guard |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Mount was unavailable in the June 22 automation shell; re-check on launch host |
| GitHub access for private repos | `gh` is authenticated with repo access on the host used for release operations | Verified on June 22, 2026 as `jarredsimpkins-bot` |
| MACROTBC release blocker | `MACROTBC` branch and command-center handoff are ready for review/push | Still substantive launch blocker |
| WV courthouse release blocker | `WV_COURTHOUSE_RESEARCHER` has remote/upstream and local release edits reviewed | Still substantive launch blocker |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Re-run `gh auth status` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. MACROTBC remains the main production integration release blocker until its command-center/AppSheet handoff is reviewed and pushed.
2. WV courthouse researcher remains blocked on remote/upstream setup plus review of current local edits.
3. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27773432493`
- Latest verified visible run during this pass: `#166` on branch `codex/release-control-wv-inventory-20260622-1207`, success on June 22, 2026
