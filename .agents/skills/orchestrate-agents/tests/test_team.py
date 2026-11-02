import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "team.py"
SPEC = importlib.util.spec_from_file_location("team", SCRIPT)
team = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(team)


class TurnTests(unittest.TestCase):
    def test_previous_turn_done_is_not_completion(self):
        self.assertIsNone(team.turn_outcome({"since": "before"}, {"state": "done", "updated_at": "before"}))
        self.assertEqual(team.turn_outcome({"since": "before"}, {"state": "done", "updated_at": "after"}), 0)

    def test_idle_or_missing_protocol_is_not_completion(self):
        for state in ("idle", "working", "unknown", "surprise"):
            self.assertIsNone(team.turn_outcome({"since": None}, {"state": state, "updated_at": "now"}))

    def test_blocked_error_and_exit_have_distinct_outcomes(self):
        for state, code in (("blocked", 10), ("error", 11), ("exited", 12), ("wrong_process", 12)):
            self.assertEqual(team.turn_outcome({"since": None}, {"state": state, "updated_at": "now"}), code)

    def test_nested_done_does_not_finish_root_turn(self):
        process = {"pid": 42, "name": "node"}
        task = {"agent": "pi", "block": "worker", "process": process}
        replies = [
            {"child": {"argv0": "pi", **process}},
            {"records": [
                {"state": "working", "app": "pi", "owner": process, "updated_at": "now"},
                {"id": "test", "state": "done", "app": "pi", "owner": process, "updated_at": "later"},
            ]},
        ]
        with patch.object(team, "rex_json", side_effect=replies):
            self.assertEqual(team.observe({"session": "session"}, task)["state"], "working")

    def test_status_from_previous_process_is_not_completion(self):
        task = {"agent": "pi", "block": "worker", "process": {"pid": 42, "name": "node"}}
        replies = [
            {"child": {"argv0": "pi", "pid": 42, "name": "node"}},
            {"records": [{"state": "done", "app": "pi", "owner": {"pid": 41, "name": "node"}}]},
        ]
        with patch.object(team, "rex_json", side_effect=replies):
            self.assertEqual(team.observe({"session": "session"}, task)["state"], "unknown")

    def test_replaced_agent_invalidates_binding(self):
        task = {"agent": "pi", "block": "worker", "process": {"pid": 42, "name": "node"}}
        with patch.object(team, "rex_json", return_value={"child": {"argv0": "pi", "pid": 43, "name": "node"}}):
            self.assertEqual(team.observe({"session": "session"}, task)["state"], "wrong_process")

    def test_both_original_and_current_manager_are_protected(self):
        for block in ("old-manager", "new-manager"):
            with patch.dict(os.environ, {"REX_BLOCK": "new-manager"}):
                with self.assertRaises(ValueError):
                    team.guard({"manager_block": "old-manager"}, {"block": block})


class RecordTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name).resolve()
        self.record = self.root / "team.json"
        self.prompt = self.root / "prompt.md"
        self.prompt.write_text("Make one small change")
        team.save(self.record, {"version": 1, "session": "session", "manager_block": "manager", "tasks": {}})

    def call(self, *arguments):
        with patch("sys.argv", [str(SCRIPT), str(self.record), *map(str, arguments)]):
            return team.main()

    def add(self, name="one", *extra):
        self.call("add", name, "--agent", "pi", "--model", "small", "--cwd", self.root,
                  "--prompt", self.prompt, "--report", self.root / "REPORT.md", *extra)

    def test_existing_run_cannot_be_overwritten(self):
        with self.assertRaisesRegex(ValueError, "already exists"):
            self.call("init", "--session", "session", "--manager-block", "manager")

    def test_conversation_id_can_be_recorded_before_launch(self):
        self.add()
        self.call("conversation", "one", "--id", "native-session-123")
        task = team.read_team(self.record)["tasks"]["one"]
        self.assertEqual(task["conversation_id"], "native-session-123")
        self.assertIsNone(task["block"])

    def test_conversation_id_cannot_be_silently_replaced(self):
        self.add()
        self.call("conversation", "one", "--id", "native-session-123")
        self.call("conversation", "one", "--id", "native-session-123")
        with self.assertRaisesRegex(ValueError, "already recorded"):
            self.call("conversation", "one", "--id", "unrelated-session")
        self.assertEqual(team.read_team(self.record)["tasks"]["one"]["conversation_id"], "native-session-123")

    def test_invalid_conversation_id_is_not_recorded(self):
        self.add()
        for conversation_id in ("", "not an id", "../session.jsonl", "id\x1b"):
            with self.assertRaisesRegex(ValueError, "conversation ID"):
                self.call("conversation", "one", "--id", conversation_id)
        self.assertIsNone(team.read_team(self.record)["tasks"]["one"]["conversation_id"])

    def test_editing_tasks_cannot_share_a_workspace(self):
        self.add()
        with self.assertRaisesRegex(ValueError, "separate workspaces"):
            self.add("two")
        self.add("review", "--read-only")

    def test_dependency_must_be_verified_before_binding(self):
        self.add()
        self.add("two", "--read-only", "--depends", "one")
        with self.assertRaisesRegex(ValueError, "verify dependencies"):
            self.call("bind", "two", "--block", "worker")

    def test_send_failure_keeps_uncertain_delivery_record(self):
        self.add()
        record = team.read_team(self.record)
        record["tasks"]["one"].update(block="worker", process={"pid": 42, "name": "node"}, turn=1)
        team.save(self.record, record)
        with patch.object(team, "observe", return_value={"state": "done", "updated_at": "before"}):
            with patch.object(team, "rex", side_effect=RuntimeError("connection failed")):
                with self.assertRaises(RuntimeError):
                    self.call("send", "one", "--file", self.prompt)
        task = team.read_team(self.record)["tasks"]["one"]
        self.assertEqual(task["phase"], "sending")
        self.assertEqual(task["since"], "before")
        self.assertEqual(task["turn"], 2)
        self.assertEqual(task["followups"], [{"turn": 2, "prompt": str(self.prompt)}])

    def test_sent_followup_keeps_its_prompt_path(self):
        self.add()
        followup = self.root / "turn-2.md"
        followup.write_text("Make the specific correction")
        record = team.read_team(self.record)
        record["tasks"]["one"].update(block="worker", process={"pid": 42, "name": "node"}, turn=1)
        team.save(self.record, record)
        with patch.object(team, "observe", return_value={"state": "done", "updated_at": "before"}):
            with patch.object(team, "rex"), patch.object(team.time, "sleep"):
                self.call("send", "one", "--file", followup)
        task = team.read_team(self.record)["tasks"]["one"]
        self.assertEqual(task["prompt"], str(self.prompt))
        self.assertEqual(task["followups"], [{"turn": 2, "prompt": str(followup)}])
        self.assertEqual(task["phase"], "assigned")

    def test_busy_worker_is_not_typed_into(self):
        self.add()
        record = team.read_team(self.record)
        record["tasks"]["one"]["block"] = "worker"
        team.save(self.record, record)
        with patch.object(team, "observe", return_value={"state": "working"}):
            with patch.object(team, "rex") as rex:
                with self.assertRaisesRegex(ValueError, "not ready"):
                    self.call("send", "one", "--file", self.prompt)
                rex.assert_not_called()

    def test_second_send_cannot_reuse_stale_done(self):
        self.add()
        record = team.read_team(self.record)
        record["tasks"]["one"].update(block="worker", since="before", turn=2)
        team.save(self.record, record)
        with patch.object(team, "observe", return_value={"state": "done", "updated_at": "before"}):
            with patch.object(team, "rex") as rex:
                with self.assertRaisesRegex(ValueError, "not ready"):
                    self.call("send", "one", "--file", self.prompt)
                rex.assert_not_called()

    def test_worker_done_does_not_mark_task_verified(self):
        self.add()
        record = team.read_team(self.record)
        record["tasks"]["one"]["block"] = "worker"
        team.save(self.record, record)
        with patch.object(team, "observe", return_value={"state": "done", "updated_at": "now"}):
            with patch("sys.stdout", io.StringIO()):
                self.assertEqual(self.call("wait", "one", "--timeout", "0"), 0)
        self.assertEqual(team.read_team(self.record)["tasks"]["one"]["phase"], "planned")


if __name__ == "__main__":
    unittest.main()
