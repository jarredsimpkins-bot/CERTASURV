"""Synthetic tests only; no HTTP requests, client data, or provider credentials."""
import base64
import hashlib
import hmac
import io
import json
import os
from pathlib import Path
import sqlite3
import tempfile
import threading
import unittest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch
from urllib.parse import urlencode

from messaging import Blocked, Outbox, Rejected, configuration, segments
from provider_twilio import TwilioProvider, make_app

NOW = datetime(2026, 10, 5, 15, 0, tzinfo=timezone.utc)
PHONE = "+12025550101"  # Fictional test fixture, not a configured sender/recipient.
SENDER = "+12025550102"
SID = "SM" + "1" * 32
INBOUND_SID = "SM" + "2" * 32
ACCOUNT = "AC" + "3" * 32
BODY = "CertaSurv: Your estimate was emailed. Please check your inbox. Reply STOP to opt out."
ACTOR = "test-operator"


def config(**values):
    cfg = {"operators": [ACTOR]}
    cfg.update(values)
    return cfg


def live_config(**values):
    cfg = config(mode="live", provider="twilio", sender=SENDER, account_sid=ACCOUNT,
                 allowed_recipients=[PHONE], live_release_ref="TEST-ONLY",
                 sender_verified_ref="TEST-ONLY", webhooks_verified_ref="TEST-ONLY",
                 operator_acl_ref="TEST-ONLY", status_url="https://sms.example.test/status",
                 inbound_url="https://sms.example.test/inbound", daily_messages=3,
                 recipient_daily_messages=3, daily_budget_microusd=30000,
                 monthly_budget_microusd=60000, segment_cost_bound_microusd=10000)
    cfg.update(values)
    return cfg


