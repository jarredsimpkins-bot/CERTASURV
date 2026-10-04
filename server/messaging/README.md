# CertaSurv client-texting outbox — gated pilot

Implementation location: `jarredsimpkins-bot/CERTASURV/server/messaging`.
Based on `main` commit `23df2bb1b0f9a6e83f00b3563fbecd6c10c504bd`.
This is a local control-plane queue, not a CRM, project record system, Firebase deployment, or authorization to contact clients.

## What is implemented

One bounded use case: an operator attests a real Gmail SENT receipt for an estimate, creates a project/client-linked draft, previews the exact recipient/body, and approves its fingerprint. A one-message worker then simulates it or submits it through a selected adapter. Nothing polls Gmail, imports phone archives, schedules messages, or sends on queue insertion.

`messaging.py` contains the provider interface, SQLite outbox, linked source/consent records, append-only application audit, approval binding, budget reservations, suppression and delivery state. `provider_twilio.py` is an optional real outbound REST adapter and signed-receipt/inbound WSGI adapter. `cli.py` is a local human interface. Existing router, installers, registries and capabilities are unchanged.

The actual provider is **not selected**: the example uses `provider=none`. Preserve the user's existing-cell preference. Do not purchase a number, port it, assume a verified voice caller ID can originate SMS, or require Twilio. A vetted Android/cell gateway can implement the same `Provider.send(message, config)` contract after a separate compatibility/security review. Its receipt and inbound adapters must authenticate events before calling the trusted core methods. The configuration allowlist must be deliberately extended and tested for a new provider; no arbitrary URL adapter is supplied.

## Defaults and hard stops

- `mode=dry_run`; durable global pause initially ON; empty operator/recipient allowlists; no sender/account; all monetary limits zero.
- No provider construction or network request during dry run. Simulations record `dry_run`, never `sent` or `delivered`; they consume no send reservation and cannot become live without a new approval.
- Each approval binds exact body, destination, project/client/source, consent revision, sender/provider configuration, release references and limits. Expiry defaults to 30 minutes. Changing any bound state requires fresh approval. Editing drafts clears approval.
- Consent must cover CertaSurv estimate-follow-up SMS and have an evidence reference. Emailing a person is not treated as SMS consent. Missing/unknown/revoked consent, missing SENT evidence, future events, events older than seven days, archived imports, or missing identity/opt-out text are held. This is a technical gate, not a legal/carrier-compliance certification.
- Idempotency is based on project, client, purpose and Gmail message ID (or a held event ID when the receipt is missing). Reimporting the same Gmail receipt with a different event ID cannot create a second send. Source/body conflicts require review rather than silently replacing approved text.
- Live sends require configured provider/sender, private token, explicit release/verification references, a recipient allowlist, a valid recipient timezone, and a weekday 09:00–17:00 local send window by default. These are conservative operating defaults, not assertions about legal permitted hours.
- Before one external POST, an atomic SQLite transaction claims the message and reserves a per-segment cost bound against daily/monthly USD limits and daily/recipient count limits. Reservations are retained on failure or ambiguity. Segment accounting includes GSM extensions and UTF-16 surrogate pairs. Default maximum is one segment.
- No automatic retry, redirect, or queue re-send. Timeout, malformed response and other ambiguous failures become `uncertain`. An interrupted `submitting` attempt is never reclaimed for sending; `recover` marks it uncertain after workers have stopped. A provider rejection is failed, not retried.
- Authenticated STOP/opt-out suppresses the phone globally; any other reply pauses automation too. START and a reimported consent record do not resume messaging. There is deliberately no automatic unsuppress/re-consent endpoint. A future reviewed human reconciliation workflow must handle resumption.
- Signed delivery receipts are deduplicated, bound to recipient/sender, and applied without regressing terminal state. Early callbacks are retained until the POST's SID is recorded. Provider acceptance/queued/sent is not proof of delivery. Delivery is not proof the client read the message.

## Local runtime and trust boundary

Use Python 3.11+ and one persistent local disk, for example `D:\SERVER\STATE\messaging\outbox.sqlite`. The program rejects relative DB paths and runtime DBs beneath a Git checkout/module. **Never** place the DB on OneDrive, Drive, SMB, a shared filesystem, or ephemeral Cloud Functions storage. SQLite transactions coordinate multiple local processes; this is not a distributed database implementation.

