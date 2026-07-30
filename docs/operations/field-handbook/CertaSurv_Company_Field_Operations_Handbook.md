# CertaSurv Company Field Operations Handbook

Draft date: 2026-07-29
Status: Working company handbook draft

## 1. Purpose

This handbook turns the current CertaSurv field, office, AppSheet, Google Forms, Operations Hub, Drive, email, and text-message direction into one operating standard.

It is written for:

- office/admin staff preparing field direction;
- crew leads using AppSheet, Trimble Access, Android tools, and Drive;
- drafters and reviewers receiving field returns;
- owners/managers deciding when field evidence is good enough to move forward.

The goal is simple: the company should not depend on private texts, memory, or one person's phone to carry survey intent.

## 2. Source Of Truth Rules

1. The Operations Hub is the source of truth for job status, field direction, daily logs, tasks, file registry, generated documents, job events, and review status.
2. AppSheet is the field/mobile/offline surface. It owns field direction consumption, daily log entry, uploads, checkpoints, photos, signoffs, stop-work escalation, and field-office status writeback.
3. Browser apps are office/admin surfaces. They own parcel research, intake, estimating, deed plotting, returned-field processing, final platting, QA/QC, and owner dashboards.
4. Google Forms are structured intake and submission surfaces feeding the Operations Hub. They do not become separate truth stores.
5. Drive stores source files and generated outputs. Drive files, PDFs, KMLs, DXFs, workbooks, Google Docs, photos, and deliverables must be linked back to Hub rows.
6. Generated outputs register to `Generated_Documents`, `File_Registry`, or the appropriate file/attachment table. A generated PDF, KML, workbook, or drawing is evidence/output, not the authority row.
7. CSD Project ID is the permanent job key. SSD, WKS, client job numbers, addresses, and project names are aliases.
8. No crew dispatch without a field direction record.
9. No field day closes without a daily log.
10. Text, email, Google Chat, phone, and marked-up-file instructions must be captured in a job row with exact wording and clean action. They cannot remain only in SMS or someone's inbox.

## 3. Roles And Ownership

| Role | Owns | Does Not Own |
| --- | --- | --- |
| Owner / Survey Manager / Reviewer | Control transforms, monument action approval, scope expansion, release approval, final survey judgment | Raw field capture by memory only |
| Office / PM | Field direction, schedule, project setup, Drive folder, client coordination, office triage | Changing field facts after the fact |
| Crew Lead | AppSheet assignment review, field work, photos, uploads, checkpoints, daily log, stop-work alerts | TBC processing, legal boundary judgment, final deliverable release |
| Drafter / Reviewer | Field-return review, drafting questions, mapping needs, plat corrections, QA status | Unrecorded text-only decisions |
| TBC Operator | TBC, GNSS, OPUS, feature-code processing, coordinate files, native JOB handling | Survey manager approval |
| Automation / SERVER1 | Watch approved Drive/AppSheet inputs, hash arrivals, create tasks/events, notify users | Survey judgment, GNSS processing, TBC transformation |

## 4. Workflow Surface Split

### AppSheet Field Workflows

Keep these in AppSheet because they happen on a phone, tablet, or offline field surface:

- field package handoff;
- crew work order and field direction review;
- field daily log completion;
- field blocker and stop-work escalation;
- field uploads;
- checkpoints;
- photos;
- signoffs;
- quick status writeback.

### Browser Office Workflows

Keep these in browser/office tools:

- parcel information and source evidence;
- customer/internal intake;
- estimating;
- deed plot workflow;
- courthouse/research continuity;
- returned-field-work processing;
- final platting and QA/QC;
- job standing dashboard and owner oversight.

### Shared Rows

Both field and office tools must respect these shared tables:

- `Projects` / `Jobs`
- `Job_Tasks`
- `Job_Events`
- `Generated_Documents`
- `File_Registry`
- `Customer_Intake_Responses`
- `Internal_Intake_Responses`
- `Estimate_Requests`
- `Estimates`
- `Field_Assignments`
- `Crew_Work_Orders`
- `Field_Workflow_Tasks`
- `Field_Daily_Log`
- `Field_Checkpoints`
- `Field_Photo_Log`
- `Field_Signoffs`
- `Field_Required_Files`
- `Drafting_Questions`
- `Mapping_Needs`
- `Plat_Review_Log`
- `Research_Work`
- `Job_Attachments`

## 5. Field Direction Standard

A field direction is the daily marching order. It must tell the crew what job they are working, where to go, what to do, what evidence to collect, what files to use, what hazards exist, and when to stop or call the office.

### Required Field Direction Data

- Work Order ID
- CSD Project ID
- Work Date
- Crew Lead
- Crew Members
- Project Name
- Client Job #
- County / Location
- Site Address
- Site Contact / Phone
- Phase / Target
- Survey Service Type / Products
- Priority
- Priority Reason
- Client / Recordation Deadline
- Scheduled Start
- Scheduled End
- Crew / Rig
- Data Collector / File Set
- Drive Folder URL
- Source Package Status
- Required CAD / Deliverable Format And Version
- Scope Today / Objective
- Required Shots / Evidence
- Documents To Carry
- Access / Parking / Hazards
- Safety / PPE Notes
- Boundary / Control Notes
- Deliverables Expected Today
- Office Questions Before Leaving
- Return Trip Risk
- Approved By
- Calendar Event URL
- Office Internal Notes