class FakeProvider:
    def __init__(self, error=None, before_return=None):
        self.calls = 0
        self.error = error
        self.before_return = before_return

    def send(self, payload, cfg):
        self.calls += 1
        if self.before_return:
            self.before_return()
        if self.error:
            raise self.error
        return SID, "queued"


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / "outbox.sqlite"
        self.now = NOW
        self.q = Outbox(self.path, config(), lambda: self.now)
        self.q.record_contact("test-client", PHONE, "America/New_York", "granted", "TEST-consent", ACTOR)

    def tearDown(self):
        self.q.close()
        self.temp.cleanup()

    def source(self, event="test-email"):
        return {"event_id": event, "gmail_message_id": event, "sent_at": NOW.isoformat(),
                "evidence_ref": "TEST-gmail-sent-receipt", "origin": "live"}

    def draft(self, event="test-email", **kwargs):
        return self.q.enqueue("SSD-00000", "test-client", BODY, kwargs.get("source", self.source(event)), ACTOR)

    def approve(self, mid):
        self.q.approve(mid, self.q.preview(mid, ACTOR)["approval_hash"], ACTOR)

    def live(self, **kwargs):
        self.q.config = configuration(live_config(**kwargs))
        self.q.pause(False, ACTOR)

    def test_dry_run_never_calls_provider_or_reserves_money(self):
        mid = self.draft(); self.approve(mid)
        fake = FakeProvider(error=AssertionError("must not call"))
        self.assertEqual(self.q.dispatch(mid, fake), "dry_run")
        self.assertEqual(fake.calls, 0)
        self.assertEqual(self.q.row(mid)["reserved"], 0)
        self.assertIsNone(self.q.row(mid)["sid"])

    def test_missing_approval_blocks(self):
        with self.assertRaisesRegex(Blocked, "approval"):
            self.q.dispatch(self.draft(), FakeProvider())

    def test_duplicate_event_returns_same_id(self):
        self.assertEqual(self.draft(), self.draft())
        self.assertEqual(self.q.db.execute("SELECT COUNT(*) FROM messages").fetchone()[0], 1)

    def test_same_gmail_receipt_different_event_id_cannot_duplicate(self):
        self.draft()
        source = self.source(); source["event_id"] = "different-import-id"
        with self.assertRaisesRegex(Blocked, "duplicate_event_conflict"):
            self.draft(source=source)

    def test_duplicate_changed_body_rejected(self):
        self.draft()
        with self.assertRaisesRegex(Blocked, "duplicate_event_conflict"):
            self.q.enqueue("SSD-00000", "test-client", BODY + "!", self.source(), ACTOR)

    def test_missing_consent_held(self):
        self.q.record_contact("test-client", PHONE, "America/New_York", "unknown", "", ACTOR)
        mid = self.draft()
        self.assertEqual(self.q.row(mid)["status"], "held")
        with self.assertRaisesRegex(Blocked, "consent"):
            self.approve(mid)

    def test_missing_evidence_held(self):
        source = self.source(); del source["gmail_message_id"]
        mid = self.draft(source=source)
        with self.assertRaisesRegex(Blocked, "email_evidence"):
            self.approve(mid)

    def test_archive_events_held(self):
        source = self.source(); source["origin"] = "archive"
        with self.assertRaisesRegex(Blocked, "email_evidence"):
            self.approve(self.draft(source=source))

    def test_stale_and_future_events_held(self):
        for days in (-8, 1):
            source = self.source(str(days)); source["sent_at"] = (NOW + timedelta(days=days)).isoformat()
            with self.assertRaisesRegex(Blocked, "stale_or_future"):
                self.approve(self.draft(source=source))

    def test_expired_approval(self):
        mid = self.draft(); self.approve(mid)
        self.now += timedelta(minutes=31)
        with self.assertRaisesRegex(Blocked, "approval_expired"):
            self.q.dispatch(mid, FakeProvider())

    def test_wrong_preview_hash_rejected(self):
        with self.assertRaisesRegex(Blocked, "preview_changed"):
            self.q.approve(self.draft(), "wrong", ACTOR)

    def test_message_edit_invalidates_approval(self):
        mid = self.draft(); self.approve(mid)
        self.q.revise(mid, BODY.replace("inbox", "email"), ACTOR)
        with self.assertRaisesRegex(Blocked, "approval"):
            self.q.dispatch(mid, FakeProvider())

    def test_consent_revision_invalidates_approval(self):
        mid = self.draft(); self.approve(mid)
        self.q.record_contact("test-client", PHONE, "America/New_York", "granted", "NEW-EVIDENCE", ACTOR)
        with self.assertRaisesRegex(Blocked, "approval_invalidated"):
            self.q.dispatch(mid, FakeProvider())

    def test_changed_sender_or_budget_invalidates_approval(self):
        mid = self.draft(); self.approve(mid)
        self.q.config["sender"] = SENDER
        with self.assertRaisesRegex(Blocked, "approval_invalidated"):
            self.q.dispatch(mid, FakeProvider())

    def test_dry_run_cannot_be_promoted_without_fresh_approval(self):
        mid = self.draft(); self.approve(mid); self.q.dispatch(mid)
        self.live()
        with self.assertRaisesRegex(Blocked, "approval"):
            self.q.dispatch(mid, FakeProvider())
        self.approve(mid)
        self.assertEqual(self.q.dispatch(mid, FakeProvider()), "queued")

    def test_live_release_gate(self):
        self.live(live_release_ref="")
        mid = self.draft(); self.approve(mid)
        with self.assertRaisesRegex(Blocked, "live_release_ref"):
            self.q.dispatch(mid, FakeProvider())

    def test_global_kill(self):
        self.live(); mid = self.draft(); self.approve(mid); self.q.pause(True, ACTOR)
        with self.assertRaisesRegex(Blocked, "global_pause"):
            self.q.dispatch(mid, FakeProvider())

    def test_live_missing_secret_blocks_before_reservation(self):
        self.live(); mid = self.draft(); self.approve(mid)
        with patch.dict(os.environ, {"TWILIO_AUTH_TOKEN": ""}):
            with self.assertRaisesRegex(Blocked, "secret_missing"):
                self.q.dispatch(mid)
        self.assertIsNone(self.q.row(mid)["attempt"])

    def test_no_live_recipient_outside_allowlist(self):
        self.live(allowed_recipients=[]); mid = self.draft(); self.approve(mid)
        with self.assertRaisesRegex(Blocked, "not_allowlisted"):
            self.q.dispatch(mid, FakeProvider())

    def test_quiet_hours(self):
        self.live(start_hour=16, end_hour=17); mid = self.draft(); self.approve(mid)
        with self.assertRaisesRegex(Blocked, "send_window"):
            self.q.dispatch(mid, FakeProvider())

    def test_daily_budget_reservations_and_no_retry(self):
        self.live(daily_budget_microusd=10000)
        first = self.draft(); self.approve(first)
        fake = FakeProvider(error=TimeoutError("sensitive provider error"))
        self.assertEqual(self.q.dispatch(first, fake), "uncertain")
        with self.assertRaises(Blocked):
            self.q.dispatch(first, fake)
        second = self.draft("second"); self.approve(second)
        with self.assertRaisesRegex(Blocked, "budget_or_rate"):
            self.q.dispatch(second, FakeProvider())
        self.assertEqual(fake.calls, 1)
        self.assertEqual(self.q.row(first)["reserved"], 10000)

    def test_monthly_cap(self):
        self.live(monthly_budget_microusd=9999)
        mid = self.draft(); self.approve(mid)
        with self.assertRaisesRegex(Blocked, "budget_or_rate"):
            self.q.dispatch(mid, FakeProvider())

    def test_per_recipient_cap(self):
        self.live(recipient_daily_messages=1)
        mid = self.draft(); self.approve(mid); self.q.dispatch(mid, FakeProvider())
        next_id = self.draft("second"); self.approve(next_id)
        with self.assertRaisesRegex(Blocked, "budget_or_rate"):
            self.q.dispatch(next_id, FakeProvider())

    def test_rejection_retains_reservation_and_no_automatic_retry(self):
        self.live(); mid = self.draft(); self.approve(mid)
        self.assertEqual(self.q.dispatch(mid, FakeProvider(error=Rejected())), "failed")
        self.assertEqual(self.q.row(mid)["reserved"], 10000)
        with self.assertRaises(Blocked):
            self.approve(mid)

    def test_receipt_replay_order_and_identity(self):
        self.live(); mid = self.draft(); self.approve(mid); self.q.dispatch(mid, FakeProvider())
        fields = {"MessageSid": SID, "MessageStatus": "delivered", "To": PHONE, "From": SENDER}
        self.q.receipt({**fields, "To": SENDER})
        self.assertEqual(self.q.row(mid)["status"], "queued")
        self.q.receipt(fields); self.q.receipt(fields)
        self.q.receipt({**fields, "MessageStatus": "sent"})
        self.assertEqual(self.q.row(mid)["status"], "delivered")
        count = self.q.db.execute("SELECT COUNT(*) FROM audit WHERE event='DELIVERY_RECEIPT'").fetchone()[0]
        self.assertEqual(count, 1)

    def test_callback_before_post_response(self):
        self.live(); mid = self.draft(); self.approve(mid)
        callback = lambda: self.q.receipt({"MessageSid": SID, "MessageStatus": "delivered", "To": PHONE, "From": SENDER})
        self.assertEqual(self.q.dispatch(mid, FakeProvider(before_return=callback)), "delivered")

    def test_stop_and_reply_block_all_future_messages(self):
        for i, text in enumerate(("stop", "Please call me", "START")):
            self.q.inbound({"MessageSid": "SM" + str(i + 4) * 32, "From": PHONE, "Body": text})
            with self.assertRaisesRegex(Blocked, "suppressed"):
                self.approve(self.draft(str(i)))
        self.assertEqual(self.q.db.execute("SELECT reason FROM suppression WHERE phone=?", (PHONE,)).fetchone()[0], "opt_out")

    def test_inbound_replay_idempotent_and_revokes_approval(self):
        mid = self.draft(); self.approve(mid)
        fields = {"MessageSid": INBOUND_SID, "From": PHONE, "Body": "STOP"}
        self.q.inbound(fields); self.q.inbound(fields)
        self.assertEqual(self.q.db.execute("SELECT COUNT(*) FROM inbound").fetchone()[0], 1)
        with self.assertRaises(Blocked):
            self.q.dispatch(mid, FakeProvider())

    def test_reimported_consent_does_not_clear_stop(self):
        self.q.inbound({"MessageSid": INBOUND_SID, "From": PHONE, "Body": "STOP"})
        self.q.record_contact("test-client", PHONE, "America/New_York", "granted", "reimport", ACTOR)
        with self.assertRaisesRegex(Blocked, "suppressed"):
            self.approve(self.draft())

    def test_recovery_never_requeues_interrupted_send(self):
        mid = self.draft()
        self.q.db.execute("UPDATE messages SET status='submitting',attempt='test-attempt',reserved=10000 WHERE id=?", (mid,))
        self.q.recover(ACTOR)
        self.assertEqual(self.q.row(mid)["status"], "uncertain")
        self.assertEqual(self.q.row(mid)["reserved"], 10000)
        with self.assertRaises(Blocked):
            self.approve(mid)

    def test_audit_append_only_and_no_body_or_phone(self):
        mid = self.draft(); self.approve(mid); self.q.dispatch(mid)
        data = json.dumps([tuple(row) for row in self.q.db.execute("SELECT * FROM audit")])
        self.assertNotIn(PHONE, data); self.assertNotIn(BODY, data)
        with self.assertRaises(sqlite3.IntegrityError):
            self.q.db.execute("DELETE FROM audit")

    def test_persistence_restart(self):
        mid = self.draft(); self.approve(mid)
        self.q.close(); self.q = Outbox(self.path, config(), lambda: NOW)
        self.assertEqual(self.q.dispatch(mid), "dry_run")

    def test_concurrent_workers_only_one_provider_attempt(self):
        self.live(); mid = self.draft(); self.approve(mid)
        fake = FakeProvider(); outcomes = []
        def work():
            q = Outbox(self.path, live_config(), lambda: NOW)
            try:
                outcomes.append(q.dispatch(mid, fake))
            except Blocked:
                outcomes.append("blocked")
            finally:
                q.close()
        threads = [threading.Thread(target=work) for _ in range(2)]
        for t in threads: t.start()
        for t in threads: t.join()
        self.assertEqual(fake.calls, 1)
        self.assertCountEqual(outcomes, ["queued", "blocked"])

    def test_unauthorized_operator(self):
        with self.assertRaisesRegex(Blocked, "operator"):
            self.q.approve(self.draft(), "hash", "agent")

    def test_validation(self):
        for cfg in ({"mode": "LIVE"}, {"max_segments": True}, {"daily_messages": -1}, {"unknown": 1}):
            with self.assertRaises(Blocked): configuration(cfg)
        with self.assertRaises(Blocked): Outbox("relative.db", {})
        with self.assertRaises(Blocked): segments("bad\x00body")
        self.assertEqual(segments("a" * 160), 1)
        self.assertEqual(segments("a" * 161), 2)
        self.assertEqual(segments("^" * 80), 1)
        self.assertEqual(segments("^" * 81), 2)
        self.assertEqual(segments("🙂" * 35), 1)
        self.assertEqual(segments("🙂" * 36), 2)


