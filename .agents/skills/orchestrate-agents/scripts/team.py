#!/usr/bin/env python3
"""Keep a Rex team's task record and check worker turns. Python 3.9+, stdlib only."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time


APPS = {"pi": "pi", "claude": "claude-code", "codex": "codex", "opencode": "opencode"}


def rex(*args, text=None):
    result = subprocess.run(["rex", *args], input=text, text=True, capture_output=True, timeout=20)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return result.stdout


def rex_json(*args):
    return json.loads(rex(*args))


def save(path, team):
    # One manager writes this file; replace atomically so interrupted writes remain readable.
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as target:
        json.dump(team, target, indent=2)
        target.write("\n")
        temporary = target.name
    os.replace(temporary, path)


def read_team(path):
    team = json.loads(path.read_text())
    if team.get("version") != 1 or not isinstance(team.get("tasks"), dict):
        raise ValueError("not a version 1 team record")
    return team


def worker_process(process, agent):
    for candidate in (process.get("foreground"), process.get("child")):
        if candidate and Path(candidate.get("argv0", "")).name == agent:
            return {"pid": candidate["pid"], "name": candidate["name"]}
    return None


def observe(team, task):
    if not task.get("block"):
        return {"state": "unbound"}
    session, block = team["session"], task["block"]
    process = rex_json("block", "call", "-s", session, "-b", block, "process")
    if process.get("last_exit") is not None or process.get("child") is None:
        return {"state": "exited", "exit": process.get("last_exit")}
    if worker_process(process, task["agent"]) != task["process"]:
        return {"state": "wrong_process", "process": process}
    reports = rex_json("block", "call", "-s", session, "-b", block, "program_status")
    roots = [r for r in reports["records"] if not r.get("id")
             and (r.get("effective_app") or r.get("app")) == APPS[task["agent"]]]
    if not roots:
        return {"state": "unknown", "reason": "no root status for this agent"}
    report = roots[-1]
    if report.get("owner") != task["process"]:
        return {"state": "unknown", "reason": "status belongs to another process"}
    return report


def turn_outcome(task, report):
    state = report["state"]
    if state in ("exited", "wrong_process", "unbound"):
        return 12
    # RFC 3339 reports come from one Rex server. Ignore the pre-send report.
    fresh = bool(report.get("updated_at")) and report["updated_at"] != task.get("since")
    if fresh and state == "blocked":
        return 10
    if fresh and state == "error":
        return 11
    if fresh and state == "done":
        return 0
    return None


def guard(team, task):
    if not task.get("block"):
        raise ValueError("task is not bound to a pane")
    if task["block"] in (team["manager_block"], os.environ.get("REX_BLOCK")):
        raise ValueError("refusing to control the manager's own pane")


def existing_file(value):
    path = Path(value).expanduser().resolve()
    if not path.is_file():
        raise argparse.ArgumentTypeError("not a file: " + str(path))
    return path


def parser():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("team", type=Path, help="absolute path to the manager-owned team.json")
    commands = cli.add_subparsers(dest="command", required=True)
    init = commands.add_parser("init")
    init.add_argument("--session", required=True)
    init.add_argument("--manager-block", required=True)
    add = commands.add_parser("add")
    add.add_argument("task")
    add.add_argument("--agent", choices=APPS, required=True)
    add.add_argument("--model", required=True)
    add.add_argument("--cwd", type=Path, required=True)
    add.add_argument("--prompt", type=existing_file, required=True)
    add.add_argument("--report", type=Path, required=True)
    add.add_argument("--depends", nargs="*", default=[])
    add.add_argument("--read-only", action="store_true")
    bind = commands.add_parser("bind")
    bind.add_argument("task")
    bind.add_argument("--block", required=True)
    conversation = commands.add_parser("conversation", help="record the worker's native conversation ID")
    conversation.add_argument("task")
    conversation.add_argument("--id", dest="conversation_id", required=True)
    commands.add_parser("status")
    wait = commands.add_parser("wait")
    wait.add_argument("task")
    wait.add_argument("--timeout", type=float, default=60)
    send = commands.add_parser("send")
    send.add_argument("task")
    send.add_argument("--file", type=existing_file, required=True)
    review = commands.add_parser("review")
    review.add_argument("task")
    review.add_argument("--verdict", choices=["verified", "changes-requested", "blocked"], required=True)
    review.add_argument("--evidence", required=True)
    return cli


def main():
    args = parser().parse_args()
    path = args.team.expanduser().resolve()
    if args.command == "init":
        if path.exists():
            raise ValueError("team already exists; inspect and resume it instead")
        blocks = rex_json("block", "ls", "-s", args.session, "--json")["blocks"]
        if args.manager_block not in [b["block_id"] for b in blocks]:
            raise ValueError("manager pane is not in the selected session")
        path.parent.mkdir(parents=True, exist_ok=True)
        save(path, {"version": 1, "session": args.session, "manager_block": args.manager_block, "tasks": {}})
        return 0

    team = read_team(path)
    tasks = team["tasks"]
    if args.command == "add":
        if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", args.task) or args.task in tasks:
            raise ValueError("use a new lowercase kebab-case task ID")
        cwd = args.cwd.expanduser().resolve(strict=True)
        if not cwd.is_dir():
            raise ValueError("cwd must be a directory")
        if any(d not in tasks for d in args.depends):
            raise ValueError("dependencies must be recorded first")
        if not args.read_only and any(t["cwd"] == str(cwd) and not t["read_only"] for t in tasks.values()):
            raise ValueError("editing tasks need separate workspaces")
        tasks[args.task] = {"agent": args.agent, "model": args.model, "cwd": str(cwd),
                           "prompt": str(args.prompt), "report": str(args.report.expanduser().resolve()),
                           "depends": args.depends, "read_only": args.read_only, "phase": "planned",
                           "block": None, "process": None, "conversation_id": None,
                           "since": None, "turn": 0, "followups": [], "reviews": []}
        save(path, team)
        return 0

    if args.command == "status":
        for task_id, task in tasks.items():
            try:
                report = observe(team, task)
            except (RuntimeError, subprocess.TimeoutExpired) as error:
                report = {"state": "unavailable", "reason": str(error)}
            print(json.dumps({"task": task_id, **task, "observed": report}))
        return 0

    task = tasks[args.task]
    if args.command == "conversation":
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", args.conversation_id):
            raise ValueError("use a native conversation ID, not a name, path, or terminal text")
        if task.get("conversation_id") not in (None, args.conversation_id):
            raise ValueError("conversation ID already recorded; inspect before changing workers")
        task["conversation_id"] = args.conversation_id
        save(path, team)
        return 0

    if args.command == "bind":
        if task["block"]:
            raise ValueError("already bound; do not silently replace a worker")
        if args.block in (team["manager_block"], os.environ.get("REX_BLOCK")):
            raise ValueError("cannot bind the manager's pane as a worker")
        if any(t["block"] == args.block for t in tasks.values()):
            raise ValueError("pane already belongs to a task")
        if any(tasks[d]["phase"] != "verified" for d in task["depends"]):
            raise ValueError("verify dependencies before launching this worker")
        blocks = rex_json("block", "ls", "-s", team["session"], "--json")["blocks"]
        if args.block not in [b["block_id"] for b in blocks]:
            raise ValueError("worker pane is not in the selected session")
        process = None
        deadline = time.monotonic() + 15
        while process is None and time.monotonic() < deadline:
            process = worker_process(rex_json("block", "call", "-s", team["session"], "-b", args.block, "process"), task["agent"])
            if process is None:
                time.sleep(0.5)
        if process is None:
            raise ValueError("expected agent is not running; inspect the pane before retrying")
        task.update(block=args.block, process=process, phase="assigned", turn=1)
        save(path, team)
        return 0

    if args.command in ("wait", "send"):
        guard(team, task)
    if args.command == "wait":
        if args.timeout < 0:
            raise ValueError("timeout must be non-negative")
        deadline = time.monotonic() + args.timeout
        while True:
            report = observe(team, task)
            outcome = turn_outcome(task, report)
            if outcome is not None:
                print(json.dumps(report))
                return outcome
            if time.monotonic() >= deadline:
                print(json.dumps({"state": "timeout", "observed": report}))
                return 124
            time.sleep(min(2, max(0, deadline - time.monotonic())))

    if args.command == "send":
        report = observe(team, task)
        if (task["phase"] == "sending" or report["state"] not in ("done", "idle")
                or report.get("updated_at") == task.get("since")):
            raise ValueError("worker is not ready for a prompt; inspect it rather than typing blindly")
        message = args.file.read_text()
        if any(ord(c) < 32 and c not in "\n\r\t" for c in message):
            raise ValueError("prompt contains terminal control characters")
        message = " ".join(message.splitlines()).replace("\t", " ").strip()
        if not message:
            raise ValueError("empty prompt")
        task.update(since=report["updated_at"], phase="sending", turn=task["turn"] + 1)
        task.setdefault("followups", []).append({"turn": task["turn"], "prompt": str(args.file)})
        save(path, team)
        # Keep 'sending' on failure: inspect delivery before attempting a retry.
        rex("send", "-s", team["session"], "-b", task["block"], text=message)
        time.sleep(0.5)
        rex("send-key", "-s", team["session"], "-b", task["block"], "enter")
        task["phase"] = "assigned"
        save(path, team)
        return 0

    if args.command == "review":
        if args.verdict == "verified" and not Path(task["report"]).is_file():
            raise ValueError("read the worker's report and verify its work before marking verified")
        task["phase"] = args.verdict
        task["reviews"].append({"turn": task["turn"], "verdict": args.verdict, "evidence": args.evidence})
        save(path, team)
        return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print("team: " + str(error), file=sys.stderr)
        sys.exit(2)
