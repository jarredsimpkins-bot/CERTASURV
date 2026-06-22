# Certa Project Connection Matrix

Last updated: 2026-06-22 09:05

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
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | Shared-drive mount helpers; `origin` -> `https://github.com/jarredsimpkins-bot/certard.git` | Project watchlist, staging scripts | Active coordination repo; latest private workflow green |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | AppSheet, Google Drive, command-center manifest; `origin` -> `https://github.com/jarredsimpkins-bot/macrotbc.git` | TBC macros, CAD resources, installers, sync scripts | Active production integration repo; latest private workflow red |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | Google Apps Script, Drive API, test shared drive automation; `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-automations.git` | Reproducible automation package | Active automation repo |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Shared-drive project data and estimate folders; `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` | Local Python app/dashboard tools | Active local app project after workspace rename; needs fresh CI rerun after push |
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | Remote/upstream still needs owning-workspace confirmation | Courthouse/title research runbooks and evidence packages | Release blocker until remote and runbook evidence are verified |
| Trimble Business Center macros | `C:\Users\SimpS\OneDrive\Documents\Trimble Business Center\MacroCommands3\CertaSurv` | Mirrors to shared drive through MACROTBC | Live TBC macro command folder | Present locally |
| Feature Definition Manager | `C:\Users\SimpS\OneDrive\Documents\Feature Definition Manager` | Should be staged to shared drive CAD standards | Feature definition and CAD resources | Present locally |
| TBC templates matrix | `C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE` | Should be staged to shared drive TBC templates | Local drafting/template matrix | Present locally |

## Current Gaps Found

| Gap | Impact | Fix Path |
| --- | --- | --- |
| Shared drive is not mounted in this automation context | `G:\Shared drives\CERTASURV_PROJECT DRIVE` and command-center project folders cannot be verified locally during this pass | Sign into/mount Google Drive for Desktop before final shared-drive handoff verification |
| CERTAHEALTH remote target is unresolved | Release notes and automation still need a final answer on whether the control repo stays on public `CERTASURV.git` or moves to `certahealth.git` | Decide the permanent GitHub destination before final launch cutover |
| GitHub CLI is authenticated in this automation context | Private workflow/log inspection is available now; future hosts may still need auth restored | Use `gh auth status` before relying on private run data |
| `npm` is available on disk but can be missing from PATH in some shells | Node web tooling may work inconsistently outside the explicit Node install path | Normalize host PATH or install/reinstall Node.js LTS when the machine is not under production load |
| MACROTBC release evidence is not closed in this control repo | TBC/AppSheet/shared-drive readiness cannot be called launch-ready from control docs alone | Fix latest `macrotbc` workflow failures for folder-map artifacts and shared-config TBC control root |
| MACROTBC shared-drive config is missing locally | `Test-CertaProjectProvisioning.ps1 -Detailed` cannot verify `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json` | Restore or generate the owning-repo config before release handoff |
| WV_COURTHOUSE_RESEARCHER remote/readiness evidence is not closed here | Courthouse research packaging could launch without a reviewable remote/runbook trail | Verify owning workspace remote/upstream, runbook/install notes, and smoke-test or workflow signal |

## Operating Rule

Production mode stays on by default. TBC, Trimble, the dashboard, CAD standards, and project handoff paths are protected first. Throttling is only for TBC heat/critical system management, not the normal mode.