### Phase / Target Codes

- Initial Field
- Additional Field
- Final Field
- Stakeout
- Flood Cert
- Pickup
- Revisit

### Priority Codes

- Normal
- High
- Rush
- Hold Until Confirmed

Use `Hold Until Confirmed` when the crew should not leave until office, scope, access, file, or control questions are resolved.

### Crew / Rig Codes

- Truck 1
- Truck 2
- Rover
- Robot
- Drone
- Level

Daily log equipment may also include:

- Truck
- ATV
- Chainsaw

### Documents To Carry

- Deeds
- Prior Plat
- Tax Map
- Estimate Scope
- Work Order
- Flood Packet
- Adjoiner Deeds

### Deliverables Expected Today

- Raw collector file
- Photos
- Control report
- Sketch
- Return-trip notes
- Completed field status

### Good Field Direction Pattern

Use this structure:

```text
Today do [specific action] at [specific location].
Collect [specific evidence/photos/files].
Use [specific control/files/records].
Do not proceed if [stop condition].
Upload to [Drive folder].
Handoff note must answer [office/drafting question].
```

Bad direction:

```text
Survey property.
```

Good direction:

```text
Recover and verify the F10-F27 perimeter points on the 18.462-acre tract.
Use the current R2 KML and field packet.
Photograph every found/set point and note missing or disturbed monuments.
Heavily flag recovered points.
Stop if control does not match the packet.
```

## 6. Ed / Field-Office Direction Capture Standard

Ed's instructions often arrive through text, email, call, Google Chat, or marked-up drawings. Some are field orders. Some are office drafting/review decisions. Some are questions. Every one needs the same capture pattern so intent survives.

### Required Direction Capture Fields

- Direction Callout
- Intent Source
- Received Timestamp
- Exact Direction Received
- Clean Action Statement
- HELP / Survey Reasoning
- Target File / Attachment
- Requested File Format / Version
- Priority / Deadline
- Capacity Confirmation
- Supersedes Direction ID / Superseded By
- Field Owner
- Office Owner
- Verification Needed
- Destination Row

### Direction Callout Codes

| Code | Meaning |
| --- | --- |
| FIELD | Crew action, field visit, field evidence, monument work |
| OFFICE | Office/drafting/research action |
| VERIFY | Confirm before relying on it |
| CHANGE | Drawing, linework, label, note, plat, or scope change |
| EVIDENCE | Photo, record, monument, utility, or stakeholder proof needed |
| HELP | Survey reasoning, boundary logic, or why the direction matters |
| QUESTION | Needs answer before action can be final |
| DECISION | Surveyor/owner decision or approval state |
| DELIVER | Client/surveyor deliverable action |

### Intent Source Codes

- Ed
- Jarred
- John
- Crew
- Client
- Email
- SMS Capture
- Google Chat
- Phone Call
- Attachment
- Field Note
- Office Review

### Verification Needed Codes

- Field Evidence
- Courthouse Research
- Deed Check
- Plat Check
- Utility Confirmation
- Surveyor Review
- Client Approval
- None

### Destination Row Codes

- `Crew_Work_Orders`
- `Field_Daily_Log`
- `Research_Work`
- `Estimate_Requests`
- `Estimates`
- `Drafting_Questions`
- `Mapping_Needs`
- `Plat_Review_Log`
- `Job_Events`
- `Job_Attachments`
- `File_Registry`
- `Generated_Documents`

### Routing Rule

- Field execution direction goes to `Crew_Work_Orders`.
- What the crew did, found, could not find, photographed, uploaded, or marked goes to `Field_Daily_Log`.
- Title reports, title commitments, deeds, scans, prior plats, assessor/GIS material, and research gaps go to `Research_Work` plus `Job_Attachments` or `File_Registry`.
- Pricing requests, deadline feasibility, and service/product changes go to `Estimate_Requests` or `Estimates` before the company commits.
- Boundary reasoning, adjoiner questions, ROW logic, research gaps, and drafting/mapping questions go to `Drafting_Questions`, `Mapping_Needs`, or `Job_Events`.
- Plat corrections, redlines, seal/title block notes, color/monochrome delivery, and final approval status go to `Plat_Review_Log`.
- Deliverable files and source attachments go to Drive plus `File_Registry` or `Generated_Documents`.

### Ed Direction Examples To Preserve

