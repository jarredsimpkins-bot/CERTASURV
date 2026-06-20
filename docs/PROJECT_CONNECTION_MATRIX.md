# Certa Project Connection Matrix

Last updated: 2026-06-20 08:42

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
| Courthouse research tooling | County records research, runbooks, parcel/deed prep, ortho/LiDAR-to-TBC workflow notes | `WV_COURTHOUSE_RESEARCHER` workspace and its eventual GitHub upstream |

## Project Matrix

| Project | Path | Outside Connections | In-House Connections | Current Status |
| --- | --- | --- | --- | --- |
| CERTAHEALTH | `C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH` | `origin` -> `https://github.com/jarredsimpkins-bot/CERTASURV.git`; planned dedicated target is `certahealth.git`, but unauthenticated visibility is unresolved | Laptop load manager, project provisioning scripts | Active local control repo; remote-target decision still open |
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | Shared-drive mount helpers; `origin` -> `https://github.com/jarredsimpkins-bot/certard.git` | Project watchlist, staging scripts | Active coordination repo |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | AppSheet, Google Drive, command-center manifest; `origin` -> `https://github.com/jarredsimpkins-bot/macrotbc.git` | TBC macros, CAD resources, installers, sync scripts | Active production integration repo |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | Google Apps Script, Drive API, test shared drive automation; `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-automations.git` | Reproducible automation package | Active automation repo |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Shared-drive project data and estimate folders; `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` | Local Python app/dashboard tools | Active local app project after workspace rename from `New project2` |
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | Upstream not confirmed from local status check; candidate private repo visibility is blocked without `gh` auth | Research runbooks, CertaSurv toolkit scripts, ortho/LiDAR-to-TBC basemap workflow notes | Active release blocker with uncommitted runbook/tooling changes |
| Trimble Business Center macros | `C:\Users\SimpS\OneDrive\Documents\Trimble Business Center\MacroCommands3\CertaSurv` | Mirrors to shared drive through MACROTBC | Live TBC macro command folder | Present locally |
| Feature Definition Manager | `C:\Users\SimpS\OneDrive\Documents\Feature Definition Manager` | Should be staged to shared drive CAD standards | Feature definition and CAD resources | Present locally |
| TBC templates matrix | `C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE` | Should be staged to shared drive TBC templates | Local drafting/template matrix | Present locally |

## Current Gaps Found

| Gap | Impact | Fix Path |
| --- | --- | --- |
| Shared drive mounted and staged | Outside system-of-record folders are now available locally | Latest stage log: `G:\Shared drives\CERTASURV_PROJECT DRIVE\00_CERTASURV_COMMAND_CENTER\08_REPORTS_EXPORTS\drive-stage-log-20260522-194113.txt` |
| CERTAHEALTH remote target is unresolved | Release notes and automation still need a final answer on whether the control repo stays on public `CERTASURV.git` or moves to `certahealth.git` | Decide the permanent GitHub destination before final launch cutover |
| GitHub CLI is installed but unauthenticated on this host | `gh`-driven release pushes and private workflow/log inspection are blocked until auth is restored | Run `gh auth login` with repo and workflow scopes |
| `npm` is available on disk but can be missing from PATH in some shells | Node web tooling may work inconsistently outside the explicit Node install path | Normalize host PATH or install/reinstall Node.js LTS when the machine is not under production load |
| Shared drive was not mounted during the June 20 local check | Local release verification cannot prove shared-drive handoff paths until `G:` is restored | Sign in/mount Google Drive Desktop, then rerun `Test-CertaProjectProvisioning.ps1 -Detailed` |
| MACROTBC release lane has uncommitted changes | TBC integration package is not yet stable enough to treat as the launch source of truth | Review, verify, commit, and push the intended `MACROTBC` release-lane changes |
| WV_COURTHOUSE_RESEARCHER lacks confirmed upstream in this pass | Courthouse research tooling cannot be cleanly pushed/reviewed until remote ownership is decided and auth visibility is restored | Confirm/create the GitHub repo, set `origin`, then commit and push the active runbook/tooling changes |

## Operating Rule

Production mode stays on by default. TBC, Trimble, the dashboard, CAD standards, and project handoff paths are protected first. Throttling is only for TBC heat/critical system management, not the normal mode.
