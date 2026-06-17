# Release Ops Readiness

Last updated: 2026-06-17 America/New_York

This runbook captures the current release-operations state for the local `CERTAHEALTH` control repo and the visible public GitHub workflow history without modifying live shared-drive content.

## Current Snapshot

- Local checkout under inspection: `C:\Users\SimpS\.codex\worktrees\2656\CERTAHEALTH`
- Git commit at start of this pass: `05d4eeb0c047fbb8a730264506dbe412b8ef024d`
- Configured remote in this checkout: `https://github.com/jarredsimpkins-bot/CERTASURV.git`
- GitHub CLI status on this workstation: `gh auth status` reports no logged-in GitHub hosts as of 2026-06-17

## Workflow Output Check

- Public GitHub Actions currently shows 10 visible runs for `CertaHealth Control Checks`.
- Latest visible run on 2026-06-17:
  - Run: `#10`
  - Title: `chore: harden certahealth launch publish checks`
  - Commit: `14b9b65`
  - Branch: `codex/certahealth-launch-publish-hardening`
  - Status: `Success`
  - Duration: `2m 34s`
- Previous visible run:
  - Run: `#9`
  - Title: `Align control repo with CERTASURV_WEB_APP rename`
  - Commit: `6677946`
  - Branch: `codex/certahealth-web-app-path-alignment`
  - Status: `Success`
  - Duration: `1m 41s`

## Launch Risks Still Open

- This checkout still points at the legacy public `CERTASURV` remote; switch to `https://github.com/jarredsimpkins-bot/certahealth.git` when the dedicated control repo becomes the launch target.
- The local web-app workspace has been renamed to `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`, so scripts and handoff docs need to treat `New project2` only as a fallback alias.
- The shared-drive rename is incomplete. Operators may see both `G:\Shared drives\CERTASTRUCT` and `G:\Shared drives\CERTASURV_PROJECT DRIVE`, while the live command-center hierarchy still resolves under the latter.
- `node` and `npm` are still missing from PATH on this workstation, so local web-app tooling remains blocked outside bundled runtimes.
- GitHub shows environment warnings that should be tracked before launch hardening completes: `actions/checkout@v4` is on the Node 20 compatibility path, and `windows-latest` is being redirected.

## Operating Rule

- Treat `CERTASURV_WEB_APP` as the canonical local app workspace name.
- Treat `G:\Shared drives\CERTASTRUCT` as the preferred shared-drive root label in release-facing docs.
- Keep runtime checks dual-root aware until the command-center content is migrated out of `G:\Shared drives\CERTASURV_PROJECT DRIVE`.
- Do not edit live shared-drive content from this repo unless a committed repo artifact is being copied out intentionally.

## Minimum Release-Ops Verification

1. Run the local PowerShell syntax and required-file checks from `.github/workflows/certahealth-control-checks.yml`.
2. Run `scripts/Test-CertaProjectProvisioning.ps1 -Detailed` and review any missing items before handoff.
3. Confirm the web-app workspace path resolves to `CERTASURV_WEB_APP`, with `New project2` accepted only as a fallback.
4. Confirm any operator handoff that names the shared drive documents both the preferred `CERTASTRUCT` label and the current command-center root.
5. Switch `CERTAHEALTH` to the dedicated `certahealth` remote before any launch flow that depends on repo-specific release publishing.