- Recover or replace pins; heavily flag points when client/logger visibility matters.
- State whether the service is pin recovery only, a partial resurvey, a complete survey, an ALTA survey, or a parcel split/combination; do not let the attachments imply the scope.
- For a complete survey, state the promised products explicitly, such as all corners marked, plat, and legal description.
- When parcels are combined and a remainder is retained, identify both resulting areas and the pin/plat/legal product required for each.
- If a pins-only request becomes a parcel combination, add the required plat and revise scope and price before work proceeds.
- Create the project drawing file and appropriate folders, then attach or link the available title reports, title commitments, deeds, scans, and prior plats.
- Put an urgent project push, client deadline, or recordation deadline in structured priority fields and confirm crew capacity before promising it.
- Establish control before measuring or checking a wall or similar feature.
- Get drone shots when they remain part of the field evidence.
- Hold common-line pins where adopted by survey decision.
- Go deed distance from a found controlling pipe when directed.
- Capture client comments, neighbor reactions, and who built or claims a fence when those facts affect boundary review.
- Do not state an assumed ROW width when evidence is conflicting.
- Depict ROW graphically when the width is uncertain or better shown than stated.
- Cite the source of each shown ROW when known; route a missing deed book/page or other source reference as a drafting/research question.
- Note an apparent driveway encroachment or other material exception for surveyor review instead of silently drawing through it.
- Note a set pin deviation instead of hiding it.
- Do not publish a drawing after an uncertain datum adjustment; verify the control/datum relationship and obtain review.
- Show a well only if there is no city water and the well is actually confirmed.
- Do not label suspected utilities, wells, pole lines, datum, or monuments as certain without evidence.
- Add arrows, bearings, distances, linework, road labels, references, seal, and title/text corrections when review markup says so.
- Record the requested DWG or other deliverable version, and deliver that exact version with the revision receipt.
- Send color and monochrome deliverables when requested.
- Hold recordation or final delivery until the stated review condition is satisfied.

### Direction Supersession Rule

Email corrections must remain auditable. If a sender corrects a value, format, date, scope, or priority:

1. Preserve both exact messages with their timestamps.
2. Mark the earlier direction `Superseded`; do not delete or silently overwrite it.
3. Link the new direction to the earlier Direction ID.
4. Restate the controlling action in plain language.
5. Confirm any high-risk correction involving coordinates, datum, parcel identity, monument action, or release status.

Example: when an initial conversion request says `20000` and a follow-up minutes later says `2000 DWG`, the clean action is `Return the drawing in AutoCAD 2000 DWG format`; the first text remains attached as superseded evidence.

### Scope, Research, And Capacity Rule

- A forwarded attachment is source material, not a complete work order.
- Office intake must translate the email into service type, parcels/areas, products, deadline, priority, and owner.
- Research files must be organized in the project folder and linked to the job before field or drafting handoff.
- If research is still incomplete, record what is present, what is missing, who owns the gap, and whether the crew may proceed.
- The person accepting a deadline must check actual field capacity. When crews are overextended, the manager may shift available staff to field work and cover drafting or courthouse research in the office, but the ownership change must be recorded.

### Text-Message Rule

If Ed, John, Jarred, a crew member, or a client sends job direction by SMS:

1. Capture the exact text into the job's direction bundle.
2. Attach or link the screenshot/export if useful.
3. Translate the text into a clean action.
4. Add the survey reasoning if the instruction changes field or office judgment.
5. Route it to the correct Hub row.
6. Do not leave SMS as the only record.

If a full SMS archive is too large to parse, create a smaller Ed-only or job-specific export without media and attach that export to the job.

## 7. Daily Field Log Standard

A daily log is the proof-of-work and handoff record. It is required every field day, even if no progress was made.

### Required Daily Log Fields

- Daily Log ID
- CSD Project ID
- Work Date
- Crew Lead
- Project Name
- Phase Worked
- Weather / Conditions
- Start Time
- End Time
- Hours
- Mileage
- Data Collector / File Set
- Work Performed
- Evidence Collected
- Photos Taken?
- Files Uploaded?
- Scope Change Needed?
- Return Trip Needed?
- Field Stage Updated
- Field Stage Status
- Field Stage Points
- Notes for Drafting
- Submitted By
- Processed?

### Weather / Conditions Codes

- Clear
- Rain
- Wet
- Snow/Ice
- Heavy Brush
- Steep
- Limited Access
- Unsafe

### Evidence Collected Codes

- Monument photos
- GPS shots
- Control ties
- Fence/occupation notes
- Driveway/encroachment shots
- Water features
- Benchmark shots
- Sketch

### Files Uploaded Codes

- Yes
- Partial
- No - connection issue
- No - missing folder
- No - needs office help

If files are `Partial` or `No`, office follow-up is required before drafting treats the field return as complete.

### Scope Change Needed Codes

- No
- Maybe
- Yes - quote review needed
- Yes - owner requested extra work

### Return Trip Needed Codes

- No
- Maybe
- Yes - field incomplete
- Yes - weather/access
- Yes - office/drafting requested

### Field Stage Updated Codes

- Research
- Initial Field
- Additional Field
- Final Field
- Flood Cert Field
- Stakeout
- Field Complete

### Field Stage Status Codes

- Started
- In Progress
- Complete
- Blocked

### Field Stage Points

- 0 = blank/no progress
- 1 = Started
- 5 = In Progress
- 10 = Complete

Choose `Complete` only when drafting has what it needs from field.

### Next Action Status Codes

- Open
- Waiting on Office
- Waiting on Client
- Scheduled
- Complete

### Office Review Status Codes

- Needs Review
- Approved For Drafting
- Needs Field Follow-Up
- Needs Upload Fix
- Closed

## 8. Field Work Sequence

The crew workflow follows this sequence.

