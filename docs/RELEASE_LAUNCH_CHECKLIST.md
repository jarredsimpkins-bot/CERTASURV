# Certa Control Repo Launch Checklist

Last updated: 2026-08-20

Use this checklist for the control-repo side of a Certa/CertaSurv launch or release handoff. This stays repo-local and should be updated before copying any generated release notes into external systems.

## Control Repo Gates

| Gate | What to confirm | Current state |
| --- | --- | --- |
| Workflow green on `main` | `CertaHealth Control Checks` succeeds for the exact immutable launch commit | Required at launch; do not rely on an older green run |
| Docs present | Release readiness, connection matrix, git situation, cloud processing, and this checklist are committed | Required by workflow |
| PowerShell syntax clean | All tracked `.ps1` files parse without errors | Required by workflow |
| Workspace path aligned | Operator-facing web app path uses `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP` | Verified in current repo docs/scripts |
| Shared-drive handoff references intact | External staging/deploy references still point to `G:\Shared drives\CERTASURV_PROJECT DRIVE` | Verified read-only on June 17, 2026 |
| GitHub access for private repos | `gh` is authenticated with repo/workflow access on the host used for release operations | Blocked on this host |
| Control repo destination decided | Final answer exists for `CERTASURV.git` vs `certahealth.git` | Decision still open |

## Operator Sequence

1. Run `git status --short` in `CERTAHEALTH` and confirm only intended release-ops edits are present.
2. Run `pwsh -File .\scripts\Test-CertaProjectProvisioning.ps1 -Detailed` and record any missing tools or mounts.
3. Confirm the latest public control workflow run on `main` is green before handing off notes or switching remotes.
4. Verify external handoff references remain read-only unless copying from committed repo docs.
5. Decide the permanent control-repo remote before final launch cutover so release notes, automation, and operator docs all point to one destination.
6. Authenticate `gh` before any private workflow/log inspection or release push that depends on GitHub CLI.

## Current Launch Blockers

1. `gh` is not authenticated on this host, so private workflow runs/logs cannot be inspected here.
2. The permanent GitHub destination for `CERTAHEALTH` is still unresolved between public `CERTASURV.git` and dedicated `certahealth.git`.

## Evidence References

- Public workflow: `https://github.com/jarredsimpkins-bot/CERTASURV/actions/workflows/certahealth-control-checks.yml`
- Record the exact merged commit and its successful workflow URL in the launch receipt before target deployment.

## Certa Server v1 Launch Gates

For the `D:\SERVER` control plane, launch is green only when all of the following are true:

1. The newest `CONTROL\receipts\*-attempt.json` record reports `PASS`; its `run_id` and immutable Git commit match the referenced installer manifest, which also reports `PASS`. Never accept an older manifest after a newer attempt failed or remains `RUNNING`.
2. Local health reports `PASS`: required folders exist, Ollama is healthy and localhost-only, `certard-local` exists, cloud use is disabled, and the signed-in foreground TRIGGERcmd profile has every required command with parameters disabled.
3. The synthetic end-to-end smoke test reports `PASS` and preserves its routing, Ollama, output, and archive evidence.
4. A remotely refreshed catalog beacon is fresh and exactly matches `H-PASS S-PASS` with a new run ID.
5. After a reboot, the dedicated profile is signed in, a new smoke test passes, and another refresh produces a new `H-PASS S-PASS` beacon.

An unchanged beacon, zero or multiple beacons, `ATTN`, `INIT`, `RUNNING`, `STALE`, `ERROR`, or `FAIL` is not green. Beacon state is operational telemetry only and never grants professional, destructive, credential, or release authority.

The v1 TRIGGERcmd persistence model is sign-in dependent. Do not claim unattended-before-login operation. Review all retained pre-existing commands, especially parameter-enabled entries, before calling the whole foreground profile safe.
