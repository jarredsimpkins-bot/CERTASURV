# Certa Control Repo Launch Checklist

Last updated: 2026-06-22

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | Latest public `CertaHealth Control Checks` run for `main` is successful | Verified on June 18, 2026: run `#40`, commit `e0cd20b`, success |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | References intact; local `G:` mount missing on June 22, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Authenticated as `jarredsimpkins-bot`; private run list works |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |
| MACROTBC launch blocker cleared | TBC command-center, installer/runbook, and package/workflow review are complete | Latest unified-forward workflow failed on June 22, 2026 |
| WV courthouse launch blocker cleared | `WV_COURTHOUSE_RESEARCHER` has confirmed origin/branch plus courthouse/title package review | No remote configured; local docs/toolkit changes need review |
| Clean timing-only lanes | `CERTARD` and `CERTASURV_WEB_APP` have no new substantive local blockers beyond push/review timing | CERTARD main green; web app remains timing/review lane |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts. Use `pwsh` only when PowerShell 7 is available on PATH.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Use `gh run list --repo jarredsimpkins-bot/macrotbc --limit 5` and the equivalent private repo checks to confirm the latest blocker state before release handoff.
7. Clear MACROTBC and WV_COURTHOUSE_RESEARCHER before spending release time on already-clean CERTARD or CERTASURV_WEB_APP timing lanes.

## Current Launch Blockers

1. MACROTBC remains the substantive production-integration blocker: latest `codex/certasurv-unified-forward` workflow failed on June 22, 2026.
2. WV_COURTHOUSE_RESEARCHER remains the substantive courthouse/title blocker: local branch `codex/wv-courthouse-researcher-cabell-lessons` has uncommitted docs/toolkit changes and no remote configured.
3. The local `G:` shared-drive mount is missing, so shared-drive handoff validation/copying is blocked.
4. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Latest verified `main` run: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/runs/27769753846`
- Latest verified control run during this pass: `#171` on branch `codex/release-ops-wv-macrotbc-readiness-20260622-1430`, success on June 22, 2026; latest `main` run `#41` also succeeded