| Step | Name | Required Action | Stop / Gate |
| --- | --- | --- | --- |
| 1 | Overview | Open assignment, review job, address, crew, scope, dates, progress, required files, missing uploads, and signoff readiness | No selected assignment or missing required files means call office |
| 2 | Checkpoints | Capture start mileage entry/photo, control check-in photo, control check-out photo | Missing checkpoint blocks signoff |
| 3 | Required Uploads | Upload required files to the correct folder target | Missing required upload blocks signoff |
| 4 | Map / KML | Open project-only map/KML and use assigned F/S point lists | Wrong KML or unrelated map data means stop and flag office |
| 5 | Task Workflow | Complete ordered workflow tasks and decision branches | Blocking task or office-review branch blocks signoff |
| 6 | Point Photos | Select assignment-limited point, take photo, capture timestamp/location | Point not in dropdown means it is not in this assignment's stakeout file |
| 7 | Sign + Generate Daily Log | Sign once readiness checks pass | Cannot sign until uploads, workflow, checkpoints, and photos are complete |
| 8 | Office Handoff | Office reviews generated log, exceptions, generated docs, and unresolved blockers | Office review required if branch/blocker remains |

Detailed task order:

1. Overview
2. Start Mileage
3. Required Files
4. Map / KML
5. Arrive / Control
6. Control Check-In
7. Stakeout / Search
8. Set / Stake Points, when applicable
9. Photos
10. Decision
11. Raw Upload
12. Control Check-Out
13. Daily Log
14. Complete
15. Stop / Office Review, when triggered

## 9. Required Files And Closeout Gates

These items block field closeout when required and missing:

| Category | Required File / Evidence | Why Needed |
| --- | --- | --- |
| Packet | Field direction / crew instructions | Crew needs scope, access, safety, and task order before mobilizing |
| Research | Title report/commitment, deed/source packet, prior plat, assessor/GIS material | Crew and drafting need current-record, parcel, adjoiner, and exception context |
| Map | Project-only map pin | Crew should not see every company job on the map |
| Stakeout | Stakeout KML / point file | Drives F-number dropdown and point photo names |
| Control | Current control file | Crew must know current control before measuring/searching |
| Photos | Point-numbered photos | Photos must tie to F/S points with timestamp and GPS metadata |
| Raw Data | T02/raw field files | Drafting needs raw collector export before office work starts |
| Closeout | Daily field log / drafting handoff | Office needs a clear record of what happened and what remains |
| Stakeout | Set/stake KML / S point file | Drives S-point dropdown and set-point photo names |
| Checkpoint | Starting mileage photo + manual entry | Supports mileage and job costing |
| Checkpoint | Control check-in photo | Confirms control at start of field work |
| Checkpoint | Control check-out photo | Confirms control at end of field work |

### Research Package Before Dispatch Or Drafting

The office must create or confirm the project drawing container and standard folders, then register the available research material:

- title report or title commitment;
- current and source deeds;
- prior plats and survey references;
- assessor/GIS parcel material;
- scans, sketches, and client exhibits;
- source email and attachment receipt;
- known gaps and assigned research owner.

Title documents are research inputs, not proof that every exception or parcel question has been resolved. The job row must show whether the package is `Complete`, `Partial - Field May Proceed`, `Partial - Office Only`, or `Blocked`.

Do not issue a field or drafting package whose parcel list, scope, or promised products exist only in the email body.

## 10. Stop-Work Standard

Stop work is not failure. It is how the crew protects safety, data quality, scope, and survey judgment.

### Stop-Work Codes

- Stop Work - Access
- Stop Work - Hazard
- Stop Work - Control Mismatch
- Stop Work - Scope Request
- Stop Work - Client/Neighbor Dispute
- Stop Work - Data Collector Issue

### Required Stop-Work Fields

- CSD Project ID
- Work Order ID
- Crew Lead
- Issue Type
- Blocker Severity
- Immediate Action Taken
- Safe To Continue?
- Office Escalation Owner
- Target Resolution Date
- Attachment / Upload Link
- Stop Work Summary

### Stop-Work Responses

| Trigger | Required Response |
| --- | --- |
| Access blocked or unsafe | Stop, add issue photo/notes, notify office, resolve access before return |
| Hazard | Stop, document safety issue, owner/admin reviews before crew returns |
| Control mismatch | Stop, photograph/check control, drafting/research resolves basis before continuing |
| Scope request | Create scope review; distinguish pin-only, partial resurvey, complete survey, ALTA, split/combination, plat, and legal products; do not perform extra work until owner/office approval |
| Client/neighbor dispute | Stop or pause as needed; office decides contact/pause/continue path |
| Data collector issue | Preserve raw files, document issue, office verifies data before drafting starts |

### Troubleshooting Signals

- `Files Uploaded? = Partial/No`: office contacts crew, confirms local files, sets upload follow-up due today.
- `Return Trip Needed? = Maybe/Yes`: office decides whether to schedule a return now or wait for drafting review.
- `Scope Change Needed? = Maybe/Yes`: office pauses extra work until approved unless safety/completion requires immediate action.
- `Field Stage Status = Blocked`: office reviews same day and either re-dispatches, asks drafting, or contacts client.
- `Notes for Drafting` present: drafting reads before opening data files.
- `Photos Taken? = No`: office decides whether photos are required before drafting continues.
- `Daily log date has no work order`: office links log to work order or creates missing work order retroactively.

## 11. Stakeout And Field Package Standard

### Drive Lane

Every project uses:

```text
03_FIELD_WORK/09_STAKEOUT_FILE
```

This is the crew-ready stakeout drop. Do not create alternate random folders such as extra stakeout, export, field files, map files, or attachment folders when this lane already exists.

### First-Pass Package Contents

