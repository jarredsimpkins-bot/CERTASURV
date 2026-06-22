# Certa Release Blocker Register

Last updated: 2026-06-22 01:25 ET

This register keeps the release-ops view focused on the repositories that still need substantive launch work. It is repo-local evidence only; do not edit live shared-drive handoff content from this file.

## Current Blockers

| Repo | Local path | Current signal | Release impact | Next gate |
| --- | --- | --- | --- | --- |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | Present locally on `codex/certasurv-unified-forward`; working tree has broad tracked deletions plus generated/untracked outputs; `certasurv_shared_drive.json` is missing locally | Blocks TBC command-center and macro package confidence until the dirty tree is reconciled and pushed/reviewed | Separate intended source deletions from generated artifacts, restore or document required root files, then run repo-local validation before push |
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | Present locally on `codex/wv-courthouse-researcher-cabell-lessons`; runbook, toolbox, workflow, and registry files are modified; no remote is configured locally | Blocks courthouse/title research handoff until the new toolkit/runbook behavior is reviewed, committed, and pushable | Review the modified docs/scripts/registry together, configure the remote, run the toolkit smoke check, then commit and push a scoped branch |

## Non-Blocking Repos

| Repo | Current signal | Release impact |
| --- | --- | --- |
| CERTARD | Local branch `codex/certasurv-unified-forward` is tracking its remote | Clean enough for push/review timing rather than active release-ops intervention |
| CERTASURV_WEB_APP | Current launch focus says this repo is already clean locally; local inspection still showed unrelated generated outputs and prior file deletions in the working tree | Treat as push/review timing unless the web-app owner asks release ops to reconcile its local artifacts |
| CERTAHEALTH | Control workflow is public and latest visible run `#151` succeeded on June 22, 2026 | Control repo can keep publishing readiness docs while the final remote destination remains a cutover decision |

## Standing External Blockers

1. GitHub CLI is installed but unauthenticated on this host, so private repository workflow outputs and logs cannot be inspected locally.
2. The permanent control-repo remote remains unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.
3. `G:` shared drive is not mounted in this shell, so staged handoff folders cannot be verified.
4. Node/npm are not on PATH in this shell.
5. Shared-drive staging docs remain read-only from release ops unless copied from committed repo files as generated documentation.
