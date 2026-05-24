# Headrick / Conley Current Research Reconciliation

Updated: 2026-05-24

## Project identity

Project in operations hub:

- Internal project: CSD-2026-0004
- Client job: SSD-11635
- Project name/address: 1248 Browning Lambert Mtn
- County: Mercer County, West Virginia
- Scope: Boundary Survey
- Current queue/status: FIELD REMAINING

## Headrick subject parcels

Confirmed Headrick target references from project tracking / Drive research:

- Headrick: Map 50 Parcel 129; Map 51 Parcel 2
- Parcel references: 11-50-129 and 11-51-2
- GIS PIDs:
  - 28-11-0050-0129-0000
  - 28-11-0051-0002-0000
- Context: Browning Lambert Mtn / Crane Creek
- KML/stakeout package found and parsed on 2026-05-15
- Headrick primary parcels and nearby adjoiners were added to the GIS parser.

## Parcel card / current tax record found

File located in Drive:

- HEADRICK ALEX & JAMIE.pdf

Extracted card details:

- Owner: HEADRICK ALEX & JAMIE
- Mailing address: 7410 SR 46, Mims, FL 32754
- Parcel ID: 11 50012900000000
- District / Map / Parcel: 11-50-129
- Parcel address: 260 BROWNING LAMBERT MTN
- Legal description: 9.50 AC CRANE CK
- Deed Book / Page: 1124 / 0395
- Tax year: 2025
- Acreage: 9.5 acres
- Sale reference: 04/05/2023, Book/Page 1124

## Client-provided Conley / tract packet

From the project `FROM CLIENT` folder, the file `tract1info.pdf` contains:

- Parcels location on tax map and terrain under said location.
- Property recorded in DB 253 / PG 350.
- Property reserved in DB 640 / PG 554.

This confirms the tract being reconstructed is tied to the 253-350 parent tract and later 640-554 reservation/residue transaction.

## Reconciliation interpretation

The Headrick and Conley relationship appears to derive from a common parent tract or related chain around the Crane Creek / Browning Lambert / Montcalm area.

The strongest working interpretation is:

1. DB 253 / PG 350 is the original controlling parent description.
2. DB 640 / PG 554 is a reservation, severance, or residue instrument affecting the parent tract.
3. Headrick is a later ownership parcel or parcels derived from the same neighborhood chain.
4. Conley is likely an adjoining or residue holder connected through the same parent description.
5. The shared calls are likely inherited parent-boundary / occupation calls rather than independent duplicate geometry.

## Calls currently believed to be central to Headrick / Conley reconciliation

These calls should be treated as probable shared-control or parent-shell calls until the exact Conley deed text is fully extracted:

```text
WITH RORRER LINE UP HOLLOW ABOUT 55 POLES
TO A STAKE AND IRONWOOD POINTER

S11°W 12 POLES
TO A STONE, CORNER OF THE J.L. HONAKER TRACT

N64°32'W 1023.1 FT
TO A CHESTNUT SAPLING BY THE COUNTY ROAD,
CORNER OF THE J.W. HALL 40 ACRE TRACT

WITH COUNTY ROAD
TO TWO SMALL LOCUSTS IN THE M.B. RIGGS LINE

WITH THE M.B. RIGGS LINE
TO A BLACK OAK, CORNER OF M.B. RIGGS AND W.H. RIGGS

WITH W.H. RIGGS LINE 340 FT
TO THE POINT OF BEGINNING
```

## SC/LB representation of current controlling tract shell

```text
SC 0.000, 0.000,,, BEGINNING AT A STAKE, CORNER OF W.H. RIGGS, H.H. LUCAS AND G.T. RIGGS
LB S44°25'00.0"E, 116.600,,, TO A STONE
LB N34°50'00.0"E, 154.900,,, TO A STONE
LB N61°00'00.0"E, 290.100,,, TO A STONE ON A POINT
LB S31°30'00.0"E, 503.600,,, TO A LOCUST AND POPLAR IN THE RORRER LINE
LB ?, 907.500,,, WITH SAID RORRER LINE UP THE HOLLOW ABOUT 55 POLES TO A STAKE AND IRONWOOD POINTER
LB S11°00'00.0"W, 198.000,,, TO A STONE, CORNER OF THE J.L. HONAKER TRACT
LB N64°32'00.0"W, 1023.100,,, TO A CHESTNUT SAPLING BY THE COUNTY ROAD, CORNER OF THE J.W. HALL 40 ACRE TRACT
LB ?, ?, ,, WITH COUNTY ROAD TO TWO SMALL LOCUSTS IN THE M.B. RIGGS LINE
LB ?, ?, ,, WITH THE M.B. RIGGS LINE TO A BLACK OAK, CORNER OF M.B. RIGGS AND W.H. RIGGS
LB ?, 340.000,,, WITH W.H. RIGGS LINE TO THE POINT OF BEGINNING
```

## Notes on geometry

- The 55-pole Rorrer call is not a hard straight deed course; it is a hollow/meander/adjoiner line.
- 55 poles = 907.5 ft.
- The county road segment is also likely an occupation / road-meander segment.
- The M.B. Riggs segment is unresolved and must be tied by adjoiner evidence.
- The old/new county road language indicates road relocation or multiple roadbeds, which should be checked in LiDAR.
- Do not force this deed into closure using only straight-line bearings. The correct hierarchy should weight occupation calls, adjoiner calls, road evidence, hollow/ridge terrain, and parent-chain seniority.

## Current blockers

- Exact Conley deed text/image still needs extraction from the client packet or courthouse source.
- DB 253 / PG 350 and DB 640 / PG 554 must be pulled and transcribed completely.
- Headrick DB 1124 / PG 0395 current deed should be pulled and compared against the parent/reservation calls.
- Confirm whether Conley is adjoining, residue, reserved tract holder, or simply neighboring chain reference.
- Confirm which modern parcel lines correspond to the old Rorrer/Honaker/Hall/Riggs framework.

## Field / drafting recommendations

1. Pull full deed images for:
   - DB 253 / PG 350
   - DB 640 / PG 554
   - DB 1124 / PG 0395
   - Any Conley deed found in client packet / adjoiner research.
2. Build separate COGO plots for:
   - parent tract DB 253-350
   - reservation/residue DB 640-554
   - current Headrick deed DB 1124-395
   - Conley deed
3. Tag calls as:
   - parent shell
   - reservation carve-out
   - modern parcel boundary
   - adjoiner corroboration
   - terrain/meander only
4. Use LiDAR to identify:
   - old county road bench
   - new county road
   - hollow followed by Rorrer call
   - ridge/point references
   - possible remnant fence/corner occupation near Riggs/Honaker/Hall references

## Confidence summary

High confidence:

- Headrick project identity and subject parcel references.
- Headrick tax parcel 11-50-129 / 9.50 AC Crane Creek / DB 1124 PG 0395.
- Client packet identifies DB 253-350 and DB 640-554 as controlling or relevant historical records.
- The Riggs/Honaker/Rorrer/Hall call set is central to the tract reconstruction.

Medium confidence:

- Conley shares or derives from the DB 253-350 / DB 640-554 chain.
- Shared Headrick/Conley calls are inherited parent-boundary calls.

Low / unresolved:

- Exact Conley boundary line until the Conley deed text is extracted.
- Direction and shape of the 55-pole hollow segment.
- County road meander and M.B. Riggs segment geometry.