- Native Trimble Access JOB, when available
- Search/find point CSV
- Project or location KML
- Field linework DXF
- README or crew instruction note
- Source plat/PDF used for preliminary layout

### Locked-Format Additions

Before AppSheet field assignment is treated as issued, the package should carry or reference:

- Production FXL
- TBC template or exact template reference
- Layer/style manifest
- Point-style manifest
- SearchMap / label-style settings
- Export receipt
- Deed/current-record proof or link
- Assignment ID / AppSheet promotion receipt

### Native JOB Rule

- The office `.vce` remains the editable master.
- The native Trimble Access `.job` is the revision-stamped field edition.
- Do not regenerate a JOB from JXL when the native JOB exists.
- JXL, CSV, DXF, KML, and other derivatives do not replace the native field record.
- A single native `.job` can be the crew drop only when it contains approved job settings, coordinate system, points, feature coding, and no external dependencies.
- When the job references DXF, KML, imagery, surfaces, geoids, or other linked files, issue one ZIP containing the native JOB, dependencies, pinned FXL/reference, and a short hash/revision manifest.

### Derivative Regeneration Rule

Generate the following from the same approved JOB/VCE revision:

- search/stakeout point exports;
- field linework DXF;
- project/find KML;
- preliminary workmaps;
- AppSheet point/task rows.

When TBC moves, rotates, recalculates, or transforms `PL`, every geometry-dependent derivative is stale until regenerated from the same revision.

## 12. F/S Point And Photo Standard

### F Points

`F` points are find/search/verify targets.

Examples:

- `F10`
- `F11`
- `F27`

F points drive find/search dropdowns and point photo names.

### S Points

`S` points are set/stake targets.

Examples:

- `S10`
- `S11`
- `S27`

S points drive set/stake dropdowns and set-point photo names.

### Source Point Preservation

When TBC/source point names are mapped into AppSheet:

- keep the AppSheet field namespace clean, such as `F10`;
- preserve the source point identifier, such as `P010`, in the description/audit note.

Example:

```text
Source P010 -> AppSheet F10
```

### Closing Coordinate Rule

A return-to-beginning coordinate is not automatically a second physical monument.

If the closing coordinate differs slightly from the beginning coordinate:

1. preserve both geometry coordinates;
2. record the closure gap;
3. create one physical field target unless manager review says otherwise;
4. require manager review before treating the closing vertex as distinct.

## 13. Field File Naming Rules

| Rule | Folder Path | Pattern | Example |
| --- | --- | --- | --- |
| Find KML | `03 Field/Stakeout` | `{ClientJob}_{CSD}_FIND_F.kml` | `SSD-11635_CSD-2026-0004_FIND_F.kml` |
| Set KML | `03 Field/Stakeout` | `{ClientJob}_{CSD}_SET_S.kml` | `SSD-11635_CSD-2026-0004_SET_S.kml` |
| Find Photo | `03 Field/Photos/Find` | `{CSD}_{PointID}_{timestamp}.jpg` | `CSD-2026-0004_F12_20260515_083011.jpg` |
| Set Photo | `03 Field/Photos/Set` | `{CSD}_{PointID}_{timestamp}.jpg` | `CSD-2026-0004_S12_20260515_103644.jpg` |
| Start Mileage | `03 Field/Photos/Odometer` | `{CSD}_START_MILEAGE_{timestamp}.jpg` | `CSD-2026-0004_START_MILEAGE_20260515_074455.jpg` |
| Control Check-In | `03 Field/Control Checks` | `{CSD}_CONTROL_CHECK_IN_{timestamp}.jpg` | `CSD-2026-0004_CONTROL_CHECK_IN_20260515_081530.jpg` |
| Control Check-Out | `03 Field/Control Checks` | `{CSD}_CONTROL_CHECK_OUT_{timestamp}.jpg` | `CSD-2026-0004_CONTROL_CHECK_OUT_20260515_164822.jpg` |

## 14. Feature Code Standard

Build the active field code list from observed field exports and actual crew usage, not from the legacy FXL alone. The legacy FXL is a parts library. CSV/JOB exports are usage evidence.

Keep the active list lean. Use aliases and notes for detail. Do not make a new button for every tree, post, monument phrase, deed call, or oddball description.

### Line Control Rule

Use B/E line logic:

```text
ER B
ER
ER
ER E
```

For parallel lines, allow numeric strings:

```text
ER1 B
ER1
ER1 E

ER2 B
ER2
ER2 E
```

Point numbers stay numeric only. Codes and descriptions stay in the code/description field.

### Active Line Codes

| Code | Meaning | Notes |
| --- | --- | --- |
| ER | Edge of road | Use B/E and numeric string suffixes |
| CL | Centerline generic | Aliases: `CL RD`, `CLRD` |
| CLR | Centerline road | May merge into `CL` after field review |
| FENCE | Fence line | Alias: `FNC`; keep B/E |
| BD | Building outline | Use `BD1 B`, `BD1`, `BD1 E` |
| DR | Drain / ditch / drainage | Aliases: `DRAIN`, `CL DRAIN` |
| DW | Driveway | Alias: `DRIVEWAY` |
| ROW | Right-of-way | Alias: `ROW RD` |
| CRK | Creek / stream bank | Alias: `CRK BANK` |
| PL | Property / boundary line | Boundary workflow |
| TOB | Top of bank | Alias: `TOP OF BANK` |
| TOR | Top of ridge | Aliases: `TOP OF RIDGE`, `RIDGETOP`, `RDGTOP` |
| PWR | Powerline | Alias: `POWERLINE` |

