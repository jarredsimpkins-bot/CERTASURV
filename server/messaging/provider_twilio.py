"""Optional Twilio transport. Selecting this code does not acquire or move a number."""
from __future__ import annotations

import base64
import json
import os
import re
from urllib.error import HTTPError
from urllib.parse import parse_qsl, urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

from messaging import Blocked, Outbox, PHONE, Rejected


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise HTTPError(req.full_url, code, "redirect_refused", headers, fp)


class TwilioProvider:
    def __init__(self, config: dict):
        self.config = config
        if config["provider"] != "twilio" or not re.fullmatch(r"AC[0-9a-fA-F]{32}", config["account_sid"]):
            raise Blocked("twilio_account_not_configured")
        if not PHONE.fullmatch(config["sender"]):
            raise Blocked("twilio_sender_not_configured")
        for key in ("status_url", "inbound_url"):
            url = urlsplit(config[key])
            if (url.scheme != "https" or not url.hostname or url.username or url.password
                    or url.fragment or not url.path):
                raise Blocked("https_callback_urls_required")
        if config["status_url"] == config["inbound_url"]:
            raise Blocked("distinct_callback_routes_required")
        self.token = os.environ.get("TWILIO_AUTH_TOKEN", "")
        if len(self.token) < 20:
            raise Blocked("twilio_secret_missing")
        try:
            from twilio.request_validator import RequestValidator
        except ImportError:
            raise Blocked("official_twilio_validator_dependency_required") from None
        self.validator = RequestValidator(self.token)

    def send(self, message: dict, config: dict) -> tuple[str, str]:
        account = config["account_sid"]
        url = f"https://api.twilio.com/2010-04-01/Accounts/{account}/Messages.json"
        data = urlencode({"To": message["to"], "From": config["sender"],
                          "Body": message["body"], "StatusCallback": config["status_url"]}).encode()
        auth = base64.b64encode(f"{account}:{self.token}".encode()).decode()
        request = Request(url, data, {"Authorization": "Basic " + auth,
                                     "Content-Type": "application/x-www-form-urlencoded"}, method="POST")
        # Deliberately one POST only, no redirect, no transport/provider automatic retry.
        try:
            with build_opener(NoRedirect()).open(request, timeout=10) as response:
                raw = response.read(16385)
                if len(raw) > 16384 or response.status != 201:
                    raise ValueError("ambiguous_provider_response")
                result = json.loads(raw)
        except HTTPError as exc:
            if 400 <= exc.code < 500:
                raise Rejected("provider_rejected") from None
            raise ValueError("ambiguous_provider_response") from None
        return result["sid"], result["status"]

    def webhook(self, outbox: Outbox, target: str, signature: str, raw: bytes):
        if len(raw) > 16384:
            raise Blocked("webhook_too_large")
        route = None
        for key in ("status_url", "inbound_url"):
            parsed = urlsplit(self.config[key])
            expected = parsed.path + ("?" + parsed.query if parsed.query else "")
            if target == expected:
                route = key
        if route is None:
            raise Blocked("unknown_webhook_route")
        try:
            pairs = parse_qsl(raw.decode("utf-8"), keep_blank_values=True,
                              strict_parsing=True, max_num_fields=100, errors="strict")
        except (UnicodeError, ValueError):
            raise Blocked("invalid_webhook_form") from None
        fields = dict(pairs)
        if len(fields) != len(pairs):
            raise Blocked("duplicate_webhook_fields")
        # Official helper receives ALL fields and the configured exact public URL;
        # Host/X-Forwarded-* headers never decide which URL is trusted.
        if not signature or not self.validator.validate(self.config[route], fields, signature):
            raise Blocked("invalid_webhook_signature")
        if fields.get("AccountSid") != self.config["account_sid"]:
            raise Blocked("webhook_account_mismatch")
        if route == "inbound_url":
            if fields.get("To") != self.config["sender"]:
                raise Blocked("webhook_sender_mismatch")
            outbox.inbound(fields)
        else:
            outbox.receipt(fields)


def make_app(config_path: str, database_path: str):
    """WSGI factory for an approved HTTPS reverse proxy. No send/approve HTTP routes."""
    def app(environ, start_response):
        outbox = None
        try:
            if environ.get("REQUEST_METHOD") != "POST":
                raise Blocked("post_required")
            if environ.get("CONTENT_TYPE", "").split(";")[0].strip() != "application/x-www-form-urlencoded":
                raise Blocked("form_content_type_required")
            length = int(environ.get("CONTENT_LENGTH", "0"))
            if not 0 < length <= 16384:
                raise Blocked("invalid_body_size")
            raw = environ["wsgi.input"].read(length)
            if len(raw) != length:
                raise Blocked("incomplete_body")
            with open(config_path, encoding="utf-8") as stream:
                config = json.load(stream)
            outbox = Outbox(database_path, config)
            provider = TwilioProvider(outbox.config)
            query = environ.get("QUERY_STRING", "")
            target = environ.get("PATH_INFO", "") + ("?" + query if query else "")
            provider.webhook(outbox, target, environ.get("HTTP_X_TWILIO_SIGNATURE", ""), raw)
            # Empty TwiML: our application never sends an automatic reply.
            start_response("200 OK", [("Content-Type", "application/xml"), ("Cache-Control", "no-store")])
            return [b"<Response></Response>"]
        except (Blocked, ValueError, UnicodeError):
            start_response("403 Forbidden", [("Content-Type", "text/plain"), ("Cache-Control", "no-store")])
            return [b"Request rejected"]
        except Exception:
            # Ask provider to retry failed receipt persistence. Never acknowledge lost receipts.
            start_response("503 Service Unavailable", [("Content-Type", "text/plain"), ("Cache-Control", "no-store")])
            return [b"Temporarily unavailable"]
        finally:
            if outbox:
                outbox.close()
    return app
