import json
import os
from pathlib import Path
import subprocess
import tempfile
import time


def api(operation, session_id=None, body=None):
    args = ["opencode", "api", operation]
    if session_id:
        args += ["--param", f"sessionID={session_id}"]
    if body is not None:
        args += ["--data", json.dumps(body)]
    output = subprocess.check_output(args, text=True)
    return json.loads(output) if output.strip() else None


socket = f"session-tools-smoke-{os.getpid()}"


def tmux(*args):
    return subprocess.check_output(["tmux", "-L", socket, *args], text=True)


def screen():
    return tmux("capture-pane", "-p", "-t", "smoke")


def alert_open(marker):
    visible = screen()
    return marker in visible and any(line.strip() == "ok" for line in visible.splitlines())


def wait_for(predicate, label, timeout=60):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.25)
    raise AssertionError(f"Timed out: {label}\n{screen()}")


def keys(*keys):
    tmux("send-keys", "-t", "smoke", *keys)
    time.sleep(0.2)


def command(text):
    tmux("send-keys", "-t", "smoke", "-l", text)
    keys("Enter")
    if text in ("/btw", "/bg"):
        keys("Enter")


def status():
    return tmux("display-message", "-p", "-t", "smoke", "#{@opencode-status}").strip()


def choose_action(title):
    wait_for(lambda: title in screen(), title)
    tmux("send-keys", "-t", "smoke", "-l", title)
    keys("Enter")


def context(session_id):
    return api("v2.session.context", session_id)["data"]


def last_text(messages):
    for message in reversed(messages):
        if message["type"] == "assistant":
            texts = [part["text"] for part in message["content"] if part["type"] == "text"]
            if texts:
                return "\n".join(texts)
    return ""