### Active Point Codes

| Code | Meaning | Notes |
| --- | --- | --- |
| CTRL | Control point | Alias: `TRV` |
| CHK | Check point | Alias: `CHECK` |
| BASE | Base setup/reference | Core control workflow |
| ACP | Adjusted/control point | Alias: `OPUS ADJUSTED` |
| RBF | Rebar found | Common monument |
| RBS | Rebar set | Aliases: `REBAR SET`, `SET CONVERSE REBAR` |
| IPF | Iron pipe found | Aliases: `1.5IPF`, `1.5 IPF` |
| IPS | Iron pipe set | Companion to IPF |
| MON | Uncommon monument catch-all | Put details after `*` |
| GMK | Gas marker | Alias: `GAS MARKER` |
| GV | Gas valve | Aliases: `GAS_VALVE`, `G GAS_VALVE` |
| PP | Power pole | Utility point |
| GATE | Gate / gate post | Alias: `GATE POST` |
| BLD | Building corner / point | Alias: `BLDG` |
| GND | Ground shot | Alias: `GRND` |
| TREE | Tree | Put species/size after `*` |
| STUMP | Stump | Vegetation |
| POST | Post / fence post | Alias: `FENCE POST` |
| FLAG | Flagged item | Alias: `FLAGG` |
| SET | Generic set item | Holding code only; prefer `RBS`, `IPS`, or `MON` |
| NOTE | Note-only observation | Use for deed/search prose |
| NS | Needs review | Holding code; meaning conflicts across exports |

### MON Rule

Use `MON` for uncommon monuments and put the real detail after `*`.

```text
MON *STONE 12X8
MON *AXLE
MON *CONC MON 4X4
MON *RAILROAD SPIKE
```

Common monuments stay dedicated:

```text
RBF
RBS
IPF
IPS
```

### Building Rule

Use `BLD` for point symbols:

```text
BLD *HOUSE CORNER
BLD *FOUNDATION CORNER
```

Use `BD` for connected building outline linework:

```text
BD1 B
BD1
BD1
BD1 E
```

### NOTE Rule

Use `NOTE` for deed-call prose, search notes, ambiguous descriptions, or nonstandard observations.

Do not promote these as Measure Codes buttons:

- `CALL`
- `TO`
- `WITH`
- `BEGINNING`
- `POINT`
- `WHITE`
- `BLACK`
- `HICKORY`
- `CHESTNUT`
- `IRON`
- `IN`
- `INCH`

Put those words in the note detail instead.

## 15. Field / Model / Office Truth Rule

Reviewer decisions create truth. Model outputs create candidates. Field crews create evidence. QA promotes deliverables.

Workflow:

```text
model_candidate
-> office_reviewed
-> needs_field_check
-> field_observed
-> field_verified / field_rejected
-> office_promoted
-> delivered
-> post_delivery_issue
-> training_example
```

### Required Capture For Corrections

- who corrected it;
- when corrected;
- source imagery/LiDAR used;
- field photo IDs;
- GNSS accuracy estimate;
- original model confidence;
- final reviewer decision;
- reason code;
- geometry before;
- geometry after.

### Candidate Point Rule

Amber/candidate points are questions, not final truth. Add photos and notes before changing status. Office review promotes, rejects, archives, or routes corrections to training.

## 16. Planimetric And Point Classes

### Operational Point Classes

| Point Class | Priority | Shape | Truth Status |
| --- | ---: | --- | --- |
| control | 1 | triangle | not deliverable truth |
| checkpoint | 1 | square | not deliverable truth |
| gcp | 1 | diamond | not deliverable truth |
| topo_observation | 3 | circle | not deliverable truth |
| landform_label | 4 | circle | not deliverable truth |
| lidar_qa_flag | 2 | hexagon | not deliverable truth |
| ortho_qa_flag | 2 | hexagon | not deliverable truth |
| ai_candidate | 4 | hollow_circle | not deliverable truth |
| field_task | 2 | flag | not deliverable truth |
| hazard | 1 | warning | not deliverable truth |
| access_gate | 2 | gate | not deliverable truth |
| photo_evidence | 3 | camera | not deliverable truth |

### Planimetric Feature Promotion Gates

| Feature | Theme | Geometry | Promotion Gate |
| --- | --- | --- | --- |
| building_footprint | structures | polygon | office_review_required |
| road_centerline | transportation | line | source_and_topology_review |
| edge_of_pavement | transportation | line | ortho_lidar_review |
| curb_line | transportation | line | field_or_high_res_review |
| sidewalk | transportation | line_or_polygon | office_review_required |
| rail | transportation | line | source_review |
| hydro_flowline | hydrography | line | hydro_connectivity_review |
| waterbody_edge | hydrography | polygon | vintage_and_season_review |
| ditch_swale | hydrography | line | lidar_and_field_review |
| bridge_culvert | structures | point_or_line | field_or_source_review |
| contour | elevation | line | surface_generation_qa |
| terrain_breakline | elevation | line | surface_qa_required |
| utility_asset | utilities | point | field_or_authoritative_source |
| vegetation_edge | land_cover | line_or_polygon | vintage_review |
| boundary_reference | boundaries | line_or_polygon | source_evidence_required |
| terrain_landform_label | landforms | point_or_line | reviewed_label |

