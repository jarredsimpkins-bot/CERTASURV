# Certa Project Connection Matrix

Last updated: 2026-06-17 06:00 ET

This file is the working standard for making sure every active Certa/CertaSurv project has both outside connections and in-house production connections.

## Connection Lanes

| Lane | Purpose | Required Connection |
| --- | --- | --- |
| Outside source control | Publishable source handoff and PR/review workflow | Git remotes, GitHub account/tooling where needed |
| Outside operations drive | System-of-record folders, IDs, releases, and handoffs | `G:\Shared drives\CERTASURV_PROJECT DRIVE` (`CERTASTRUCT` system-of-record lane) |
| Outside phone/app operations | AppSheet and Google Sheets command center | Command-center workbook and registry IDs from `MACROTBC\command_center\command_center_manifest.json` |
| Outside automation | Google Apps Script Drive bootstrap and scraper | `AUTOMATIONS\share-drive-automation` package |
| In-house TBC production | Live TBC macros and worker services | `Trimble Business Center\MacroCommands3\CertaSurv` and Trimble services |
| In-house CAD standards | Templates, feature definitions, blocks, layers, symbols | ProgramData Trimble matrix and Feature Definition Manager |
| In-house local apps | Local web/dashboard/parcel/estimate tools | `CERTASURV_WEB_APP` plus local Python runtime |
| In-house coordination | Watchlists, nudges, drive staging helpers | `CERTARD` and `CERTAHEALTH` scripts |

## Project Matrix

| Project | Path | Outside Connections | In-House Connections | Current Status |
| --- | --- | --- | --- | --- |
| CERTAHEALTH | `C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH` | Live public control remote on `CERTASURV.git`; dedicated `certahealth.git` still planned | Laptop load manager, project provisioning scripts | Active local control repo |
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | Shared-drive mount helpers and Git remote present | Project watchlist, staging scripts | Active coordination repo |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | AppSheet, Google Drive, command-center manifest, Git remote present | TBC macros, CAD resources, installers, sync scripts | Active production integration repo |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | Google Apps Script, Drive API, test shared drive automation, Git remote present | Reproducible automation package | Active automation repo |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Shared-drive project data and estimate folders; Git remote present | Local Python app/dashboard tools | Active local app project |
| Trimble Business Center macros | `C:\Users\SimpS\OneDrive\Documents\Trimble Business Center\MacroCommands3\CertaSurv` | Mirrors to shared drive through MACROTBC | Live TBC macro command folder | Present locally |
| Feature Definition Manager | `C:\Users\SimpS\OneDrive\Documents\Feature Definition Manager` | Should be staged to shared drive CAD standards | Feature definition and CAD resources | Present locally |
| TBC templates matrix | `C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE` | Should be staged to shared drive TBC templates | Local drafting/template matrix | Present locally |

## Current Readiness Signals

| Signal | Impact | Evidence |
| --- | --- | --- |
| Shared drive mounted and staged | Outside system-of-record folders are available locally | Latest stage log: `G:\Shared drives\CERTASURV_PROJECT DRIVE\00_CERTASURV_COMMAND_CENTER\08_REPORTS_EXPORTS\drive-stage-log-20260522-194113.txt` |
| Public control workflow green | Repo-local control checks are passing in GitHub Actions | `CertaHealth Control Checks` succeeded on 2026-06-17 09:12 UTC |
| Canonical web app rename is live | Launch scripts must stop depending on the removed `New project2` path | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` exists; `C:\Users\SimpS\OneDrive\Documents\New project2` does not |

## Current Gaps Found

| Gap | Impact | Fix Path |
| --- | --- | --- |
| GitHub CLI not authenticated | Private repo workflow, run-log, and artifact inspection is still blocked from this machine | Run `gh auth login` before private-repo release review |
| CERTAHEALTH remote naming split | Control docs and scripts must distinguish the live public `CERTASURV.git` remote from the planned dedicated `certahealth.git` target | Keep `docs/GIT_SITUATION.md` current before cutover |
| `npm` missing from PATH | Node web tooling may be limited outside bundled Codex Node | Install Node.js LTS when the machine is not under production load |

## Operating Rule

Production mode stays on by default. TBC, Trimble, the dashboard, CAD standards, and project handoff paths are protected first. Throttling is only for TBC heat/critical system management, not the normal mode.
