"""Human-operated control interface. Run --help; never expose through arbitrary-shell tools."""
from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
from pathlib import Path

from messaging import Blocked, Outbox


def principal() -> str:
    # Do not trust USERNAME, USER, LOGNAME, command flags, or a submitted JSON actor.
    if os.name == "nt":
        import ctypes
        size = ctypes.c_ulong(1024)
        buffer = ctypes.create_unicode_buffer(size.value)
        if not ctypes.windll.secur32.GetUserNameExW(2, buffer, ctypes.byref(size)):
            raise Blocked("cannot_resolve_windows_principal")
        return buffer.value
    import pwd
    return pwd.getpwuid(os.geteuid()).pw_name


def read_json(path: str):
    with open(path, encoding="utf-8-sig") as stream:
        return json.load(stream)


def confirm(phrase: str):
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        raise Blocked("interactive_human_terminal_required")
    if input(f"Type {phrase} exactly: ") != phrase:
        raise Blocked("confirmation_not_supplied")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, help="Private operator-owned config outside checkout")
    parser.add_argument("--db", required=True, help="Absolute local persistent DB path outside checkout")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("identity")
    for cmd in ("contact", "enqueue"):
        sub.add_parser(cmd).add_argument("json_file")
    for cmd in ("preview", "approve", "dispatch"):
        sub.add_parser(cmd).add_argument("message_id")
    rev = sub.add_parser("revise")
    rev.add_argument("message_id")
    rev.add_argument("body_file", help="UTF-8 replacement body; never put client text in shell history")
    sub.add_parser("pause")
    sub.add_parser("unpause")
    sub.add_parser("recover")
    sub.add_parser("status")
    args = parser.parse_args()
    outbox = None
    try:
        actor = principal()
        if args.command == "identity":
            print(actor)
            return 0
        config_path = Path(args.config).resolve()
        if (Path(__file__).resolve().parent in config_path.parents
                or any((p / ".git").exists() for p in config_path.parents)):
            raise Blocked("private_configuration_must_be_outside_checkout")
        outbox = Outbox(args.db, read_json(str(config_path)))
        outbox.operator(actor)
        command = args.command
        if command == "contact":
            record = read_json(args.json_file)
            confirm("ATTEST CONSENT EVIDENCE")
            outbox.record_contact(actor=actor, **record)
        elif command == "enqueue":
            record = read_json(args.json_file)
            confirm("ATTEST GMAIL SENT EVIDENCE")
            print(outbox.enqueue(actor=actor, **record))
        elif command in {"preview", "approve"}:
            preview = outbox.preview(args.message_id, actor)
            print(json.dumps(preview, indent=2))
            if command == "approve":
                confirm("APPROVE " + preview["approval_hash"])
                outbox.approve(args.message_id, preview["approval_hash"], actor)
                print("approved")
        elif command == "revise":
            outbox.revise(args.message_id, Path(args.body_file).read_text(encoding="utf-8"), actor)
        elif command == "dispatch":
            print(outbox.dispatch(args.message_id))
        elif command in {"pause", "unpause"}:
            if command == "unpause":
                confirm("UNPAUSE APPROVED MESSAGES")
            outbox.pause(command == "pause", actor)
        elif command == "recover":
            confirm("WORKERS STOPPED RECONCILE WITHOUT RESENDING")
            outbox.recover(actor)
        elif command == "status":
            rows = outbox.db.execute("SELECT id,status,reserved,error FROM messages ORDER BY rowid DESC LIMIT 100").fetchall()
            print(json.dumps([dict(row) for row in rows], indent=2))
        return 0
    except (Blocked, KeyError, TypeError, ValueError, OSError, sqlite3.Error) as exc:
        print(str(exc) if isinstance(exc, Blocked) else "operation_failed_review_private_runtime", file=sys.stderr)
        return 2
    finally:
        if outbox:
            outbox.close()


if __name__ == "__main__":
    raise SystemExit(main())
