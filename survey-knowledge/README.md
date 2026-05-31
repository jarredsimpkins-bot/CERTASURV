# Survey Knowledge

Internal CertaStruct knowledge harvester for surveying education, public YouTube transcripts, PDFs, books, SOP drafts, and field-office workflow training.

This project is built to turn public surveying education and internal documents into a searchable local knowledge base, then translate that knowledge into CertaStruct-specific SOP candidates, checklists, and training modules.

## What it ingests

### Public YouTube transcript sources

- The 3rd Dimension / `@The3rdDimensionSurveying`
- Surveying With Robert / `@SurveyingWithRobert`
- Rami Tamimi, P.S. / `@RamiTamimi`

The project only collects public metadata and publicly available captions/transcripts. It does **not** download video or audio.

### Internal documents

Drop files into:

```text
documents/inbox/
books/inbox/
```

Supported starter formats:

- `.pdf`
- `.txt`
- `.md`
- `.docx`

EPUB support is reserved for later. Keep copyrighted books private/internal and do not redistribute extracted text.

## Why this exists

The goal is not just storage. The goal is:

```text
source knowledge -> searchable chunks -> CertaStruct application reports -> SOP draft -> checklist -> training module
```

## CertaStruct rules baked in

- Point numbers should not use letters.
- Designations such as `ACP`, `GCP`, `CHECK`, `BM`, `CP`, `SET`, and `FOUND` belong in point descriptions, not point numbers.
- Applied notes should distinguish:
  - what the source actually says
  - what we infer
  - how it applies internally
  - whether internal testing is needed before adoption

## Setup

```bash
cd survey-knowledge
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Main commands

Fetch YouTube video metadata and public transcripts:

```bash
python ingest_youtube.py fetch-all
python ingest_youtube.py build-db
```

Ingest PDFs and documents:

```bash
python ingest_documents.py ingest
python ingest_documents.py build-db
```

Search everything:

```bash
python search.py "Trimble Access backsight error"
python search.py "point numbering"
python search.py "level loop adjustment"
python search.py "scanner control density"
```

Create an applied internal report:

```bash
python apply_to_certastruct.py "GNSS base rover workflow"
python apply_to_certastruct.py "total station backsight error"
```

Build starter SOP drafts:

```bash
python build_sop_drafts.py
```

## Folders

```text
survey-knowledge/
  config.yaml
  ingest_youtube.py
  ingest_documents.py
  search.py
  apply_to_certastruct.py
  build_sop_drafts.py
  data/
    raw/
    transcripts/
    chunks.jsonl
    videos.json
    documents.json
  documents/
    inbox/
  books/
    inbox/
  notes/
  reports/
  sop_drafts/
  survey_knowledge.sqlite
```

## First searches to run

```bash
python search.py "point numbering"
python search.py "Trimble Access backsight error"
python search.py "TBC sync files field office"
python search.py "R8 base rover radio cellular"
python search.py "level loop adjustment"
python search.py "topographic survey total station"
python search.py "GNSS control network"
python search.py "scanner control density"
python search.py "drone data georeferenced in TBC"
python search.py "total station vertical accuracy"
```