Keep the config at an operator-owned external path such as `D:\SERVER\CONFIG\messaging.json`. The database, consent evidence, contact phone numbers and full message bodies are private operational data. Audits omit message body, phone number and raw exception text, but the underlying DB still contains client information. Apply Windows ACLs, encryption at rest, backup/retention policy and log redaction before client data is used. Do not commit runtime records, `.env`, tokens, client fixtures or service-account JSON. Sample configuration and tests contain no usable credentials or real recipients.

Approval/consent functions are trusted local primitives, not remotely authenticated APIs. The CLI resolves the OS principal rather than accepting an actor from JSON/environment and requires an interactive terminal plus the full preview hash for approval. Enqueue and consent registration require separate interactive evidence attestations. Production requires a separate authorized human Windows account, protected config/DB ACLs and no agent/service impersonation of that account. Do not register approval or arbitrary CLI execution as an unattended TRIGGERcmd command. A person/process with write access to this runtime is inside the trust boundary; the SQLite audit is not externally tamper-proof.

## Test and dry-run workflow

From the repository root:

```powershell
py -3 -m unittest discover -s server/messaging -p test_messaging.py -v
```

The core tests use only the standard library plus an available IANA timezone database. Windows may need `tzdata`. The seven optional provider tests require the official Twilio validator. After approval of the dependency installation in the target environment:

```powershell
py -3 -m pip install -r server/messaging/requirements-twilio.txt
py -3 -m unittest discover -s server/messaging -p test_messaging.py -v
```

The direct Twilio version is pinned; generate/review a fully hashed transitive lock before production. Do not install into an unrelated global interpreter.

Copy `config.example.json` to the protected external config path and add only the verified human OS principal to `operators`, retaining dry-run/none/zero defaults. `identity` prints the current principal without touching the DB/config:

```powershell
$cli = 'server/messaging/cli.py'
$cfg = 'D:\SERVER\CONFIG\messaging.json'
$db = 'D:\SERVER\STATE\messaging\outbox.sqlite'
py -3 $cli --config $cfg --db $db identity
py -3 $cli --config $cfg --db $db contact D:\PRIVATE\contact.json
py -3 $cli --config $cfg --db $db enqueue D:\PRIVATE\estimate-sent.json
py -3 $cli --config $cfg --db $db preview <returned-message-id>
py -3 $cli --config $cfg --db $db approve <returned-message-id>
py -3 $cli --config $cfg --db $db dispatch <returned-message-id>
py -3 $cli --config $cfg --db $db status
py -3 $cli --config $cfg --db $db pause
```

Do not paste credentials or client message contents into shell arguments/history. The contact JSON fields are `client_id`, `phone` (confirmed E.164), `timezone_name` (confirmed IANA zone), `consent` (`unknown/granted/revoked`), and `evidence_ref`. Estimate-event JSON fields are `project_id` (SSD number), `client_id`, `body`, and `source`. Source fields: `event_id`, `gmail_message_id`, `sent_at` (timezone-qualified ISO timestamp), `evidence_ref`, `origin` (`live`). Never add an `actor` field; the CLI obtains identity itself. Start with synthetic records, not the client's real number.

Bodies must start `CertaSurv:` and include `Reply STOP to opt out.`. A missing source receipt stays held; do not invent one to satisfy validation. Gmail SENT evidence is manually attested in this pilot, not independently fetched by this module. Contact changes require revising/reapproving unsent drafts. A changed message ID requires a genuinely different source event, never a workaround for an uncertain send.

## CODEX / HUMAN handoff and deployment checklist

`New-CertaMessagingHandoff.ps1` calls the existing `D:\SERVER\ROUTER\New-CertaTask.ps1`, with CODEX/HUMAN as the only allowed lanes. Default CODEX requests a synthetic review/test receipt. `-Gate HUMAN` creates a separate release-review task. Creating or routing that task does not execute CODEX, deploy code, approve a message, or send anything. The script has not been executed on a user PC in this change.

Before owner-only live testing, a HUMAN must verify and record all of the following:

