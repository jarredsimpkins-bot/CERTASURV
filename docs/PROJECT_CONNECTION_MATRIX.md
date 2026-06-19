# Certa Project Connection Matrix

Last updated: 2026-06-19 00:45 EDT

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
| In-house local apps | Local web/dashboard/parcel/estimate tools | `CERTASURV_WEB_APP`, `WV_COURTHOUSE_RESEARCHER`, and local Python runtime |
| In-house coordination | Watchlists, nudges, drive staging helpers | `CERTARD` and `CERTAHEALTH` scripts |

## Project Matrix

| Project | Path | Outside Connections | In-House Connections | Current Status |
| --- | --- | --- | --- | --- |
| CERTAHEALTH | `C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH` | `origin` -> `https://github.com/jarredsimpkins-bot/CERTASURV.git`; planned dedicated repo exists as `certahealth.git` | Laptop load manager, project provisioning scripts | Active local control repo; remote-target decision still open |
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | `origin` -> `https://github.com/jarredsimpkins-bot/certard.git`; shared-drive mount helpers | Project watchlist, staging scripts | Active coordination repo; current local check found one modified doc |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | AppSheet, Google Drive, command-center manifest; `origin` -> `https://github.com/jarredsimpkins-bot/macrotbc.git` | TBC macros, CAD resources, installers, sync scripts | Active production integration repo with substantive local edits |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | Google Apps Script, Drive API, test shared drive automation; `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-automations.git` | Reproducible automation package | Active automation repo |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Shared-drive project data and estimate folders; `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` | Local Python app/dashboard tools | Active local app project; clean in current local check |
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | No `origin` configured yet | Local courthouse research, prep toolkit, and basemap workflow assets | Active local app/toolkit repo; local-only and currently dirty |
| Trimble Business Center macros | `C:\Users\SimpS\OneDrive\Documents\Trimble Business Center\MacroCommands3\CertaSurv` | Mirrors to shared drive through MACROTBC | Live TBC macro command folder | Present locally |
| Feature Definition Manager | `C:\Users\SimpS\OneDrive\Documents\Feature Definition Manager` | Should be staged to shared drive CAD standards | Feature definition and CAD resources | Present locally |
| TBC templates matrix | `C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE` | Should be staged to shared drive TBC templates | Local drafting/template matrix | Present locally |

## Current Gaps Found

| Gap | Impact | Fix Path |
| --- | --- | --- |
| Shared drive mounted and staged | Outside system-of-record folders are available locally | Stage helpers and deployment references were re-verified read-only on June 19, 2026 |
| CERTAHEALTH remote target is unresolved | Release notes and automation still need a final answer on whether the control repo stays on public `CERTASURV.git` or moves to `certahealth.git` | Decide the permanent GitHub destination before final launch cutover |
| GitHub CLI is installed but unauthenticated on this host | `gh`-driven private workflow/log inspection is blocked until auth is restored | Run `gh auth login` with repo and workflow scopes |
| `node` and `npm` are missing from `PATH` on this machine | Node-based web tooling remains inconsistent from normal shells | Normalize host `PATH` or install/reinstall Node.js LTS when the machine is not under production load |
| `MACROTBC` is still dirty locally | TBC integration lane should not be treated as release-ready yet | Triage and land the active edits in `MACROTBC` intentionally |
| `WV_COURTHOUSE_RESEARCHER` is still local-only | WV toolkit changes cannot be pushed or reviewed remotely yet | Create the GitHub repo if needed, then run `Set-CertaGitRemotes.ps1 -Apply` or set `origin` manually |

## Operating Rule

Production mode stays on by default. TBC, Trimble, the dashboard, CAD standards, and project handoff paths are protected first. Throttling is only for TBC heat or critical system management, not the normal mode.
