# CERTASURV Install and Launch Runbook

Last updated: 2026-05-31

## Purpose

Provide a repeatable, low-risk install and launch sequence for the Certa/CertaSurv stack with clear stop points before production-impacting actions.

## Preconditions

- Shared drive is mounted: `G:\Shared drives\CERTASURV_PROJECT DRIVE`
- Local control repos are present and up to date.
- Required local paths exist:
  - `C:\Users\SimpS\OneDrive\Documents\CERTAHEALTH`
  - `C:\Users\SimpS\OneDrive\Documents\CERTARD`
  - `C:\Users\SimpS\OneDrive\Documents\MACROTBC`
- Production workload is stable (no emergency TBC recovery in progress).

## Release Install Sequence

1. Confirm repo health in `CERTAHEALTH`:
   - `git status --short --branch`
   - `pwsh -NoProfile -File scripts/Test-CertaProjectProvisioning.ps1`
2. Confirm local remotes and branch wiring:
   - `pwsh -NoProfile -File scripts/Set-CertaGitRemotes.ps1`
3. Validate load-manager safety posture:
   - `pwsh -NoProfile -File scripts/Manage-CertaLaptopLoad.ps1 -Mode Auto`
4. Run release checks in CI by pushing branch updates and confirming workflow success.
5. Stage install handoff artifacts from source repos to shared drive using approved staging scripts.

## Stop/No-Go Conditions

- Any PowerShell parse or provisioning check failure.
- Missing required shared-drive folder keys in handoff metadata.
- GitHub workflow check failures on release branch.
- Active TBC/Trimble emergency load where install actions would increase risk.

## Post-Install Verification

1. Confirm workflow status is green for latest release commit.
2. Confirm required release docs are present in repo and shared-drive staged copy.
3. Confirm `InstallReleases.csv` (or equivalent package index) has populated release version rows.
4. Capture launch note with UTC timestamp, commit SHA, and staged artifact location.

## Rollback Notes

- Revert only the scoped release commit(s), not unrelated local changes.
- Re-stage the previous known-good release package to shared drive.
- Record rollback reason and impacted components in release notes.