## 17. Field Return And Background Processing

### Field-Return Lifecycle

1. `field-data-received`
2. `office-processing-started`
3. `temporary-field-adjustment-available`, when same-day provisional direction is necessary
4. `manager-review-required`
5. `processed-package-ready`
6. `field-acknowledged`

Every state must tie to:

- project;
- assignment;
- source filename;
- SHA-256;
- Drive folder;
- issue revision.

### Drive Watcher Boundary

The field-data Drive watcher detects files, preserves bytes, records receipts, and posts `field-data-received`.

It does not:

- open TBC;
- process GNSS;
- transform coordinates;
- evaluate control;
- interpret feature codes;
- regenerate KML/DXF;
- make survey judgment.

Production note: the watcher contract exists, but direct Drive drops are not automatic unless the supervised watcher is actually deployed with renewable authorization, loopback SERVER1, internal token, monitoring, and approved folder registry.

## 18. Drive And Folder Rules

### Required Drive Behavior

- Use Google Drive for Desktop with shared drives visible.
- Put operational project data, research packets, KML, field files, estimates, generated documents, dashboards, TBC packages, and reports in the shared drive.
- Keep machine-specific installs in local program folders.
- Keep source code in repos until intentionally packaged.
- Do not leave shared work products only on one workstation.

### Legacy CertaSurv Drive During Transition

Legacy lane:

```text
G:\Shared drives\CERTASURV_PROJECT DRIVE
```

Canonical production home is `CERTASTRUCT`, but the legacy CertaSurv shared drive remains usable during transition.

### Field/CAD Folder Classes

Field/cad/project data belongs under structured project folders, not random local folders. Field outputs should land in the appropriate field package, daily log, raw data, photos, KML, drafting, review, or deliverable lane and then be registered in Hub rows.

## 19. Office Review And Job Standing

True job standing requires more than a completed field visit. The dashboard or owner review must be able to report:

- intake completeness and missing-info status;
- estimate stage, sent/approved status, and estimator margin fields;
- research completeness and current deed/parcel blockers;
- field readiness, field completion, required uploads, checkpoints, and signoffs;
- drafting completion;
- open drafting questions and mapping needs;
- QA/QC issue count;
- redline closure percent;
- final deliverable readiness;
- deliverable draft/final status;
- days since last event;
- current owner;
- blocker reason;
- next action.

Field complete means field evidence is complete enough for office/drafting to continue. It does not mean the job is final.

### Plat And Deliverable Review Checklist

Before release, the reviewer must confirm:

- title block jurisdiction, client/prepared-for name, punctuation, and project identifiers are correct;
- deeds, plats, title material, and other references actually used are listed;
- every shown ROW has a known source or a clearly logged unresolved-source question; do not invent a width or deed reference;
- an approximate latitude/longitude near the dwelling and northing/easting at a principal corner are shown when requested and appropriate to the product;
- apparent driveway encroachments and other material exceptions are called out for surveyor disposition;
- fence ownership/construction statements, client comments, and neighbor reactions are treated as stakeholder evidence, not boundary proof;
- any found or set monument that differs from the adopted line is shown and noted, with the surveyor deciding whether it remains or is moved;
- parcel combinations, retained remainders, and products for each resulting area match the approved scope;
- the delivered CAD version, sheet size/scale, color/monochrome set, and release condition match the current direction.

### Priority And Capacity Review

An email phrase such as `BIG PUSH`, `must be done within a week`, or `later this week` is a priority signal, not a complete schedule commitment. The office must record the requested date, reason, responsible crew, capacity confirmation, and any work displaced. If capacity is not confirmed, the job remains `Priority Requested`, not `Scheduled`.

## 20. Training Standards

### Office Training

Office staff must be able to write a field direction in one minute using:

```text
Today do X at Y.
Collect Z.
Use A/B/C files.
Stop if W.
Upload to folder.
Tell drafting Q.
```

### Crew Training

Crew leads must know:

- daily log is mandatory;
- required files must be reviewed before mobilization;
- F points are find/search targets;
- S points are set/stake targets;
- point photos must be tied to the correct point;
- control check-in and check-out photos matter;
- no upload means office must know immediately;
- stop-work flags protect the job;
- notes for drafting are part of the work, not optional commentary.

### Review Training

Reviewers must check:

- exact source direction versus clean action;
- field evidence versus office assumption;
- stale KML/DXF/workmaps after geometry moves;
- whether control supports the conclusion;
- whether utilities/wells/ROWs/monuments are confirmed or only suspected;
- whether the client/surveyor deliverable is color, monochrome, both, held, or ready.

## 21. Minimum Go-Live / Production Test Checklist

Before treating the field workflow as production-ready:

