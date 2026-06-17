# Release Ops Readiness

Last updated: 2026-06-16 22:45 America/New_York

This runbook captures the current release-operations state for the local `CERTAHEALTH` control repo and the public `CERTASURV` GitHub repo without modifying live shared-drive content.

## Current Snapshot

- Local checkout: `C:\Users\SimpS\.codex\worktrees\307d\CERTAHEALTH`
- Git commit under inspection: `05d4eeb0c047fbb8a730264506dbe412b8ef024d`
- Public remote: `https://github.com/jarredsimpkins-bot/CERTASURV.git`
- GitHub CLI status on this workstation: not authenticated as of 2026-06-16

## Workflow Output Check

- Public GitHub Actions currently shows 2 runs for `CertaHealth Control Checks`, both on `main`.
- Latest visible run:
  - Title: `Use git credentials for cloud offload pushes`
  - Commit: `d2e6776`
  - Trigger time: May 23, 2026 00:38
  - Status: `Success`
  - Duration: `18s`
- Previous visible run:
  - Title: `Document adaptive cloud offload rule`
  - Commit: `c739104`
  - Status: `Success`
  - Duration: `23s`

## Launch Risks Still Open

- `gh auth status` fails, so authenticated log inspection, release publishing, and private-repo checks are blocked from this workstation until `gh auth login` is completed.
- The local web-app workspace has been renamed to `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`, but older docs/scripts still used `New project2` before this run.
- The shared-drive rename is incomplete. `G:\Shared drives\CERTASTRUCT` exists, but the live command-center hierarchy still resides under `G:\Shared drives\CERTASURV_PROJECT DRIVE`.
- GitHub Actions warns that `actions/checkout@v4` is still on the Node 20 compatibility path and that `windows-latest` is being redirected.

## Operating Rule

- Treat `CERTASURV_WEB_APP` as the canonical local app workspace name.
- Treat `G:\Shared drives\CERTASTRUCT` as the preferred shared-drive root label when discussing the release target.
- Keep runtime checks dual-root aware until the command-center content is migrated out of `G:\Shared drives\CERTASURV_PROJECT DRIVE`.
- Do not edit live shared-drive content from this repo unless a committed repo artifact is being copied out intentionally.

## Minimum Release-Ops Verification

1. Run the local PowerShell syntax and required-file checks from `.github/workflows/certahealth-control-checks.yml`.
2. Run `scripts/Test-CertaProjectProvisioning.ps1 -Detailed` and review any missing items before handoff.
3. Confirm `gh auth status` succeeds before depending on CLI-based push/log workflows.
4. Confirm the web-app workspace path resolves to `CERTASURV_WEB_APP`.
5. Confirm both shared-drive roots are documented correctly in any operator handoff.
