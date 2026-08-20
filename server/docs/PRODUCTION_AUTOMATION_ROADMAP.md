# CertaSurv Production Automation Roadmap

## Mission

`D:\SERVER` is not merely an Ollama host. It is the company work-intake, evidence, routing, execution, validation, and receipt engine.

Every job enters the server first. The server decides whether the next step should be:

1. a verified deterministic script;
2. a low-risk local Ollama worker;
3. Codex engineering or debugging;
4. a specialist workstation such as MSI for TBC, Land Desktop, CAD, CloudCompare, or WebODM;
5. a human, administrator, or licensed surveyor decision.

The server remains the task owner even when a specialist PC performs one step.

## Non-negotiable authority rules

- Original deeds, plats, field files, imagery, GIS, CAD, and client records remain preserved as source evidence.
- AI output is candidate information until independently validated.
- Public-source and computed geometry never silently becomes authoritative survey geometry.
- Boundary resolution, final professional judgment, controlled release, destructive deletion, credentials, and legal/contractual authority remain human/PLS/admin gates.
- Every state-changing operation produces a validator result and an execution receipt.
- Repeated successful Codex work should be promoted into a tested deterministic script or reusable skill.

---

## Production capability families

### 1. Project intake and project identity

**Goal:** Create one governed project record keyed by the CertaSurv SSD project number.

**Inputs**

- intake form, estimate/scope, client files, tax-map/GIS location, KML/KMZ, deeds, plats, photos, prior company work;
- existing Shared Drive or local project folder;
- operator instructions.

**Server actions**

- validate or assign the SSD project identity;
- classify all incoming files without overwriting originals;
- create/update the project manifest and source registry;
- identify missing intake, research, field, drafting, QC, and delivery requirements;
- route each next action to SCRIPT, OLLAMA, CODEX, SPECIALIST, or HUMAN.

**Outputs**

- project manifest;
- source/evidence registry;
- current stage, owner, blocker, and next task;
- receipt.

---

### 2. Courthouse and title-research engine

**Goal:** Produce a structured, auditable research package rather than a folder of disconnected downloads.

**Workflow**

```text
Subject KML / GIS parcel
  -> identify touching and relevant parcels
  -> create one parcel folder per GIS/tax-map identity
  -> build Master Research Log
  -> collect map cards where available
  -> capture current deed and known plats
  -> search IDX / deed index
  -> preserve images/PDFs as source evidence
  -> OCR and extract metadata/back references
  -> update chain of title
  -> normalize legal calls
  -> determine whether each parcel has a plottable deed/plat source
  -> route unresolved gaps back to research
```

**Required extracted facts**

- grantor/grantee;
- deed book/page or instrument number;
- execution and recording dates;
- tax map/parcel and district;
- acreage;
- parent tract and exceptions/reservations;
- prior survey/plat references;
- called-for monuments and physical features;
- junior/senior title context and common-grantor sequence;
- back references;
- source file and page/image citation.

**Plot-source gate**

A parcel is not marked plot-ready until the server has either:

- a plottable deed;
- a plottable plat;
- or a verified direct reference to a plottable block/lot/plat/source.

OCR or AI confidence alone never satisfies the gate.

---

### 3. Deed and plat auto-plot engine

**Goal:** Convert record calls into deterministic candidate geometry with full provenance and QC.

**Server actions**

- preserve raw deed wording;
- parse bearings, distances, curves, ties, along/to calls, monument calls, and physical-feature calls;
- normalize calls into a controlled schema;
- compute the raw unadjusted plot;
- report closure vector, linear misclosure, closure ratio/precision, area, and call-level warnings;
- store any adjusted reconstruction separately from the raw plot;
- generate subject and adjoiner candidate geometry;
- compare multiple record sources without silently collapsing them;
- create a deed mosaic and common-corner network;
- compute segment-level deed-to-field deltas when field evidence exists.

**Outputs**

- calls CSV/JSON;
- raw plot DXF;
- optional KML/KMZ and PNG preview;
- closure report;
- source-linked point/line registry;
- unresolved-call list;
- plot receipt.

**Required QC signals**

- bearing and distance differences;
- endpoint residuals;
- lateral offset;
- translation/rotation versus true geometry disagreement;
- subject/adjoiner common-corner agreement;
- network loop closure;
- title seniority/juniority and source quality kept separately auditable.

---

### 4. Parcel mosaic and evidence reconciliation

**Goal:** Build the best record-evidence reconstruction before field deployment without pretending it is final boundary truth.

**Layer/evidence concepts**

- individual deed geometry remains on a DEED working layer;
- aggregate reconstruction remains on a DEED MOSAIC layer;
- accepted adjoiner geometry is promoted only after review to the approved ADJACENT layer;
- original geometry and provenance are always retained.

**Server actions**

- fit subject and adjoiner record geometry;
- expose gaps, overlaps, bad calls, rotations, translations, and outlier lines;
- weight conflicts using monuments, title sequence, prior surveys, parent-tract derivation, source quality, closure, and field evidence;
- prepare a review package, not an automatic legal conclusion.

---

### 5. Public-source extraction engine

**Goal:** Use orthophotos, LiDAR, terrain, GIS, and prior company data to create a real pre-field work plan.

**Candidate features**

- roads and drives;
- drains/thalwegs;
- ridges and terrain breaks;
- fences/walls;
- buildings and structures;
- streams;
- visible monuments or target objects;
- access, vegetation, terrain, and coverage conditions.

**Derived-layer rule**

All remote/computed geometry stays in grey `EXTRACT_` provenance layers, for example:

- `EXTRACT_ORTHO18_ROAD`;
- `EXTRACT_ORTHO21_DRAIN`;
- `EXTRACT_LIDAR_TERRAIN`;
- `EXTRACT_POINTCLOUD_STRUCTURE`.

Derived geometry is reference evidence. If later accepted for a final deliverable, it is copied/promoted to the approved final layer; the original `EXTRACT_` layer remains for QC/history.

**Road/drain action rule**

Any road or drain that borders, crosses, enters, or materially affects the working boundary becomes a green field action such as `SHOOT ROAD` or `SHOOT DRAIN`. Public geometry itself remains grey.

---

### 6. Automatic workmap production

**Goal:** Generate a field-ready package from record, GIS, public-source, and existing field evidence.

**Display/status rules**

- yellow phantom = current PL/working-boundary input and reference;
- green = unresolved SEARCH / required field verification or shot;
- red = recovered/accepted reliable field evidence;
- blue = set monument;
- orange = control, including BASE / NS / TRV;
- grey `EXTRACT_` = public, remote, or computed evidence.

**Workmap content**

- current working boundary context;
- subject and adjoiner record evidence;
- uncertainty/search areas at unresolved corners;
- called-for monuments, trees/species, roads, streams, ridges, fences, and other physical calls;
- green road/drain/feature shot requirements;
- existing found/set/control points;
- access and route planning;
- field notes and task callouts.

**Outputs**

- import-back DXF containing only the requested new markup when appropriate;
- KML/KMZ mobile workmap;
- PNG/PDF preview;
- CONTROL CSV;
- FIELD CSV;
- STAKEOUT CSV;
- search/action register;
- source and receipt files.

**Special overlay rule**

When producing a requested F-series label overlay, output only the requested F range with the point name and description at/adjacent to the point. Do not add unrelated vectors, leaders, point families, or linework.

---

### 7. Field-return ingestion and workmap updating

**Goal:** Turn field data into a controlled project update without losing lineage.

**Inputs**

- Trimble JOB/JXL/T02/raw files;
- CSV/PNEZD;
- GNSS vectors and traverse evidence;
- field photos and monument observations;
- crew notes;
- updated KML/workmap.

**Server actions**

- preserve raw authoritative files;
- identify BASE, NS/GNSS, TRV, control, search, found, and set observations;
- distinguish actual field observations from record/search seeds using field evidence and vector relationships rather than point number alone;
- update red/blue/orange/green status;
- compare field observations to P/F/TM record/search points;
- compute offsets, bearings, residuals, and description relationships;
- create the next search/stakeout generation when needed;
- update workmap, stakeout, control, and field packages;
- attach final QC/evidence to each final S point.

**Point lineage rule**

