# CERTASURV Release Readiness Checklist

Last updated: 2026-05-31

## Scope

This checklist is for release-ops readiness across Certa/CertaSurv control, handoff, and install lanes.

## Checklist

- [ ] Control repo is on intended release branch and clean (`git status` clean).
- [ ] Required control docs are present and current:
  - [ ] `docs/PROJECT_CONNECTION_MATRIX.md`
  - [ ] `docs/GIT_SITUATION.md`
  - [ ] `docs/CLOUD_PROCESSING.md`
  - [ ] `docs/CERTASURV_INSTALL_RUNBOOK.md`
  - [ ] `docs/CERTASURV_RELEASE_CHECKLIST.md`
- [ ] Required scripts are present and parse clean:
  - [ ] `scripts/Test-CertaProjectProvisioning.ps1`
  - [ ] `scripts/Set-CertaGitRemotes.ps1`
  - [ ] `scripts/Manage-CertaLaptopLoad.ps1`
- [ ] Shared-drive staging location is reachable and writable.
- [ ] Shared-drive handoff metadata includes required launch keys and release path.
- [ ] GitHub Actions control checks passed for latest release commit.
- [ ] Release note includes commit SHA, timestamp, and staged package path.
- [ ] No live-production emergency conditions are active.

## Sign-Off

- Release operator:
- Date:
- Commit SHA:
- Handoff path:
