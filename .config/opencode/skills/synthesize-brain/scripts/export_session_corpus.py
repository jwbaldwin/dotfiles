#!/usr/bin/env python3

"""Export OpenCode session corpus and suggest high-value sessions.

This script supports two modes:
- Suggest mode: rank likely high-value sessions for a prompt/query.
- Corpus mode: export selected sessions as markdown/json for synthesis.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import re
import sqlite3
import sys
from typing import Any, Dict, List, Sequence


DEFAULT_DB_PATH = pathlib.Path("~/.local/share/opencode/opencode.db").expanduser()

KEYWORD_PATTERNS = [
    ("must", re.compile(r"\bmust\b", re.IGNORECASE)),
    ("never", re.compile(r"\bnever\b", re.IGNORECASE)),
    ("always", re.compile(r"\balways\b", re.IGNORECASE)),
    ("prefer", re.compile(r"\bprefer\b", re.IGNORECASE)),
    ("avoid", re.compile(r"\bavoid\b", re.IGNORECASE)),
    ("do not", re.compile(r"\bdo\s+not\b", re.IGNORECASE)),
    ("don't", re.compile(r"\bdon't\b", re.IGNORECASE)),
    ("should", re.compile(r"\bshould\b", re.IGNORECASE)),
    ("need to", re.compile(r"\bneed\s+to\b", re.IGNORECASE)),
    ("i want", re.compile(r"\bi\s+want\b", re.IGNORECASE)),
    ("i need", re.compile(r"\bi\s+need\b", re.IGNORECASE)),
    ("let's", re.compile(r"\blet's\b", re.IGNORECASE)),
    ("we should", re.compile(r"\bwe\s+should\b", re.IGNORECASE)),
]

STOPWORDS = {
    "the",
    "a",
    "an",
    "and",
    "or",
    "but",
    "if",
    "then",
    "this",
    "that",
    "those",
    "these",
    "for",
    "from",
    "into",
    "with",
    "about",
    "have",
    "has",
    "had",
    "you",
    "your",
    "yours",
    "our",
    "ours",
    "just",
    "want",
    "need",
    "session",
    "sessions",
    "conversation",
    "conversations",
    "last",
    "three",
    "two",
    "one",
    "high",
    "value",
    "useful",
    "knowledge",
    "taste",
    "values",
    "synthesize",
}

WORD_PATTERN = re.compile(r"[a-z0-9_/-]+")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Suggest and export OpenCode session corpus."
    )
    parser.add_argument(
        "--db-path",
        default=str(DEFAULT_DB_PATH),
        help="Path to opencode.db (default: ~/.local/share/opencode/opencode.db).",
    )
    parser.add_argument(
        "--session-id",
        action="append",
        default=[],
        help="Session ID to include (repeat for multiple).",
    )
    parser.add_argument(
        "--recent",
        type=int,
        default=0,
        help="Number of sessions to export when no --session-id is given (default: 3).",
    )
    parser.add_argument(
        "--recent-window",
        type=int,
        default=50,
        help="Candidate window size for ranking when no explicit IDs are provided.",
    )
    parser.add_argument(
        "--suggest",
        type=int,
        default=0,
        help="Suggest top N sessions only (no corpus export unless --auto-select is also set).",
    )
    parser.add_argument(
        "--auto-select",
        type=int,
        default=0,
        help="Automatically select top N ranked sessions and export corpus.",
    )
    parser.add_argument(
        "--query",
        default="",
        help="Freeform relevance query used to rank candidate sessions.",
    )
    parser.add_argument(
        "--directory",
        default="",
        help="Optional directory prefix filter when selecting candidates.",
    )
    parser.add_argument(
        "--include-assistant",
        action="store_true",
        help="Include assistant text parts in exported corpus.",
    )
    parser.add_argument(
        "--max-items-per-role",
        type=int,
        default=120,
        help="Maximum number of text parts per role per session.",
    )
    parser.add_argument(
        "--max-chars",
        type=int,
        default=700,
        help="Maximum characters kept per text part.",
    )
    parser.add_argument(
        "--format",
        choices=["markdown", "json"],
        default="markdown",
        help="Output format.",
    )
    parser.add_argument(
        "--output",
        default="",
        help="Write output to path. Default: print to stdout.",
    )
    return parser.parse_args()


def normalize_text(text: str, max_chars: int) -> str:
    cleaned = re.sub(r"\s+", " ", text).strip()
    if len(cleaned) <= max_chars:
        return cleaned
    return cleaned[: max_chars - 1].rstrip() + "..."


def ms_to_iso(ms: int) -> str:
    return dt.datetime.fromtimestamp(ms / 1000, tz=dt.timezone.utc).isoformat()


def extract_query_terms(query: str) -> List[str]:
    terms = []
    seen = set()
    for raw in WORD_PATTERN.findall(query.lower()):
        token = raw.strip("_- /")
        if len(token) < 3:
            continue
        if token.startswith("ses_"):
            continue
        if token in STOPWORDS:
            continue
        if token in seen:
            continue
        seen.add(token)
        terms.append(token)
    return terms


def detect_keywords(text: str) -> List[str]:
    found = [kw for kw, pattern in KEYWORD_PATTERNS if pattern.search(text)]
    unique = []
    for kw in found:
        if kw not in unique:
            unique.append(kw)
    return unique


def split_sentences(text: str) -> List[str]:
    parts = re.split(r"(?<=[.!?])\s+", text)
    return [p.strip() for p in parts if p.strip()]


def extract_signals(messages: Sequence[Dict[str, Any]]) -> List[Dict[str, Any]]:
    seen = set()
    signals: List[Dict[str, Any]] = []

    for msg in messages:
        text_value = msg.get("text")
        if not isinstance(text_value, str):
            continue

        for sentence in split_sentences(text_value):
            keywords = detect_keywords(sentence)
            if not keywords:
                continue
            if len(sentence) < 15:
                continue

            key = sentence.lower()
            if key in seen:
                continue
            seen.add(key)

            signals.append(
                {
                    "text": sentence,
                    "keywords": keywords,
                    "time_created_ms": msg.get("time_created_ms"),
                }
            )

    return signals


def fetch_sessions_by_ids(
    conn: sqlite3.Connection,
    session_ids: Sequence[str],
) -> List[Dict[str, Any]]:
    if not session_ids:
        return []

    cur = conn.cursor()
    placeholders = ",".join(["?"] * len(session_ids))
    rows = cur.execute(
        f"""
        SELECT id, title, directory, time_updated
        FROM session
        WHERE id IN ({placeholders})
        """,
        list(session_ids),
    ).fetchall()

    by_id = {str(row[0]): row for row in rows}
    missing = [sid for sid in session_ids if sid not in by_id]
    if missing:
        print(
            "warning: missing session IDs: " + ", ".join(missing),
            file=sys.stderr,
        )

    ordered = [by_id[sid] for sid in session_ids if sid in by_id]
    return [
        {
            "id": str(row[0]),
            "title": str(row[1]),
            "directory": str(row[2]),
            "time_updated_ms": int(row[3]),
            "time_updated_iso": ms_to_iso(int(row[3])),
        }
        for row in ordered
    ]


def fetch_recent_sessions(
    conn: sqlite3.Connection,
    limit: int,
    directory: str,
) -> List[Dict[str, Any]]:
    cur = conn.cursor()

    query = """
        SELECT id, title, directory, time_updated
        FROM session
        WHERE time_archived IS NULL
    """
    params: List[Any] = []

    if directory:
        query += " AND directory LIKE ?"
        params.append(directory.rstrip("/") + "%")

    query += " ORDER BY time_updated DESC LIMIT ?"
    params.append(max(1, limit))

    rows = cur.execute(query, params).fetchall()
    return [
        {
            "id": str(row[0]),
            "title": str(row[1]),
            "directory": str(row[2]),
            "time_updated_ms": int(row[3]),
            "time_updated_iso": ms_to_iso(int(row[3])),
        }
        for row in rows
    ]


def fetch_text_parts(
    conn: sqlite3.Connection,
    session_id: str,
    include_assistant: bool,
    max_items_per_role: int,
    max_chars: int,
) -> Dict[str, List[Dict[str, Any]]]:
    cur = conn.cursor()
    rows = cur.execute(
        """
        SELECT
            json_extract(m.data, '$.role') AS role,
            p.time_created AS time_created,
            json_extract(p.data, '$.text') AS text
        FROM part p
        JOIN message m ON m.id = p.message_id
        WHERE p.session_id = ?
          AND json_extract(p.data, '$.type') = 'text'
        ORDER BY p.time_created ASC
        """,
        (session_id,),
    ).fetchall()

    include_roles = {"user"}
    if include_assistant:
        include_roles.add("assistant")

    out: Dict[str, List[Dict[str, Any]]] = {"user": [], "assistant": []}
    counters = {"user": 0, "assistant": 0}

    for role, time_created, text in rows:
        role_value = str(role)
        if role_value not in include_roles:
            continue
        if not isinstance(text, str) or not text.strip():
            continue
        if counters[role_value] >= max_items_per_role:
            continue

        time_created_ms = int(time_created)
        out[role_value].append(
            {
                "time_created_ms": time_created_ms,
                "time_created_iso": ms_to_iso(time_created_ms),
                "text": normalize_text(text, max_chars=max_chars),
            }
        )
        counters[role_value] += 1

    if not include_assistant:
        out.pop("assistant", None)

    return out


def score_candidate_pool(
    conn: sqlite3.Connection,
    candidates: Sequence[Dict[str, Any]],
    query: str,
    max_chars: int,
) -> List[Dict[str, Any]]:
    query_terms = extract_query_terms(query)
    ranked: List[Dict[str, Any]] = []
    total = len(candidates)

    for index, session in enumerate(candidates):
        session_id = str(session.get("id", ""))
        title = str(session.get("title", ""))

        user_messages = fetch_text_parts(
            conn,
            session_id=session_id,
            include_assistant=False,
            max_items_per_role=50,
            max_chars=max_chars,
        ).get("user", [])

        joined_text = " ".join(str(m.get("text", "")) for m in user_messages).lower()
        lower_title = title.lower()

        matched_terms = [
            term
            for term in query_terms
            if term in lower_title or term in joined_text
        ]
        query_score = (len(matched_terms) / len(query_terms)) if query_terms else 0.0

        signal_count = len(extract_signals(user_messages))
        signal_density = min(signal_count / max(1, len(user_messages)), 1.0)
        volume_score = min(len(user_messages) / 30.0, 1.0)

        if total <= 1:
            recency_score = 1.0
        else:
            recency_score = 1.0 - (index / (total - 1))

        if query_terms:
            score = (
                0.45 * query_score
                + 0.25 * signal_density
                + 0.15 * volume_score
                + 0.15 * recency_score
            )
        else:
            score = 0.40 * signal_density + 0.35 * volume_score + 0.25 * recency_score

        reasons: List[str] = []
        if matched_terms:
            reasons.append("query match: " + ", ".join(matched_terms[:4]))
        if signal_count >= 4:
            reasons.append("directive-rich language")
        if len(user_messages) >= 8:
            reasons.append("high user signal volume")
        if index == 0:
            reasons.append("most recent")
        if not reasons:
            reasons.append("recent and non-trivial")

        ranked.append(
            {
                "id": session_id,
                "title": title,
                "directory": str(session.get("directory", "")),
                "time_updated_ms": int(session.get("time_updated_ms", 0)),
                "time_updated_iso": str(session.get("time_updated_iso", "")),
                "score": round(score, 4),
                "reasons": reasons,
                "matched_terms": matched_terms,
                "user_text_parts": len(user_messages),
                "candidate_signals": signal_count,
            }
        )

    ranked.sort(key=lambda item: float(item.get("score", 0.0)), reverse=True)
    return ranked


def build_payload(args: argparse.Namespace) -> Dict[str, Any]:
    db_path = pathlib.Path(args.db_path).expanduser()
    if not db_path.exists():
        raise FileNotFoundError(f"Database not found: {db_path}")

    conn = sqlite3.connect(str(db_path))
    try:
        explicit_ids: List[str] = list(args.session_id)

        selection_mode = "explicit"
        selected_sessions: List[Dict[str, Any]] = []
        ranked_candidates: List[Dict[str, Any]] = []

        if explicit_ids:
            selected_sessions = fetch_sessions_by_ids(conn, explicit_ids)
        else:
            baseline_count = args.recent if args.recent > 0 else 3
            pool_limit = max(
                3,
                baseline_count,
                args.recent_window,
                args.suggest,
                args.auto_select,
            )
            candidate_pool = fetch_recent_sessions(
                conn,
                limit=pool_limit,
                directory=args.directory,
            )
            ranked_candidates = score_candidate_pool(
                conn,
                candidates=candidate_pool,
                query=args.query,
                max_chars=args.max_chars,
            )

            if args.suggest > 0 and args.auto_select == 0 and args.recent == 0:
                top = ranked_candidates[: args.suggest]
                return {
                    "mode": "suggestions",
                    "generated_at": dt.datetime.now(tz=dt.timezone.utc).isoformat(),
                    "db_path": str(db_path),
                    "selection": {
                        "query": args.query,
                        "directory": args.directory,
                        "suggest": args.suggest,
                        "recent_window": pool_limit,
                    },
                    "suggestions": top,
                    "stats": {
                        "candidate_count": len(ranked_candidates),
                        "suggested_count": len(top),
                    },
                }

            if args.auto_select > 0:
                selection_mode = "auto-select"
                selected_ids = [
                    str(item.get("id", ""))
                    for item in ranked_candidates[: args.auto_select]
                    if item.get("id")
                ]
            else:
                selection_mode = "ranked-recent"
                pick_count = args.recent if args.recent > 0 else 3
                selected_ids = [
                    str(item.get("id", ""))
                    for item in ranked_candidates[:pick_count]
                    if item.get("id")
                ]

            selected_sessions = fetch_sessions_by_ids(conn, selected_ids)

        for session in selected_sessions:
            session_id = str(session.get("id", ""))
            messages = fetch_text_parts(
                conn,
                session_id=session_id,
                include_assistant=args.include_assistant,
                max_items_per_role=args.max_items_per_role,
                max_chars=args.max_chars,
            )
            session["messages"] = messages
            session["candidate_signals"] = extract_signals(messages.get("user", []))
    finally:
        conn.close()

    user_parts = 0
    assistant_parts = 0
    signal_count = 0
    for session in selected_sessions:
        messages = session.get("messages", {})
        if isinstance(messages, dict):
            user_items = messages.get("user", [])
            assistant_items = messages.get("assistant", [])
            if isinstance(user_items, list):
                user_parts += len(user_items)
            if isinstance(assistant_items, list):
                assistant_parts += len(assistant_items)

        signals = session.get("candidate_signals", [])
        if isinstance(signals, list):
            signal_count += len(signals)

    selected_ids = [str(s.get("id", "")) for s in selected_sessions]

    payload: Dict[str, Any] = {
        "mode": "corpus",
        "generated_at": dt.datetime.now(tz=dt.timezone.utc).isoformat(),
        "db_path": str(db_path),
        "selection": {
            "mode": selection_mode,
            "session_ids": list(args.session_id),
            "selected_session_ids": selected_ids,
            "recent": args.recent,
            "recent_window": args.recent_window,
            "query": args.query,
            "directory": args.directory,
            "suggest": args.suggest,
            "auto_select": args.auto_select,
            "include_assistant": args.include_assistant,
        },
        "stats": {
            "session_count": len(selected_sessions),
            "user_text_parts": user_parts,
            "assistant_text_parts": assistant_parts,
            "candidate_signal_count": signal_count,
        },
        "suggestions": ranked_candidates[: max(args.suggest, 8)] if ranked_candidates else [],
        "sessions": selected_sessions,
    }
    return payload


def render_markdown(payload: Dict[str, Any]) -> str:
    lines: List[str] = []
    lines.append("# Session Corpus")
    lines.append("")
    lines.append(f"- Mode: {payload.get('mode', 'corpus')}")
    lines.append(f"- Generated: {payload.get('generated_at', '')}")
    lines.append(f"- DB: `{payload.get('db_path', '')}`")

    stats = payload.get("stats", {})
    if isinstance(stats, dict):
        for key in [
            "candidate_count",
            "suggested_count",
            "session_count",
            "user_text_parts",
            "assistant_text_parts",
            "candidate_signal_count",
        ]:
            if key in stats:
                lines.append(f"- {key.replace('_', ' ').title()}: {stats[key]}")

    suggestions = payload.get("suggestions", [])
    if isinstance(suggestions, list) and suggestions:
        lines.append("")
        lines.append("## Top Candidate Sessions")
        for index, item in enumerate(suggestions, start=1):
            if not isinstance(item, dict):
                continue

            reasons = item.get("reasons", [])
            reason_text = ", ".join(reasons) if isinstance(reasons, list) else ""
            lines.append(
                f"{index}. {item.get('id', '')} - {item.get('title', '')} (score={item.get('score', 0)})"
            )
            lines.append(f"   - Updated: {item.get('time_updated_iso', '')}")
            lines.append(f"   - Directory: `{item.get('directory', '')}`")
            lines.append(f"   - Reasons: {reason_text}")

    if payload.get("mode") == "suggestions":
        lines.append("")
        return "\n".join(lines)

    sessions = payload.get("sessions", [])
    if not isinstance(sessions, list):
        sessions = []

    for session in sessions:
        if not isinstance(session, dict):
            continue

        lines.append("")
        lines.append(f"## {session.get('id', '')} - {session.get('title', '')}")
        lines.append(f"- Directory: `{session.get('directory', '')}`")
        lines.append(f"- Updated: {session.get('time_updated_iso', '')}")

        signals = session.get("candidate_signals", [])
        if isinstance(signals, list) and signals:
            lines.append("")
            lines.append("### Candidate Signals")
            for signal in signals:
                if not isinstance(signal, dict):
                    continue
                keywords = signal.get("keywords", [])
                kw_text = ", ".join(keywords) if isinstance(keywords, list) else ""
                lines.append(f"- ({kw_text}) {signal.get('text', '')}")

        messages = session.get("messages", {})
        if not isinstance(messages, dict):
            messages = {}

        user_msgs = messages.get("user", [])
        if isinstance(user_msgs, list) and user_msgs:
            lines.append("")
            lines.append("### User Text Parts")
            for index, msg in enumerate(user_msgs, start=1):
                if isinstance(msg, dict):
                    lines.append(f"{index}. {msg.get('text', '')}")

        assistant_msgs = messages.get("assistant", [])
        if isinstance(assistant_msgs, list) and assistant_msgs:
            lines.append("")
            lines.append("### Assistant Text Parts")
            for index, msg in enumerate(assistant_msgs, start=1):
                if isinstance(msg, dict):
                    lines.append(f"{index}. {msg.get('text', '')}")

    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()

    try:
        payload = build_payload(args)
    except Exception as exc:  # pragma: no cover
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        rendered = json.dumps(payload, indent=2)
    else:
        rendered = render_markdown(payload)

    if args.output:
        output_path = pathlib.Path(args.output).expanduser()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(rendered, encoding="utf-8")
    else:
        print(rendered)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