Point records remain unique events. Do not force the same numeric point ID across P/F/S states. Preserve lineage through source, description, proximity, parent/corner grouping, and audit metadata.

---

### 8. CAD, TBC, Land Desktop, CloudCompare, and WebODM dispatch

**Goal:** Let the server own the job while a specialist node performs software-specific work.

**Examples**

- TBC/Land Desktop import and verification on MSI;
- CAD label or symbology application;
- CloudCompare point-cloud processing;
- WebODM orthophoto generation;
- DXF/DWG conversion or legacy AC1015 production;
- approved final packaging.

**Contract**

```text
Server task
  -> named approved TRIGGERcmd/CertaNode action
  -> specialist node executes fixed script/workflow
  -> validator runs
  -> outputs and receipt return to D:\SERVER
```

No unrestricted shell or arbitrary AI-generated command is allowed.

---

### 9. Truth/QC engine

**Goal:** Separate aggressive extraction and candidate generation from mathematical and professional acceptance.

**Auto Extract**

- produces candidate roads, drains, structures, points, labels, deed calls, and geometry.

**Truth/QC engine**

- checks source authority and provenance;
- compares to field/control/deed/title evidence;
- computes residuals, closure, confidence, and conflict indicators;
- promotes, rejects, or sends to review;
- records the exact reason and reviewer.

The model may explain a discrepancy, but deterministic calculations and qualified review control acceptance.

---

### 10. Continuous project updater

**Goal:** Keep each project’s current task, evidence state, workmap, and next action current.

**Events**

- new intake;
- new courthouse source;
- new deed/plat;
- new field drop;
- new ortho/LiDAR extraction;
- new CAD output;
- failed validation;
- human correction or approval.

**Server response**

```text
EVENT
  -> RULE
  -> deterministic script where possible
  -> AI only where judgment is needed
  -> follow-up script/action
  -> validator
  -> execution receipt
  -> update project state and next task
```

---

## Implementation order

### Phase 0 — Runtime and routing foundation

- `D:\SERVER` canonical root;
- Ollama local-only worker;
- Trigger enrollment and named commands;
- queue worker;
- receipts and health;
- one deterministic manifest capability;
- one Ollama candidate task;
- one Codex task handoff;
- one MSI specialist handoff.

### Phase 1 — Courthouse Packet v1

- subject KML intake;
- touching-parcel register;
- parcel folders;
- Master Research Log;
- source capture manifest;
- OCR metadata extraction;
- chain-of-title/back-reference update;
- plot-source gate.

### Phase 2 — Auto Plot v1

- normalized line-call schema;
- deterministic bearing/distance plot;
- raw closure report;
- DXF/CSV/PNG outputs;
- source-linked call warnings;
- no automatic adjustment or boundary acceptance.

### Phase 3 — Workmap v1

- subject PL/context input;
- record points and search areas;
- public-source grey extracts;
- green `SHOOT ROAD` / `SHOOT DRAIN` actions;
- DXF/KMZ/PNG/CONTROL/FIELD/STAKEOUT outputs.

### Phase 4 — Field Return v1

- JOB/T02/CSV manifest and ingestion;
- field/control/search/found/set classification;
- deed-to-field comparisons;
- workmap and stakeout update;
- receipt and unresolved-action list.

### Phase 5 — Continuous project loop

- file/event watchers;
- state transitions;
- automatic rerouting after new evidence;
- specialist-node dispatch;
- project dashboard updates.

### Phase 6 — Capability promotion

After repeated verified Codex executions of the same task:

- propose a deterministic script/skill;
- add fixtures, tests, validator, version, and rollback;
- keep status `REVIEW` until human approval;
- promote to `VERIFIED` only after clean regression testing;
- route future matching tasks to SCRIPT first.

---

## Minimum production acceptance test

A noncritical test project must complete:

```text
intake
  -> courthouse packet
  -> source registry
  -> deed extraction
  -> raw auto plot and closure
  -> public-source extraction
  -> field workmap package
  -> mock field return
  -> updated workmap/stakeout
  -> specialist CAD handoff
  -> human review
  -> delivery package
  -> archive
  -> full receipt review
```

No unattended production authorization is granted until this end-to-end loop passes and the restore/recovery path is tested.