1. Correct deployed Certa server and persistent runtime; Python/timezone dependencies; independent review of this branch; private data storage, backups and appropriate separate operator account/ACLs. Confirm existing router behavior is unchanged on the target Windows host. Record `operator_acl_ref`.
2. Actual provider choice and authority to use the intended existing number, SMS capability, carrier/registration requirements, inbound/reply routing, consent evidence, and the verified sender. No number, account, carrier permission or credential is assumed. Record `sender_verified_ref` and select provider only after authorization.
3. Approved outbound money/count limits and a conservative all-in per-segment USD bound. `microusd` means one-millionth of USD: 10,000 is $0.01 (an example, NOT a carrier price). These limits bound this outbox's reserved outbound spend under that assumption, not the provider's entire bill; inbound traffic, number rentals, fees/taxes and Firebase infrastructure are outside it. Configure provider-side controls and check actual billing separately.
4. Supply `TWILIO_AUTH_TOKEN`, only for the optional Twilio adapter, from an approved secret manager or protected service environment. Never source control/chat/email. Firebase Secret Manager is appropriate for a separately approved cloud component. Account SID is non-secret config and is checked on callbacks. Do not print token values in diagnostics.
5. Approve an HTTPS ingress, bind its exact public `status_url` and `inbound_url`, and mount `provider_twilio.make_app(config_path, database_path)` behind a production WSGI server/reverse proxy. There is no built-in development listener or send/approve web route. Preserve form values, cap request size/rate/timeouts, redact ingress logs, verify signatures including all fields, test wrong-account/sender and retry behavior, and confirm STOP reaches this DB. Record `webhooks_verified_ref`. Keep reply/receipt ingress operating even when sends are paused.
6. Record a separate `live_release_ref` authorizing **owner-only** testing, fill only an owner-controlled test recipient in `allowed_recipients`, set explicitly approved nonzero limits, and switch to live. Fresh exact-message approval plus interactive `unpause` is still required. Prove POST, delivery receipt, duplicate handling and actual STOP with the verified sender. No such authorization or test has been completed here.
7. Only after a second explicit client-release approval may the authorized operator expand the recipient allowlist to consented clients. Keep each message manually approved; no automatic follow-up campaign is part of this change.

A CODEX continuation may add a trusted Gmail/Firebase event bridge that **only creates held/pending drafts** after verifying the actual SENT message and project/client association. It must not grant consent, choose the sender, approve, unpause, or dispatch. Preserve the archived SMS collection as read-only history; never replay it as live message intent or feed it into the live inbound handler. The current CLI intentionally requires an operator attestation; do not bypass that by running an agent as the operator.

Firebase Blaze does not itself provide an ordinary client-texting sender. No Firebase function/extension, project ID, billing budget, IAM role or secret was created/changed. If cloud execution is later selected, port the transactional outbox/unique claims/reservations to a durable transactional cloud store and prove concurrency/security rules in an emulator before deployment; **do not deploy this SQLite runtime into Cloud Functions**. Review the existing Firebase project's real services/billing configuration. Alerts-only budgets do not stop service; separately supported service spend caps and application/provider controls are distinct safeguards.

## Rollback and unresolved outcomes

Use `pause` immediately; disable any separately installed dispatcher. Retain receipts, suppression, queue and budget reservations; keep signed inbound/receipt processing active. Do not delete the DB or restore an old snapshot to retry messages, because that can remove STOP/attempt/deduplication evidence. Stop workers before `recover`. For uncertain submissions, unmatched receipts, SID collisions or conflicting provider evidence, investigate provider records manually and retain a reconciliation receipt; do not create a new send to find out whether the old one succeeded. This version does not implement a manual SID-association/resume tool. STOP resumption and ambiguous-outcome reconciliation are deliberately HUMAN-held.

## Validation receipt (2026-10-04)

42 synthetic unittest cases passed on Python 3.13.5/Linux. Standard-library-only run: 35 passed, seven optional provider cases skipped. Provider-enabled run: 42 passed, zero skipped, using the exact upstream `twilio/request_validator.py` Git blob `f7a0db361c60a3dee268f0a4923a2be78a802117`, fetched and SHA-verified in a temporary test-only import path; the helper is not vendored into this repo. Its documented signature vector, modified/forged signatures, account/number checks, callback replay, empty TwiML, mocked outbound request and no approval HTTP route were exercised. The full Twilio dependency installation, target Windows runtime, PowerShell wrapper, cloud deployment, live credentials, carrier delivery and real STOP behavior were NOT tested. All outbound HTTP calls were mocked. No live messages were sent.

Primary references reviewed:
- Twilio message creation/status: https://www.twilio.com/docs/messaging/api/message-resource
- Twilio signatures: https://www.twilio.com/docs/usage/security
- Twilio inbound/receipt behavior: https://www.twilio.com/docs/usage/webhooks/messaging-webhooks
- Firebase secrets: https://firebase.google.com/docs/functions/config-env
- Firebase billing controls: https://firebase.google.com/docs/projects/billing/avoid-surprise-bills
