# Certa Project Connection Matrix

Last updated: 2026-06-16 22:45

This file is the working standard for making sure every active Certa/CertaSurv project has both outside connections and in-house production connections.

## Connection Lanes

| Lane | Purpose | Required Connection |
| --- | --- | --- |
| Outside source control | Publishable source handoff and PR/review workflow | Git remotes, GitHub account/tooling where needed |
| Outside operations drive | System-of-record folders, IDs, releases, and handoffs | `G:\Shared drives\CERTASTRUCT` primary, `G:\Shared drives\CERTASURV_PROJECT DRIVE` transitional command-center root |
| Outside phone/app operations | AppSheet and Google Sheets command center | Command-center workbook and registry IDs from `MACROTBC\command_center\command_center_manifest.json` |
| Outside automation | Google Apps Script Drive bootstrap and scraper | `AUTOMATIONS\share-drive-automation` package |
| In-house TBC production | Live TBC macros and worker services | `Trimble Business Center\MacroCommands3\CertaSurv` and Trimble services |
| In-house CAD standards | Templates, feature definitions, blocks, layers, symbols | ProgramData Trimble matrix and Feature Definition Manager |
| In-house local apps | Local web/dashboard/parcel/estimate tools | `CERTASURV_WEB_APP` plus local Python runtime |
| In-house coordination | Watchlists, nudges, drive staging helpers | `CERTARD` and `CERTAHEALTH` scripts |

## Project Matrix

| Project | Path | Outside Connections | In-House Connections | Current Status |
| --- | --- | --- | --- | --- |
| CERTAHEALTH | `C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH` | Needs Git remote if this becomes a publishable ops repo | Laptop load manager, project provisioning scripts | Active local control repo |
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | Shared-drive mount helpers; needs Git remote | Project watchlist, staging scripts | Active coordination repo |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | AppSheet, Google Drive, command-center manifest; needs Git remote | TBC macros, CAD resources, installers, sync scripts | Active production integration repo |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | Google Apps Script, Drive API, test shared drive automation; needs Git remote | Reproducible automation package | Active automation repo |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Shared-drive project data and estimate folders; remote already points to `certasurv-web-app` | Local Python app/dashboard tools | Active local app project |
| Trimble Business Center macros | `C:\Users\SimpS\OneDrive\Documents\Trimble Business Center\MacroCommands3\CertaSurv` | Mirrors to shared drive through MACROTBC | Live TBC macro command folder | Present locally |
| Feature Definition Manager | `C:\Users\SimpS\OneDrive\Documents\Feature Definition Manager` | Should be staged to shared drive CAD standards | Feature definition and CAD resources | Present locally |
| TBC templates matrix | `C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE` | Should be staged to shared drive TBC templates | Local drafting/template matrix | Present locally |

## Current Gaps Found

| Gap | Impact | Fix Path |
| --- | --- | --- |
| Shared drive rename is only partially migrated | `G:\Shared drives\CERTASTRUCT` exists, but the live command-center and project folders still live under `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Keep release runbooks and staging scripts dual-root aware until the command-center tree is copied or renamed |
| Web app workspace rename drift | Repo automation still referenced `New project2`, but the live workspace is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Align scripts and handoff docs to `CERTASURV_WEB_APP`, leaving the GitHub slug as `certasurv-web-app` |
| GitHub CLI is installed but this workstation is not signed in to `gh` | Connector-free GitHub Actions log triage and push automation are limited until login is restored | Use browser-visible public Actions data for `CERTASURV`; run `gh auth login` before relying on CLI log inspection or authenticated pushes |
| `npm` missing from PATH | Node web tooling may be limited outside bundled Codex Node | Install Node.js LTS when the machine is not under production load; the installer stalled during this pass |

## Operating Rule

Production mode stays on by default. TBC, Trimble, the dashboard, CAD standards, and project handoff paths are protected first. Throttling is only for TBC heat/critical system management, not the normal mode.
