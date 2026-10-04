"""Local Certa control-plane outbox. No scheduler, public approval API, or implicit send."""
from __future__ import annotations

import hashlib
import hmac
import json
import re
import sqlite3
import uuid
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Callable, Protocol
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

UTC = timezone.utc
PHONE = re.compile(r"\+[1-9][0-9]{7,14}\Z")
SID = re.compile(r"SM[0-9a-fA-F]{32}\Z")
TERMINAL = {"delivered", "failed", "undelivered", "canceled"}
RANK = {"accepted": 0, "queued": 1, "sending": 2, "sent": 3,
        "delivered": 4, "failed": 4, "undelivered": 4, "canceled": 4}
STOP = {"STOP", "STOPALL", "UNSUBSCRIBE", "CANCEL", "END", "QUIT", "REVOKE", "OPT OUT"}
GSM = set("@£$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !\"#¤%&'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà")
EXT = set("\f^{}\\[~]|€")
DEFAULTS = {
    "mode": "dry_run", "provider": "none", "operators": [], "allowed_recipients": [],
    "sender": "", "account_sid": "", "status_url": "", "inbound_url": "",
    "live_release_ref": "", "sender_verified_ref": "", "webhooks_verified_ref": "",
    "operator_acl_ref": "", "daily_messages": 0, "recipient_daily_messages": 1,
    "daily_budget_microusd": 0, "monthly_budget_microusd": 0,
    "segment_cost_bound_microusd": 0, "max_segments": 1, "approval_minutes": 30,
    "start_hour": 9, "end_hour": 17, "weekdays": [0, 1, 2, 3, 4],
}


class Blocked(ValueError):
    """Safe, non-PII reason code suitable for operator output."""


class Rejected(Exception):
    """Provider definitely rejected submission. No automatic retry is permitted."""


class Provider(Protocol):
    def send(self, message: dict, config: dict) -> tuple[str, str]: ...


def canonical(value: object) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def digest(value: object) -> str:
    return hashlib.sha256(canonical(value).encode()).hexdigest()


def timestamp(value: str) -> datetime:
    dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if dt.tzinfo is None:
        raise ValueError("timezone_required")
    return dt.astimezone(UTC)


def segments(body: str) -> int:
    if not body or any(ord(c) < 32 and c not in "\r\n\f" for c in body):
        raise Blocked("invalid_body")
    if all(c in GSM or c in EXT for c in body):
        units = sum(2 if c in EXT else 1 for c in body)
        return 1 if units <= 160 else (units + 152) // 153
    try:
        units = len(body.encode("utf-16-be")) // 2
    except UnicodeError as exc:
        raise Blocked("invalid_unicode") from exc
    return 1 if units <= 70 else (units + 66) // 67


def configuration(value: dict) -> dict:
    if not isinstance(value, dict) or set(value) - set(DEFAULTS):
        raise Blocked("unknown_configuration")
    cfg = {**DEFAULTS, **json.loads(canonical(value))}
    if cfg["mode"] not in {"dry_run", "live"} or cfg["provider"] not in {"none", "twilio"}:
        raise Blocked("invalid_mode_or_provider")
    for key, default in DEFAULTS.items():
        if type(cfg[key]) is not type(default):
            raise Blocked("invalid_configuration_type")
        if isinstance(default, int) and cfg[key] < 0:
            raise Blocked("negative_configuration")
    for key in ("operators", "allowed_recipients"):
        if any(not isinstance(v, str) or not v for v in cfg[key]):
            raise Blocked("invalid_allowlist")
    if any(not PHONE.fullmatch(v) for v in cfg["allowed_recipients"]):
        raise Blocked("invalid_allowlisted_phone")
    if not (1 <= cfg["approval_minutes"] <= 120 and 1 <= cfg["max_segments"] <= 3
            and 0 <= cfg["start_hour"] < cfg["end_hour"] <= 24):
        raise Blocked("invalid_limits")
    if not cfg["weekdays"] or any(type(v) is not int or v not in range(7) for v in cfg["weekdays"]):
        raise Blocked("invalid_weekdays")
    return cfg


