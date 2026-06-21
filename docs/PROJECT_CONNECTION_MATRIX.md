# Certa Project Connection Matrix

Last updated: 2026-06-20 22:20 ET

This file is the working standard for making sure every active Certa/CertaSurv project has both outside connections and in-house production connections.

## Connection Lanes

| Lane | Purpose | Required Connection |
| --- | --- | --- |
| Outside source control | Publishable source handoff and PR/review workflow | Git remotes, GitHub account/tooling where needed |
| Outside operations drive | System-of-record folders, IDs, releases, and handoffs | `G:\Shared drives\CERTASURV_PROJECT DRIVE` |
| Outside phone/app operations | AppSheet and Google Sheets command center | Command-center workbook and registry IDs from `MACROTBC\command_center\command_center_manifest.json` |
| Outside automation | Google Apps Script Drive bootstrap and scraper | `AUTOMATIONS\share-drive-automation` package |
| In-house TBC production | Live TBC macros and worker services | `Trimble Business Center\MacroCommands3\CertaSurv` and Trimble services |
| In-house CAD standards | Templates, feature definitions, blocks, layers, symbols | ProgramData Trimble matrix and Feature Definition Manager |
| In-house local apps | Local web/dashboard/parcel/estimate tools | `CERTASURV_WEB_APP` plus local Python runtime |
| In-house coordination | Watchlists, nudges, drive staging helpers | `CERTARD` and `CERTAHEALTH` scripts |

## Project Matrix

| Project | Path | Outside Connections | In-House Connections | Current Status |
| --- | --- | --- | --- | --- |
| CERTAHEALTH | `C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH` | `origin` -> `https://github.com/jarredsimpkins-bot/CERTASURV.git`; planned dedicated repo exists as `certahealth.git` | Laptop load manager, project provisioning scripts | Active local control repo; remote-target decision still open |
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | Shared-drive mount helpers; `origin` -> `https://github.com/jarredsimpkins-bot/certard.git` | Project watchlist, staging scripts | Active coordination repo; push/review timing remains |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | AppSheet, Google Drive, command-center manifest; `origin` -> `https://github.com/jarredsimpkins-bot/macrotbc.git` | TBC macros, CAD resources, installers, sync scripts | Active production integration repo; dirty-tree triage blocks release handoff |
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | Needs Git remote and workflow visibility for release handoff | County records, courthouse research, ortho/LiDAR-to-basemap tooling, CertaSurv runbooks | Active local repo with dirty runbook/toolbox changes; remote setup is a launch blocker |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | Google Apps Script, Drive API, test shared drive automation; `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-automations.git` | Reproducible automation package | Active automation repo |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Shared-drive project data and estimate folders; `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` | Local Python app/dashboard tools | Active local app project after workspace rename from `New project2` |
| Trimble Business Center macros | `C:\Users\SimpS\OneDrive\Documents\Trimble Business Center\MacroCommands3\CertaSurv` | Mirrors to shared drive through MACROTBC | Live TBC macro command folder | Present locally |
| Feature Definition Manager | `C:\Users\SimpS\OneDrive\Documents\Feature Definition Manager` | Should be staged to shared drive CAD standards | Feature definition and CAD resources | Present locally |
| TBC templates matrix | `C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE` | Should be staged to shared drive TBC templates | Local drafting/template matrix | Present locally |

## Current Gaps Found

| Gap | Impact | Fix Path |
| --- | --- | --- |
| Shared drive mount missing on this host | Outside system-of-record folders cannot be verified or staged locally until Google Drive Desktop exposes `G:` again | Remount `G:\Shared drives\CERTASURV_PROJECT DRIVE` before release handoff or shared-drive packaging |
| MACROTBC dirty release branch | TBC handoff can accidentally omit or sweep generated command-center output without an intentional commit/ignore/defer pass | Review `codex/certasurv-unified-forward`, preserve release docs/config/source changes, and leave generated/cache artifacts out of release commits |
| MACROTBC shared-drive config missing locally | The TBC integration repo cannot prove its shared-drive target from `certasurv_shared_drive.json` during local release verification | Restore or regenerate `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json` before handoff |
| WV_COURTHOUSE_RESEARCHER has no observed remote | County-research release work cannot be pushed/reviewed from this host until remote setup is complete | Add `origin` for `jarredsimpkins-bot/wv-courthouse-researcher.git`, then push the reviewed release branch |
| CERTAHEALTH remote target is unresolved | Release notes and automation still need a final answer on whether the control repo stays on public `CERTASURV.git` or moves to `certahealth.git` | Decide the permanent GitHub destination before final launch cutover |
| GitHub CLI is installed but unauthenticated on this host | `gh`-driven release pushes and private workflow/log inspection are blocked until auth is restored | Run `gh auth login` with repo and workflow scopes |
| `node`, `npm`, and `pwsh` are not currently on PATH | Local release checks that expect PowerShell 7 or Node tooling will fail on this host without fallback commands | Normalize host PATH or install/reinstall Node.js LTS and PowerShell 7 when the machine is not under production load |

## Operating Rule

Production mode stays on by default. TBC, Trimble, the dashboard, CAD standards, and project handoff paths are protected first. Throttling is only for TBC heat/critical system management, not the normal mode.