try:
    from twilio.request_validator import RequestValidator
except ImportError:
    RequestValidator = None


@unittest.skipIf(RequestValidator is None, "optional official Twilio validator not installed")
class WebhookTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.cfg = live_config()
        self.q = Outbox(Path(self.temp.name) / "test.db", self.cfg, lambda: NOW)
        self.secret_patch = patch.dict(os.environ, {"TWILIO_AUTH_TOKEN": "test-only-not-a-credential-32chars"})
        self.secret_patch.start()
        self.p = TwilioProvider(self.q.config)
        self.fields = {"AccountSid": ACCOUNT, "MessageSid": INBOUND_SID,
                       "From": PHONE, "To": SENDER, "Body": "STOP"}

    def tearDown(self):
        self.q.close(); self.secret_patch.stop(); self.temp.cleanup()

    def signature(self, fields=None):
        return self.p.validator.compute_signature(self.cfg["inbound_url"], fields or self.fields)

    def test_official_published_signature_vector(self):
        params = {"CallSid": "CA1234567890ABCDE", "Caller": "+14158675310", "Digits": "1234",
                  "From": "+14158675310", "To": "+18005551212"}
        self.assertTrue(RequestValidator("12345").validate("https://example.com/myapp.php?foo=1&bar=2", params, "L/OH5YylLD5NRKLltdqwSvS0BnU="))

    def test_valid_signed_stop_and_replay(self):
        raw = urlencode(self.fields).encode()
        for _ in range(2): self.p.webhook(self.q, "/inbound", self.signature(), raw)
        self.assertEqual(self.q.db.execute("SELECT COUNT(*) FROM inbound").fetchone()[0], 1)
        self.assertEqual(self.q.db.execute("SELECT reason FROM suppression").fetchone()[0], "opt_out")

    def test_forged_or_modified_callback_has_no_effect(self):
        for signature, raw in (("fake", urlencode(self.fields).encode()),
                               (self.signature(), urlencode({**self.fields, "From": SENDER}).encode())):
            with self.assertRaisesRegex(Blocked, "signature"):
                self.p.webhook(self.q, "/inbound", signature, raw)
        self.assertEqual(self.q.db.execute("SELECT COUNT(*) FROM suppression").fetchone()[0], 0)

    def test_duplicate_fields_and_wrong_route_rejected(self):
        raw = urlencode(self.fields).encode()
        with self.assertRaises(Blocked): self.p.webhook(self.q, "/inbound", self.signature(), raw + b"&Body=START")
        with self.assertRaises(Blocked): self.p.webhook(self.q, "/other", self.signature(), raw)

    def test_account_and_number_binding(self):
        for key, value in (("AccountSid", "AC" + "4" * 32), ("To", PHONE)):
            fields = {**self.fields, key: value}
            with self.assertRaisesRegex(Blocked, "mismatch"):
                self.p.webhook(self.q, "/inbound", self.signature(fields), urlencode(fields).encode())

    def test_provider_transport_is_single_post_and_status_not_delivered(self):
        response = unittest.mock.MagicMock()
        response.__enter__.return_value = response
        response.status = 201
        response.read.return_value = json.dumps({"sid": SID, "status": "queued"}).encode()
        opener = unittest.mock.MagicMock(); opener.open.return_value = response
        with patch("provider_twilio.build_opener", return_value=opener):
            self.assertEqual(self.p.send({"to": PHONE, "body": BODY}, self.q.config), (SID, "queued"))
        self.assertEqual(opener.open.call_count, 1)
        request = opener.open.call_args.args[0]
        self.assertEqual(request.method, "POST")
        self.assertIn("StatusCallback", request.data.decode())

    def test_wsgi_no_approval_route_no_automatic_reply(self):
        cfg = Path(self.temp.name) / "cfg.json"; cfg.write_text(json.dumps(self.cfg))
        app = make_app(str(cfg), str(Path(self.temp.name) / "test.db"))
        raw = urlencode(self.fields).encode(); status = []
        env = {"REQUEST_METHOD": "POST", "CONTENT_TYPE": "application/x-www-form-urlencoded",
               "CONTENT_LENGTH": str(len(raw)), "wsgi.input": io.BytesIO(raw), "PATH_INFO": "/inbound",
               "HTTP_X_TWILIO_SIGNATURE": self.signature(), "HTTP_HOST": "attacker.test"}
        result = app(env, lambda code, headers: status.append(code))
        self.assertEqual(status, ["200 OK"])
        self.assertEqual(result, [b"<Response></Response>"])
        env["PATH_INFO"] = "/approve"; env["wsgi.input"] = io.BytesIO(raw); status.clear()
        app(env, lambda code, headers: status.append(code))
        self.assertEqual(status, ["403 Forbidden"])


if __name__ == "__main__":
    unittest.main()
