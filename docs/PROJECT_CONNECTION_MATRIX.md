# Certa Project Connection Matrix

Last updated: 2026-06-17 10:47 ET

This file is the working standard for making sure every active Certa/CertaSurv project has both outside connections and in-house production connections.

## Connection Lanes

| Lane | Purpose | Required Connection |
| --- | --- | --- |
| Outside source control | Publishable source handoff and PR/review workflow | Git remotes, GitHub account/tooling where needed |
| Outside operations drive | System-of-record folders, IDs, releases, and handoffs | `G:\Shared drives\CERTASTRUCT` is the canonical launch root, while the active `00_CERTASURV_COMMAND_CENTER` tree is still populated under `G:\Shared drives\CERTASURV_PROJECT DRIVE` |
| Outside phone/app operations | AppSheet and Google Sheets command center | Command-center workbook and registry IDs from `MACROTBC\command_center\command_center_manifest.json` |
| Outside automation | Google Apps Script Drive bootstrap and scraper | `AUTOMATIONS\share-drive-automation` package |
| In-house TBC production | Live TBC macros and worker services | `Trimble Business Center\MacroCommands3\CertaSurv` and Trimble services |
| In-house CAD standards | Templates, feature definitions, blocks, layers, symbols | ProgramData Trimble matrix and Feature Definition Manager |
| In-house local apps | Local web/dashboard/parcel/estimate tools | `CERTASURV_WEB_APP` plus local Python runtime |
| In-house coordination | Watchlists, nudges, drive staging helpers | `CERTARD` and `CERTAHEALTH` scripts |

## Project Matrix

| Project | Path | Outside Connections | In-House Connections | Current Status |
| --- | --- | --- | --- | --- |
| CERTAHEALTH | `C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH` | Public `CERTASURV.git` remote today; planned `certahealth.git` cutover still open | Laptop load manager, project provisioning scripts | Active control repo, remote naming still mismatched |
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | Shared-drive mount helpers and private Git remote present | Project watchlist, staging scripts | Active coordination repo |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | AppSheet, Google Drive, command-center manifest, and private Git remote present | TBC macros, CAD resources, installers, sync scripts | Active production integration repo |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | Google Apps Script, Drive API, test shared drive automation, and private Git remote present | Reproducible automation package | Active automation repo |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Shared-drive project data, estimate folders, and private Git remote present | Local Python app/dashboard tools | Active local app project on renamed workspace |
| Trimble Business Center macros | `C:\Users\SimpS\OneDrive\Documents\Trimble Business Center\MacroCommands3\CertaSurv` | Mirrors to shared drive through MACROTBC | Live TBC macro command folder | Present locally |
| Feature Definition Manager | `C:\Users\SimpS\OneDrive\Documents\Feature Definition Manager` | Should be staged to shared drive CAD standards | Feature definition and CAD resources | Present locally |
| TBC templates matrix | `C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE` | Should be staged to shared drive TBC templates | Local drafting/template matrix | Present locally |

## Current Gaps Found

| Gap | Impact | Fix Path |
| --- | --- | --- |
| Canonical vs legacy shared-drive naming is split | Launch notes can point operators to the wrong drive root even though both mounts exist locally | Use `CERTASTRUCT` as the canonical launch target, but document that the active `00_CERTASURV_COMMAND_CENTER` tree is still being read from `CERTASURV_PROJECT DRIVE` during this cutover |
| CERTAHEALTH remote still targets public `CERTASURV.git` | Control-repo cutover and naming clarity remain incomplete | Decide whether to retain the public control repo shape or move to the planned `certahealth.git` remote |
| GitHub CLI private visibility is still auth-dependent | Private workflow/artifact review cannot be confirmed from this checkout without valid `gh` auth | Re-authenticate `gh` before relying on private Actions or artifact checks |
| `npm` missing from PATH | Node web tooling may be limited outside bundled Codex Node | Install Node.js LTS when the machine is not under production load; the installer stalled during this pass |

## Operating Rule

Production mode stays on by default. TBC, Trimble, the dashboard, CAD standards, and project handoff paths are protected first. Throttling is only for TBC heat/critical system management, not the normal mode.

## Capability Alignment Notes

- AppSheet remains the field and phone-facing surface.
- Browser/local app surfaces remain the parcel, estimate, intake, deed plotting, processing, final platting, and admin oversight surfaces.
- Release notes and handoff docs should keep those capability boundaries explicit so launch operators do not route browser-only work into AppSheet or vice versa.
