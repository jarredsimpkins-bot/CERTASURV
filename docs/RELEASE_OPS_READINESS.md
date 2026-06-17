# Release Ops Readiness

Last updated: 2026-06-17 03:45 ET

## Current Remote Signal

- Public GitHub Actions visibility currently shows `CertaHealth Control Checks #18` for commit `4a88927` (`Align launch scripts with renamed repo paths`).
- That visible run completed successfully on 2026-06-17 at `2026-06-17T07:11:26Z`.
- Direct CLI inspection is still blocked on this workstation because `gh auth status` is not authenticated.

## Repo-Local Launch Checks

- The control-check workflow now requires this readiness note, the cloud offload runner, the publish helper, and the provisioning/remotes scripts.
- `scripts/Test-CertaProjectProvisioning.ps1` is the repo-local preflight for renamed workspace paths, shared-drive mount expectations, Git tooling, and local dependency visibility.
- The release-ops scripts now prefer `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; the legacy `New project2` alias is only retained as a compatibility fallback for older clones.

## Known Launch Blockers

1. `gh` must be authenticated before CLI-based release publishing or workflow inspection can be considered ready.
2. `node` and `npm` are still expected to be missing from PATH on this workstation unless Node.js is restored.
3. Older `CERTAHEALTH` clones may still push to the legacy public `CERTASURV` remote instead of `https://github.com/jarredsimpkins-bot/certahealth.git`.
4. Shared-drive cutover is still in progress, so release docs and scripts must keep handling both `G:\Shared drives\CERTASTRUCT` and `G:\Shared drives\CERTASURV_PROJECT DRIVE`.

## Recommended Operator Sequence

1. Run `powershell -ExecutionPolicy Bypass -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed`.
2. Authenticate GitHub CLI with `gh auth login`.
3. Confirm the local web-app folder is `CERTASURV_WEB_APP`; keep the legacy alias fallback only where an older clone still depends on it.
4. Repoint `CERTAHEALTH` to `https://github.com/jarredsimpkins-bot/certahealth.git` in any older local clones before launch publishing.
