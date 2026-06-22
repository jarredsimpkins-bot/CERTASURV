# Certa Release Ops Readiness

Last updated: 2026-06-22 10:35

## Launch Snapshot

| Area | Current Signal | Readiness |
| --- | --- | --- |
| Control repo workflow | `gh` shows latest visible run `#168` succeeded on June 22, 2026; latest visible `main` run `#41` also succeeded | Ready |
| Control repo docs | Core launch docs are present and the workflow now guards required files plus retired web-app script paths | Ready |
| Shared-drive handoff docs | Shared-drive staging and Apps Script deployment references exist outside this repo; live `G:` mount remains an external launch-host check | Ready with external dependency |
| Web app workspace naming | Active local folder is `C:\Users\SimpS\OneDrive\Documents\CERTASURV_WEB_APP`; release scripts no longer fall back to `New project2` | Ready |
| CERTARD | Local workspace has remote `jarredsimpkins-bot/certard.git`; one liaison brief is modified locally on `codex/certasurv-unified-forward` | Review timing |
| CERTASURV_WEB_APP | Local workspace has remote `jarredsimpkins-bot/certasurv-web-app.git`; current checkout contains many unrelated generated/data/cache changes | Local hygiene before push |
| MACROTBC | Local workspace exists at `C:\Users\SimpS\OneDrive\Documents\MACROTBC`, branch `codex/certasurv-unified-forward`, remote `jarredsimpkins-bot/macrotbc.git`, clean during this pass; command-center/AppSheet handoff still needs release review | Substantive release blocker |
| WV courthouse researcher | Local workspace exists at `C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER`; current branch has uncommitted release-prep docs/scripts and no configured remote observed during this pass | Blocked |
| GitHub CLI access | `gh auth status` succeeds on this host as `jarredsimpkins-bot` with `repo` scope | Ready |
| Final control-repo destination | `CERTAHEALTH` still points at public `CERTASURV.git`; planned `certahealth.git` exists | Decision needed |

## External Handoff References Checked

- `C:\Users\SimpS\OneDrive\Documents\CERTARD\scripts\Stage-CertaSurvSharedDrive.ps1`
- `C:\Users\SimpS\OneDrive\Documents\AUTOMATIONS\share-drive-automation\DEPLOY_THIS.md`
- `C:\Users\SimpS\OneDrive\Documents\MACROTBC\command_center\command_center_manifest.json`

These references are expected to align on the shared-drive root `G:\Shared drives\CERTASURV_PROJECT DRIVE`, but the drive is not mounted in this run, so live shared-drive contents were not modified or revalidated.

## Current Verified Workflow Signal

- Workflow file: `.github/workflows/certahealth-control-checks.yml`
- Latest verified visible run: `#168`, branch `codex/release-control-webapp-path-guard-20260622-790c`, commit `f4144ce`, created `2026-06-22T14:12:24Z`, conclusion `success`
- Latest verified `main` run: `#41`, branch `main`, commit `6f40b64`, created `2026-06-18T16:17:45Z`, conclusion `success`
- Verified job summary for run `#168`: `powershell-and-docs` succeeded, including `Validate PowerShell syntax`, `Block retired web app path in scripts`, and `Verify required control files`

## Launch Blockers

1. Finish MACROTBC release review on `codex/certasurv-unified-forward` and confirm the AppSheet/command-center handoff is ready for the launch package.
2. Configure and push the `WV_COURTHOUSE_RESEARCHER` remote after reviewing its local uncommitted release-prep changes.
3. Clean or explicitly exclude `CERTASURV_WEB_APP` generated/data/cache changes before any release push from that repo.
4. Remount `G:\Shared drives\CERTASURV_PROJECT DRIVE` before copying generated handoff docs or validating live release staging.
5. Decide whether the control repo should keep using public `CERTASURV.git` or switch to the planned dedicated `certahealth.git` remote before launch cutover.

## Non-Blocking Follow-Up

- Use the updated control scripts to include `WV_COURTHOUSE_RESEARCHER` in provisioning, remote setup, publish, and cloud-offload checks.
- Keep using the public REST API as a fallback if GitHub CLI credentials expire on this host.