class Outbox:
    """One SQLite database on one local persistent disk; never a shared/network drive.

    Callers are trusted local processes. Only cli.py provides an operator interface.
    Filesystem ACLs and separate human/agent accounts are part of the release gate.
    """
    def __init__(self, database: str | Path, config: dict,
                 clock: Callable[[], datetime] | None = None):
        self.config = configuration(config)
        self.clock = clock or (lambda: datetime.now(UTC))
        path = Path(database).expanduser()
        if not path.is_absolute() or Path(__file__).resolve().parent in path.resolve().parents:
            raise Blocked("runtime_database_must_be_external_absolute_path")
        if any((p / ".git").exists() for p in path.resolve().parents):
            raise Blocked("runtime_database_must_not_be_in_git_checkout")
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.db = sqlite3.connect(path, timeout=15, isolation_level=None)
        self.db.row_factory = sqlite3.Row
        self.db.execute("PRAGMA journal_mode=WAL")
        self.db.execute("PRAGMA synchronous=FULL")
        self.db.executescript("""
        CREATE TABLE IF NOT EXISTS control(id INTEGER PRIMARY KEY CHECK(id=1), paused INTEGER NOT NULL);
        INSERT OR IGNORE INTO control VALUES(1,1);
        CREATE TABLE IF NOT EXISTS contacts(id TEXT PRIMARY KEY, record TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS suppression(phone TEXT PRIMARY KEY, reason TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS messages(
          id TEXT PRIMARY KEY, dedupe TEXT UNIQUE NOT NULL, payload TEXT NOT NULL,
          status TEXT NOT NULL, approval TEXT, approver TEXT, expires TEXT,
          attempt TEXT, sid TEXT UNIQUE, reserved INTEGER NOT NULL DEFAULT 0,
          day TEXT, month TEXT, phone_hash TEXT, sender TEXT, error TEXT);
        CREATE TABLE IF NOT EXISTS audit(
          seq INTEGER PRIMARY KEY, at TEXT NOT NULL, message_id TEXT, event TEXT NOT NULL, detail TEXT NOT NULL);
        CREATE TRIGGER IF NOT EXISTS audit_no_update BEFORE UPDATE ON audit
          BEGIN SELECT RAISE(ABORT,'append_only_audit'); END;
        CREATE TRIGGER IF NOT EXISTS audit_no_delete BEFORE DELETE ON audit
          BEGIN SELECT RAISE(ABORT,'append_only_audit'); END;
        CREATE TABLE IF NOT EXISTS receipts(
          seq INTEGER PRIMARY KEY, fingerprint TEXT UNIQUE NOT NULL, sid TEXT NOT NULL,
          status TEXT NOT NULL, to_hash TEXT NOT NULL, from_hash TEXT NOT NULL, error TEXT, received_at TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS inbound(sid TEXT PRIMARY KEY, received_at TEXT NOT NULL);
        """)
        if __import__("os").name != "nt":
            path.chmod(0o600)

    def close(self):
        self.db.close()

    @contextmanager
    def transaction(self):
        self.db.execute("BEGIN IMMEDIATE")
        try:
            yield
        except BaseException:
            self.db.execute("ROLLBACK")
            raise
        else:
            self.db.execute("COMMIT")

    def operator(self, actor: str):
        if not actor or actor not in self.config["operators"]:
            raise Blocked("operator_not_authorized")

    def event(self, mid: str | None, event: str, detail: dict | None = None):
        # No message bodies, phone numbers, credentials, or raw provider exceptions.
        self.db.execute("INSERT INTO audit(at,message_id,event,detail) VALUES(?,?,?,?)",
                        (self.clock().isoformat(), mid, event, canonical(detail or {})))

    def contact(self, client_id: str) -> dict:
        row = self.db.execute("SELECT record FROM contacts WHERE id=?", (client_id,)).fetchone()
        return json.loads(row[0]) if row else {}

    def record_contact(self, client_id: str, phone: str, timezone_name: str,
                       consent: str, evidence_ref: str, actor: str):
        self.operator(actor)
        if not client_id or not PHONE.fullmatch(phone) or consent not in {"unknown", "granted", "revoked"}:
            raise Blocked("invalid_contact")
        try:
            ZoneInfo(timezone_name)
        except (ZoneInfoNotFoundError, ValueError):
            raise Blocked("invalid_recipient_timezone") from None
        if consent == "granted" and not evidence_ref.strip():
            raise Blocked("consent_evidence_required")
        with self.transaction():
            record = {"phone": phone, "timezone": timezone_name, "consent": consent,
                      "evidence_ref": evidence_ref, "recorded_by": actor,
                      "recorded_at": self.clock().isoformat(),
                      "revision": self.contact(client_id).get("revision", 0) + 1}
            self.db.execute("INSERT OR REPLACE INTO contacts VALUES(?,?)", (client_id, canonical(record)))
            # This never clears STOP or reply suppression, including for a reimported client.
            if consent == "revoked":
                self.db.execute("INSERT OR REPLACE INTO suppression VALUES(?,?)", (phone, "consent_revoked"))
            self.event(None, "CONTACT_RECORDED", {"client_id": client_id, "revision": record["revision"]})

    def enqueue(self, project_id: str, client_id: str, body: str, source: dict, actor: str) -> str:
        self.operator(actor)
        if not re.fullmatch(r"SSD-\d{5}(?:[- ].*)?", project_id) or not client_id or not isinstance(source, dict):
            raise Blocked("project_client_and_source_required")
        if not isinstance(body, str) or len(body) > 2000:
            raise Blocked("invalid_body")
        # Gmail SENT evidence is attested by this operator, not inferred from a draft/email subject.
        permitted = {"event_id", "gmail_message_id", "sent_at", "evidence_ref", "origin"}
        if set(source) - permitted or not isinstance(source.get("event_id"), str) or not source["event_id"]:
            raise Blocked("source_event_required")
        if any(not isinstance(v, str) for v in source.values()):
            raise Blocked("invalid_source")
        key = digest([project_id, client_id, "estimate_emailed", source.get("gmail_message_id") or source["event_id"]])
        with self.transaction():
            existing = self.db.execute("SELECT * FROM messages WHERE dedupe=?", (key,)).fetchone()
            contact = self.contact(client_id)
            payload = {"project_id": project_id, "client_id": client_id, "purpose": "estimate_emailed",
                       "to": contact.get("phone", ""), "body": body, "source": source,
                       "source_attested_by": actor}
            if existing:
                old = json.loads(existing["payload"])
                if any(old[k] != payload[k] for k in ("project_id", "client_id", "to", "body", "source")):
                    raise Blocked("duplicate_event_conflict_use_revise")
                return existing["id"]
            mid = str(uuid.uuid4())
            state = "held" if self.reasons(payload) else "pending_approval"
            self.db.execute("INSERT INTO messages(id,dedupe,payload,status) VALUES(?,?,?,?)",
                            (mid, key, canonical(payload), state))
            self.event(mid, "DRAFT_CREATED", {"project_id": project_id, "client_id": client_id,
                                             "payload_hash": digest(payload), "status": state})
            return mid

    def row(self, mid: str):
        row = self.db.execute("SELECT * FROM messages WHERE id=?", (mid,)).fetchone()
        if not row:
            raise Blocked("message_not_found")
        return row

    def reasons(self, payload: dict) -> list[str]:
        reasons = []
        contact = self.contact(payload["client_id"])
        if not PHONE.fullmatch(payload["to"]) or contact.get("phone") != payload["to"]:
            reasons.append("recipient_missing_or_changed")
        if contact.get("consent") != "granted" or not contact.get("evidence_ref"):
            reasons.append("consent_missing_or_revoked")
        if self.db.execute("SELECT 1 FROM suppression WHERE phone=?", (payload["to"],)).fetchone():
            reasons.append("recipient_suppressed")
        source = payload["source"]
        if (source.get("origin") != "live" or not source.get("gmail_message_id")
                or not source.get("evidence_ref") or payload["source_attested_by"] not in self.config["operators"]):
            reasons.append("confirmed_live_email_evidence_required")
        try:
            age = self.clock() - timestamp(source["sent_at"])
            if not timedelta(0) <= age <= timedelta(days=7):
                reasons.append("stale_or_future_email_event")
        except (KeyError, TypeError, ValueError):
            reasons.append("email_timestamp_required")
        if not payload["body"].startswith("CertaSurv:") or "Reply STOP to opt out." not in payload["body"]:
            reasons.append("identity_and_optout_text_required")
        try:
            if segments(payload["body"]) > self.config["max_segments"]:
                reasons.append("segment_limit")
        except Blocked as exc:
            reasons.append(str(exc))
        try:
            ZoneInfo(contact["timezone"])
        except (KeyError, ZoneInfoNotFoundError, ValueError):
            reasons.append("recipient_timezone_required")
        return reasons

    def approval_hash(self, payload: dict) -> str:
        return digest({"payload": payload, "contact": self.contact(payload["client_id"]), "policy": self.config})

    def preview(self, mid: str, actor: str) -> dict:
        self.operator(actor)
        row = self.row(mid)
        payload = json.loads(row["payload"])
        return {"id": mid, "status": row["status"], "message": payload,
                "mode": self.config["mode"], "sender": self.config["sender"],
                "approval_hash": self.approval_hash(payload), "holds": self.reasons(payload)}

    def revise(self, mid: str, body: str, actor: str):
        self.operator(actor)
        if not isinstance(body, str) or len(body) > 2000:
            raise Blocked("invalid_body")
        with self.transaction():
            row = self.row(mid)
            if row["attempt"]:
                raise Blocked("attempt_already_exists")
            payload = json.loads(row["payload"])
            payload["body"] = body
            payload["to"] = self.contact(payload["client_id"]).get("phone", "")
            self.db.execute("UPDATE messages SET payload=?,status='pending_approval',approval=NULL,approver=NULL,expires=NULL WHERE id=?",
                            (canonical(payload), mid))
            self.event(mid, "DRAFT_REVISED", {"payload_hash": digest(payload)})

    def approve(self, mid: str, expected_hash: str, actor: str):
        self.operator(actor)
        with self.transaction():
            row = self.row(mid)
            payload = json.loads(row["payload"])
            if row["attempt"] or row["status"] not in {"held", "pending_approval", "dry_run", "approved"}:
                raise Blocked("message_not_approvable")
            problems = self.reasons(payload)
            if problems:
                raise Blocked(",".join(problems))
            fingerprint = self.approval_hash(payload)
            if not hmac.compare_digest(fingerprint, expected_hash):
                raise Blocked("preview_changed")
            expires = self.clock() + timedelta(minutes=self.config["approval_minutes"])
            self.db.execute("UPDATE messages SET status='approved',approval=?,approver=?,expires=? WHERE id=?",
                            (fingerprint, actor, expires.isoformat(), mid))
            self.event(mid, "HUMAN_APPROVED", {"actor": actor, "approval_hash": fingerprint,
                                               "mode": self.config["mode"]})

    def pause(self, paused: bool, actor: str):
        self.operator(actor)
        if type(paused) is not bool:
            raise Blocked("invalid_pause")
        with self.transaction():
            self.db.execute("UPDATE control SET paused=? WHERE id=1", (int(paused),))
            self.event(None, "GLOBAL_PAUSE" if paused else "GLOBAL_UNPAUSE", {"actor": actor})

    def send_checks(self, row, live: bool):
        payload = json.loads(row["payload"])
        if (row["status"] != "approved" or row["attempt"] or not row["approval"]
                or row["approver"] not in self.config["operators"]):
            raise Blocked("exact_human_approval_required")
        if timestamp(row["expires"]) <= self.clock():
            raise Blocked("approval_expired")
        if not hmac.compare_digest(row["approval"], self.approval_hash(payload)):
            raise Blocked("approval_invalidated")
        problems = self.reasons(payload)
        if problems:
            raise Blocked(",".join(problems))
        if live:
            cfg = self.config
            if self.db.execute("SELECT paused FROM control WHERE id=1").fetchone()[0]:
                raise Blocked("global_pause")
            for key in ("live_release_ref", "sender_verified_ref", "webhooks_verified_ref", "operator_acl_ref"):
                if not cfg[key].strip():
                    raise Blocked(key + "_required")
            if cfg["provider"] == "none" or not PHONE.fullmatch(cfg["sender"]):
                raise Blocked("verified_provider_sender_required")
            if payload["to"] not in cfg["allowed_recipients"]:
                raise Blocked("recipient_not_allowlisted")
            local = self.clock().astimezone(ZoneInfo(self.contact(payload["client_id"])["timezone"]))
            if local.weekday() not in cfg["weekdays"] or not cfg["start_hour"] <= local.hour < cfg["end_hour"]:
                raise Blocked("outside_recipient_send_window")
        return payload

    def dispatch(self, mid: str, provider: Provider | None = None) -> str:
        live = self.config["mode"] == "live"
        with self.transaction():
            row = self.row(mid)
            payload = self.send_checks(row, live)
            if not live:
                self.db.execute("UPDATE messages SET status='dry_run',approval=NULL WHERE id=?", (mid,))
                self.event(mid, "DRY_RUN", {"payload_hash": digest(payload), "provider_called": False})
                return "dry_run"
            if provider is None:
                # Import/credential validation happens before any reservation or network request.
                from provider_twilio import TwilioProvider
                provider = TwilioProvider(self.config)
            cfg = self.config
            if any(cfg[k] <= 0 for k in ("daily_messages", "recipient_daily_messages", "daily_budget_microusd",
                                        "monthly_budget_microusd", "segment_cost_bound_microusd")):
                raise Blocked("positive_spend_limits_required")
            reserve = segments(payload["body"]) * cfg["segment_cost_bound_microusd"]
            now = self.clock().astimezone(UTC)
            day, month, ph = now.strftime("%Y-%m-%d"), now.strftime("%Y-%m"), digest(payload["to"])
            daily = self.db.execute("SELECT COUNT(*),COALESCE(SUM(reserved),0) FROM messages WHERE day=? AND attempt IS NOT NULL", (day,)).fetchone()
            monthly = self.db.execute("SELECT COALESCE(SUM(reserved),0) FROM messages WHERE month=?", (month,)).fetchone()[0]
            count = self.db.execute("SELECT COUNT(*) FROM messages WHERE day=? AND phone_hash=? AND attempt IS NOT NULL", (day, ph)).fetchone()[0]
            if (daily[0] >= cfg["daily_messages"] or count >= cfg["recipient_daily_messages"]
                    or daily[1] + reserve > cfg["daily_budget_microusd"]
                    or monthly + reserve > cfg["monthly_budget_microusd"]):
                raise Blocked("budget_or_rate_limit")
            self.db.execute("UPDATE messages SET status='submitting',attempt=?,reserved=?,day=?,month=?,phone_hash=?,sender=? WHERE id=?",
                            (str(uuid.uuid4()), reserve, day, month, ph, cfg["sender"], mid))
            self.event(mid, "SUBMISSION_RESERVED", {"reserved_microusd": reserve})
        # Last local STOP/kill check. After this boundary an in-flight SMS cannot be recalled.
        with self.transaction():
            if (self.db.execute("SELECT paused FROM control WHERE id=1").fetchone()[0]
                    or self.reasons(payload) or self.approval_hash(payload) != row["approval"]):
                self.db.execute("UPDATE messages SET status='canceled',error='preflight_hold' WHERE id=?", (mid,))
                self.event(mid, "PREFLIGHT_CANCELED")
                return "canceled"
        try:
            sid, status = provider.send(payload, self.config)
            if not SID.fullmatch(sid) or status not in RANK:
                raise ValueError("invalid_provider_response")
        except Exception as exc:
            # Never store exception text: an SDK error can include credentials or client content.
            state = "failed" if isinstance(exc, Rejected) else "uncertain"
            with self.transaction():
                self.db.execute("UPDATE messages SET status=?,error=? WHERE id=?", (state, state, mid))
                self.event(mid, "SUBMISSION_" + state.upper())
            return state
        with self.transaction():
            self.db.execute("UPDATE messages SET sid=?,status=? WHERE id=?", (sid, status, mid))
            self.event(mid, "PROVIDER_ACCEPTED", {"sid": sid, "status": status})
            self.apply_receipts(mid)
        return self.row(mid)["status"]

    def recover(self, actor: str):
        """Only while workers are stopped. Never resend an orphaned submitting attempt."""
        self.operator(actor)
        with self.transaction():
            for row in self.db.execute("SELECT id FROM messages WHERE status='submitting'").fetchall():
                self.db.execute("UPDATE messages SET status='uncertain',error='worker_interrupted' WHERE id=?", (row[0],))
                self.event(row[0], "INTERRUPTED_REQUIRES_RECONCILIATION")

    def receipt(self, fields: dict):
        """Trusted adapter only: authentication must happen before this method."""
        sid, state = fields.get("MessageSid", ""), fields.get("MessageStatus", "")
        if not SID.fullmatch(sid) or state not in RANK:
            raise Blocked("invalid_receipt")
        to_hash, from_hash = digest(fields.get("To", "")), digest(fields.get("From", ""))
        error = str(fields.get("ErrorCode", ""))
        error = error if re.fullmatch(r"\d{0,6}", error) else "redacted"
        fingerprint = digest([sid, state, to_hash, from_hash, error])
        with self.transaction():
            changed = self.db.execute("INSERT OR IGNORE INTO receipts(fingerprint,sid,status,to_hash,from_hash,error,received_at) VALUES(?,?,?,?,?,?,?)",
                                      (fingerprint, sid, state, to_hash, from_hash, error, self.clock().isoformat())).rowcount
            if not changed:
                return
            row = self.db.execute("SELECT id FROM messages WHERE sid=?", (sid,)).fetchone()
            if row:
                self.event(row[0], "RECEIPT_RECORDED", {"sid": sid, "status": state})
                self.apply_receipts(row[0])
            else:
                self.event(None, "EARLY_OR_UNMATCHED_RECEIPT", {"sid": sid, "status": state})

    def apply_receipts(self, mid: str):
        row = self.row(mid)
        payload = json.loads(row["payload"])
        for receipt in self.db.execute("SELECT * FROM receipts WHERE sid=? ORDER BY seq", (row["sid"],)).fetchall():
            if receipt["to_hash"] != digest(payload["to"]) or receipt["from_hash"] != digest(row["sender"]):
                self.event(mid, "RECEIPT_IDENTITY_MISMATCH")
                continue
            old, new = self.row(mid)["status"], receipt["status"]
            if old in TERMINAL or RANK.get(old, -1) > RANK[new]:
                continue
            if old != new:
                self.db.execute("UPDATE messages SET status=?,error=? WHERE id=?", (new, receipt["error"], mid))
                self.event(mid, "DELIVERY_RECEIPT", {"sid": row["sid"], "status": new})

    def inbound(self, fields: dict):
        """Trusted, authenticated, live inbound adapter only. Never import SMS archives here."""
        sid, phone = fields.get("MessageSid", ""), fields.get("From", "")
        if not SID.fullmatch(sid) or not PHONE.fullmatch(phone):
            raise Blocked("invalid_inbound")
        text = fields.get("Body", "").strip().upper()
        reason = "opt_out" if text in STOP or fields.get("OptOutType") == "STOP" else "reply_pause"
        with self.transaction():
            if not self.db.execute("INSERT OR IGNORE INTO inbound VALUES(?,?)", (sid, self.clock().isoformat())).rowcount:
                return
            previous = self.db.execute("SELECT reason FROM suppression WHERE phone=?", (phone,)).fetchone()
            if not previous or reason == "opt_out":
                self.db.execute("INSERT OR REPLACE INTO suppression VALUES(?,?)", (phone, reason))
            for row in self.db.execute("SELECT id,payload FROM messages WHERE attempt IS NULL").fetchall():
                if json.loads(row["payload"])["to"] == phone:
                    self.db.execute("UPDATE messages SET status='held',approval=NULL WHERE id=?", (row["id"],))
            self.event(None, "INBOUND_SUPPRESSED", {"sid": sid, "phone_hash": digest(phone), "reason": reason})
