# Release Blocker Exit Criteria - 2026-06-21

This checklist turns the current release blockers into concrete exit gates. It is repo-local release operations documentation only; do not copy it to the live shared drive until it has been committed and reviewed.

## MACROTBC Exit Gate

MACROTBC remains a substantive blocker until all of these are true:

| Gate | Required Evidence | Release Impact |
| --- | --- | --- |
| Working tree understood | `git -C C:\Users\SimpS\OneDrive\Documents\MACROTBC status --short --branch` has no unexplained deletes or generated-output noise in the review set | Prevents packaging or pushing an accidental partial tree |
| Shared-drive config present | `C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json` exists or has an intentional replacement path documented in MACROTBC | Restores local validation against the shared-drive handoff root |
| Node package metadata present | `C:\Users\SimpS\OneDrive\Documents\MACROTBC\package.json` exists, or the repo runbook explicitly says MACROTBC no longer uses npm validation | Restores a clear validation command for cloud and local review |
| Validation command recorded | The exact MACROTBC validation command and result are captured in the release note or PR body | Makes reviewer approval repeatable |
| Remote review path clear | Active branch is pushed to `https://github.com/jarredsimpkins-bot/macrotbc.git` or the launch owner records a local-only exception | Removes ambiguity around launch review timing |

Recommended next command sequence after the working tree is cleaned or intentionally scoped:

```powershell
git -C C:\Users\SimpS\OneDrive\Documents\MACROTBC status --short --branch
Test-Path C:\Users\SimpS\OneDrive\Documents\MACROTBC\certasurv_shared_drive.json
Test-Path C:\Users\SimpS\OneDrive\Documents\MACROTBC\package.json
```

Run MACROTBC repo validation only after the package/config expectation is resolved.

## WV_COURTHOUSE_RESEARCHER Exit Gate

WV_COURTHOUSE_RESEARCHER remains a substantive blocker until all of these are true:

| Gate | Required Evidence | Release Impact |
| --- | --- | --- |
| Remote decision made | `git -C C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER remote -v` shows the intended remote, or the launch owner records that the repo remains local-only for this release | Determines whether cloud review is possible |
| Active edits scoped | `git -C C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER status --short --branch` contains only intended courthouse/toolkit files | Prevents pushing unrelated field-prep changes |
| Runbook alignment checked | `docs/certasurv_project_prep_machine.md`, `docs/certasurv_toolkit_runbook.md`, `ortho_lidar_to_tbc_basemap/docs/workflow.md`, and `templates/certasurv_tool_registry.json` agree on the launch workflow | Keeps operator handoff from splitting into conflicting instructions |
| Push or exception recorded | Active branch is pushed for review, or the release note states why WV courthouse work is excluded from launch review | Removes the current upstream blocker |

Recommended next command sequence:

```powershell
git -C C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER remote -v
git -C C:\Users\SimpS\OneDrive\Documents\WV_COURTHOUSE_RESEARCHER status --short --branch
```

## Control Repo Follow-Through

Before final launch handoff, record these in `docs/RELEASE_OPS_READINESS.md` or the release PR body:

1. Latest visible `CertaHealth Control Checks` run for `main`.
2. Latest visible feature-branch workflow run for the release-ops branch being reviewed.
3. MACROTBC exit-gate result.
4. WV_COURTHOUSE_RESEARCHER exit-gate result.
5. Whether `gh` is authenticated on the release host.
6. Whether `G:\Shared drives\CERTASURV_PROJECT DRIVE` is mounted and validated.
