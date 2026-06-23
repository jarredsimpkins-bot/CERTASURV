# Certa Project Connection Matrix

Last updated: 2026-06-23 14:45 ET

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
| CERTARD | `C:\Users\SimpS\OneDrive\Documents\CERTARD` | `origin` -> `https://github.com/jarredsimpkins-bot/certard.git`; shared-drive mount helpers | Project watchlist, staging scripts | Active coordination repo; mostly push/review timing after local dirty-file review |
| MACROTBC | `C:\Users\SimpS\OneDrive\Documents\MACROTBC` | AppSheet, Google Drive, command-center manifest; `origin` -> `https://github.com/jarredsimpkins-bot/macrotbc.git` | TBC macros, CAD resources, installers, sync scripts | Active production integration repo; substantive release blocker until readiness is green |
| AUTOMATIONS | `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS` | Google Apps Script, Drive API, test shared drive automation; `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-automations.git` | Reproducible automation package | Active automation repo |
| CERTASURV_WEB_APP | `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Shared-drive project data and estimate folders; `origin` -> `https://github.com/jarredsimpkins-bot/certasurv-web-app.git` | Local Python app/dashboard tools | Active local app project after workspace rename from `New project2` |
| WV_COURTHOUSE_RESEARCHER | `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER` | No accessible `origin` confirmed during the June 23 release-ops pass; `jarredsimpkins-bot/wv-courthouse-researcher` was not accessible through `gh repo view` | Courthouse/title research tooling and assessor prep docs | Substantive release blocker until upstream and review path are fixed |
| Trimble Business Center macros | `C:\Users\SimpS\OneDrive\Documents\Trimble Business Center\MacroCommands3\CertaSurv` | Mirrors to shared drive through MACROTBC | Live TBC macro command folder | Present locally |
| Feature Definition Manager | `C:\Users\SimpS\OneDrive\Documents\Feature Definition Manager` | Should be staged to shared drive CAD standards | Feature definition and CAD resources | Present locally |
| TBC templates matrix | `C:\ProgramData\Trimble\CONVERSE_FULL_DRAFTING_MATRIX_FROM_PAPERSPACE` | Should be staged to shared drive TBC templates | Local drafting/template matrix | Present locally |

## Current Gaps Found

| Gap | Impact | Fix Path |
| --- | --- | --- |
| Shared drive mount missing in this session | Outside system-of-record folders cannot be staged or verified locally until Google Drive Desktop exposes `G:` again | Restore `G:\Shared drives\CERTASURV_PROJECT DRIVE` before release handoff copies |
| CERTAHEALTH remote target is unresolved | Release notes and automation still need a final answer on whether the control repo stays on public `CERTASURV.git` or moves to `certahealth.git` | Decide the permanent GitHub destination before final launch cutover |
| GitHub CLI is authenticated on this host but lacks `workflow` scope | `gh`-driven private repo inspection is available, but workflow-file pushes from automation are blocked until re-auth | Re-run `gh auth status` before push/release operations and add `workflow` scope before `.github/workflows` edits |
| MACROTBC workflow readiness is failing | TBC macro/package release cannot be treated as launch-ready while readiness is red | Fix failing MACROTBC runs before package handoff |
| WV_COURTHOUSE_RESEARCHER has no accessible upstream | WV courthouse/research execution cannot be pushed or reviewed through the normal launch lane | Configure a GitHub remote or document the intended upstream |
| `npm` is available on disk but can be missing from PATH in some shells | Node web tooling may work inconsistently outside the explicit Node install path | Normalize host PATH or install/reinstall Node.js LTS when the machine is not under production load |

## Operating Rule

Production mode stays on by default. TBC, Trimble, the dashboard, CAD standards, and project handoff paths are protected first. Throttling is only for TBC heat/critical system management, not the normal mode.
