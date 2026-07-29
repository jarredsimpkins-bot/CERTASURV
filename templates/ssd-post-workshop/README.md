# SSD post-workshop project structure

This is the canonical empty project layout supplied in
`SSD_POST_WORKSHOP_EMPTY_TEMPLATE.zip` on 2026-07-29.

- `structure.txt` contains one project-relative directory per line.
- `SSD` is the project payload root.
- Applying the manifest is additive: existing folders and files are preserved.
- `scripts/Merge-CertaSsdProjectStructure.ps1` materializes the same layout on a
  filesystem target and supports `-WhatIf`.

The first live rollout target is the Google Drive shared folder `SERVER1`.
The main project drive is intentionally out of scope until the SERVER1 rollout
is verified.