- Field Direction appears on phone.
- Crew sees only assigned active jobs.
- Crew can open Drive folder from AppSheet.
- Required field direction fields block incomplete dispatch.
- Daily Log action is visible from work order.
- Daily log pre-fills project and crew fields.
- Start mileage, control check-in, and control check-out prompts work.
- Required uploads block closeout when missing.
- Point photo dropdown is assignment-limited.
- `Files Uploaded? = No` appears in Field Log Review.
- `Return Trip Needed? = Maybe/Yes` appears in Needs Field Follow-Up.
- `Scope Change Needed? = Maybe/Yes` creates or flags scope/estimate review.
- `Stop Work` flags notify office immediately.
- Drafting can see daily logs, photos, raw files, evidence, and notes by CSD Project ID.
- Generated PDFs/KML/DXF/workbooks register to `Generated_Documents` or `File_Registry`.
- `logCertaSurvFormsDeploymentAudit()` passes.
- `logCertaSurvRoutingSchemaAudit()` passes after any form/spec/header change.

## 22. Current Known Gaps

- The Operations Hub specs include the field-office direction bundle, but production Google Forms still need to be created/connected and `Forms_Links` backfilled before the form layer is live.
- The local Apps Script builder preserves field-office direction context in `Notes`; the deployed Apps Script must match the local source before production rebuild.
- Some AppSheet office/admin apps still exist as reconciliation debt and should be retired or justified by a documented mobile/offline need.
- The Drive watcher contract exists, but production requires supervised deployment before direct Drive drops become automatic.
- Large SMS archives should be replaced for workflow use by Ed-only or job-specific text exports without embedded MMS media.

## 23. Source Inventory Used For This Draft

### Live Google / Operations Sources

- CertaSurv Operations Hub
- `Field_Direction_Form`
- `Field_Daily_Log_Form`
- `Field_Troubleshooting_Form`
- `Field_Process_Steps`
- `Field_Decision_Rules`
- `Field_File_Naming_Rules`
- `Field_Ops_Workflow`
- `Field_Direction_Checkoff`
- `Daily_Log_Checkoff`
- `Source_Field_Crosswalk`
- `Job_Data_Dictionary`
- `Workflow_Surface_Map`
- `Google_Forms_Pipeline`
- `Field_Required_Files`
- `Field_Workflow_Tasks`
- `Field_Photo_Log`
- CertaSurv Field Direction and Daily Log Implementation Checkoff Google Doc

### Local CertaSurv / CERTARD Sources

- `C:\Users\SimpS\Documents\appsheet\README.md`
- `C:\Users\SimpS\Documents\appsheet\liaison_brief_2026-06-20.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\drive\CERTASURV_FORMS_AND_APPSHEET_RECONSTRUCTION.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\drive\CERTASURV_GOOGLE_FORMS_DEPLOYMENT.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\drive\CERTASURV_DRIVE_STANDARD.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\field\field_point_search_sop.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\docs\field_to_model_feedback_loop.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\docs\field_office_point_source_workflow.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\data\operational_point_catalog.json`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\data\planimetric_feature_catalog.json`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\tbc_code_rebuild\TRIMBLE_FEATURE_CODE_RESEARCH.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\tbc_code_rebuild\clean_code_seed_v1.csv`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\tbc_code_rebuild\alias_map_seed_v1.csv`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\certasurv-workflow-rebuild\docs\FIELD_STAKEOUT_PACKAGE_STANDARD.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\certasurv-workflow-rebuild\docs\TBC_WORKSPACE_MIRROR_STANDARD.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\certasurv-workflow-rebuild\docs\JS_SURVEY_TOOLS_APPSHEET_PREFILL_STANDARD.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\certasurv-workflow-rebuild\docs\FIELD_DATA_DRIVE_WATCHER.md`
- `C:\Users\SimpS\OneDrive\Documents\CERTARD\certasurv-workflow-rebuild\docs\BACKGROUND_PROCESSING_OWNERSHIP.md`

### Email / Message Direction Sources

- Gmail searches for Ed Converse direct instructions and Ed-attributed direction from Jarred/John threads.
- 2026-07-29 mailbox refresh: 31 direct-message hits across Ed's known addresses from 2026-03-05 through 2026-07-29; 18 operational candidates were read, and the six-message `Fwd: Map` / `Re: Map` thread dated 2026-07-22 through 2026-07-24 was expanded.
- New direct text sources included `SURVEY REQUIRED FOR AREA NEAR 10 MARYLAND AVENUE HAMLIN, WV 25523`, `Two Vanderbilt Mortgage and Finance projects`, the forwarded Vanderbilt title reports, and the corrected AutoCAD 2000 conversion request.
- The expanded map/plat thread supplied John/Jarred review criteria acknowledged by Ed, including references used, ROW source, apparent driveway encroachment, approximate location coordinates, a principal-corner coordinate, and disposition of a set rebar offset from the reviewed line.
- Image-only, personal, and non-operational messages were excluded. Attachment contents were not treated as handbook evidence unless the email text identified their operational role.
- Prior local transcript: `C:\Users\SimpS\.codex\attachments\658d4706-7b79-4698-bcf4-83f6f9d51f3d\pasted-text.txt`.
- Relevant direction themes found: explicit survey-product scope; parcel combination/remainder handling; research-package setup; title/deed/scan handoff; priority and capacity; corrected-direction supersession; pin recovery/replacement; heavy flagging; control points; drone shots; ROW uncertainty and source citation; encroachment exceptions; stakeholder/fence evidence; datum verification; common-line pins; well/utility uncertainty; plat references/coordinates/text/linework; CAD version; color/monochrome deliverables; surveyor seal; recordation hold; and message-to-job capture.