sessions = []
started = False
temporary_root = Path(os.environ["TMPDIR"]) / "opencode"
with tempfile.TemporaryDirectory(prefix="session-tools-", dir=temporary_root) as directory:
    try:
        def jj(*args):
            return subprocess.check_output(["jj", *args], cwd=directory, text=True, stderr=subprocess.DEVNULL).strip()

        jj("git", "init")
        jj("bookmark", "create", "prompt-info-smoke")
        jj("new")
        change_id = jj("log", "--no-graph", "-r", "@", "-T", "change_id.shortest(4)")
        origin = api("v2.session.create", body={
            "title": "Session tools smoke check",
            "location": {"directory": directory},
            "permissions": [{"action": "*", "resource": "*", "effect": "deny"}],
        })["data"]["id"]
        sessions.append(origin)
        api("v2.session.prompt", origin, {"text": "Reply with exactly SEED_OK. Do not use tools."})
        api("v2.session.wait", origin)
        baseline = context(origin)
        assert "SEED_OK" in last_text(baseline)
        launch = f"opencode --session {origin} {directory}"
        tmux("-f", "/dev/null", "new-session", "-d", "-s", "smoke", "-x", "140", "-y", "45", launch)
        started = True
        wait_for(lambda: status() == "idle", "CLI plugin loaded")
        wait_for(lambda: f" {change_id}" in screen() and "← prompt-info-smoke ↑1" in screen(), "prompt repository status")
        jj("new")
        change_id = jj("log", "--no-graph", "-r", "@", "-T", "change_id.shortest(4)")
        tmux("send-keys", "-t", "smoke", "-H", "1b", "5b", "49")
        wait_for(lambda: f" {change_id}" in screen() and "← prompt-info-smoke ↑2" in screen(), "prompt refresh on terminal focus")
        assert context(origin) == baseline

        command("/park smoke-persistence-note")
        wait_for(lambda: status() == "parked", "park updates tmux")
        assert context(origin) == baseline
        tmux("respawn-pane", "-k", "-t", "smoke", launch)
        wait_for(lambda: "smoke-persistence-note" in screen(), "parking survives restart")
        command("/inbox")
        wait_for(lambda: "Parked sessions" in screen(), "parking inbox")
        keys("Enter")
        wait_for(lambda: alert_open("smoke-persistence-note"), "parking preview")
        keys("Enter")
        wait_for(lambda: "Open session" in screen(), "parking actions")
        keys("Enter")
        command("/unpark")
        wait_for(lambda: status() == "idle", "unpark updates tmux")

        command("/btw Reply with SIDE_CHANNEL_OK in bold, then INLINE_CODE_OK as inline code, then a bullet containing LIST_ITEM_OK. No code fence.")
        wait_for(lambda: screen().count("SIDE_CHANNEL_OK") >= 2 and "Thinking…" not in screen(), "side answer", 120)
        assert "**SIDE_CHANNEL_OK**" not in screen(), "Side answer shows raw bold markers"
        assert "`INLINE_CODE_OK`" not in screen(), "Side answer shows raw inline-code markers"
        assert screen().count("LIST_ITEM_OK") >= 2, "Side answer lost its list"
        assert context(origin) == baseline, "Side question changed the main transcript"
        keys("Escape")
        wait_for(lambda: "c copy · Esc" not in screen(), "side panel dismissed")
        command("/btw")
        wait_for(lambda: "c copy · Esc" in screen() and screen().count("SIDE_CHANNEL_OK") >= 2, "reopen side answer")
        keys("Escape")
        wait_for(lambda: "c copy · Esc" not in screen(), "reopened panel dismissed")
        command("/bg Reply with exactly BACKGROUND_OK. Do not use tools.")
        wait_for(lambda: "Background tasks:" in screen(), "background launch")
        forks = [session for session in api("v2.session.list")["data"] if session.get("fork", {}).get("sessionID") == origin]
        assert len(forks) == 1
        fork = forks[0]["id"]
        sessions.append(fork)
        assert not forks[0].get("parentID"), "Background task is not an independent root"
        api("v2.session.wait", fork)
        assert "BACKGROUND_OK" in last_text(context(fork))
        assert context(origin) == baseline, "Background task changed the main transcript"

        wait_for(lambda: "Background task complete" in screen() and "Actions · /bg-result" in screen(), "automatic background result card")
        assert screen().count("BACKGROUND_OK") >= 2, "Card did not render the answer"
        tmux("send-keys", "-t", "smoke", "-l", "ci")
        wait_for(lambda: any(line.strip().endswith("ci") for line in screen().splitlines()), "completion card leaves typing alone")
        keys("BSpace", "BSpace")
        tmux("respawn-pane", "-k", "-t", "smoke", launch)
        wait_for(lambda: "Actions · /bg-result" in screen(), "result card survives restart")
        command("/bg Reply with exactly SECOND_RESULT_OK. Do not use tools.")
        wait_for(lambda: "1 of 2 · Next" in screen(), "multiple completed results", 120)
        command("/bg-result")
        choose_action("Next completed result")
        wait_for(lambda: "2 of 2 · Next" in screen() and screen().count("SECOND_RESULT_OK") >= 2, "cycle completed results")
        command("/bg-result")
        choose_action("Remove from task list")
        wait_for(lambda: "of 2 · Next" not in screen() and "Background task complete" in screen(), "remove selected result")
        command("/bg-result")
        choose_action("Dismiss result card")
        wait_for(lambda: "Actions · /bg-result" not in screen(), "dismiss result card")
        assert "Background tasks:" in screen(), "Dismissing removed the task"
        tmux("respawn-pane", "-k", "-t", "smoke", launch)
        wait_for(lambda: "Background tasks:" in screen(), "dismissed task survives restart")
        assert "Actions · /bg-result" not in screen(), "Dismissed card returned after restart"
        assert context(origin) == baseline, "Result card changed the main transcript"

        command("/bg")
        wait_for(lambda: "Background tasks" in screen(), "background picker")
        keys("Enter")
        wait_for(lambda: alert_open("BACKGROUND_OK"), "background result")
        keys("Enter")
        choose_action("Remove from task list")
        wait_for(lambda: "Background tasks:" not in screen(), "remove finished task")
        print("Passed: prompt status, tmux, parking, /btw, /bg cards/actions/cycling/dismissal/persistence, and transcript isolation")
    finally:
        if sessions:
            for session in api("v2.session.list")["data"]:
                if session.get("fork", {}).get("sessionID") == sessions[0] and session["id"] not in sessions:
                    sessions.append(session["id"])
        for session_id in reversed(sessions):
            api("v2.session.interrupt", session_id, {"continue": False})
            api("v2.session.remove", session_id)
        if started:
            time.sleep(0.5)
            tmux("kill-server")
