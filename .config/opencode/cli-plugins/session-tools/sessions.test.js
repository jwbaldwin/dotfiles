import assert from "node:assert/strict";
import test from "node:test";
import { backgroundReply, sessionStatus } from "./sessions.ts";

test("pending child questions take priority over running and failed sessions", () => {
  const statuses = new Map([
    ["root", "running"],
    ["child", "idle"],
  ]);
  const questions = new Map([["child", [{ id: "question" }]]]);
  const permissions = new Map();
  const context = {
    data: {
      session: {
        family: () => ["root", "child"],
        get: () => ({ outcome: "failed", location: { directory: "/project" } }),
        status: (id) => statuses.get(id),
        form: { list: (id) => questions.get(id) },
        permission: { list: (id) => permissions.get(id) },
      },
    },
  };
  assert.equal(sessionStatus(context, "root"), "attention");
  questions.clear();
  assert.equal(sessionStatus(context, "root"), "busy");
  permissions.set("child", [{ id: "permission" }]);
  assert.equal(sessionStatus(context, "root"), "attention");
  permissions.clear();
  statuses.set("root", "idle");
  assert.equal(sessionStatus(context, "root"), "error");
});

test("background results exclude inherited answers and reasoning", () => {
  const inherited = {
    type: "assistant",
    time: { created: 1 },
    content: [{ type: "text", text: "Original answer" }],
  };
  assert.equal(backgroundReply([inherited], "background"), undefined);
  const prompt = { type: "user", metadata: { "session-tools.background": "background" } };
  assert.equal(backgroundReply([inherited, prompt], "background"), undefined);
  const response = {
    type: "assistant",
    time: { created: 3 },
    content: [
      { type: "reasoning", text: "Private reasoning" },
      { type: "text", text: "Task result" },
    ],
  };
  assert.equal(backgroundReply([inherited, prompt, response], "background"), "Task result");
});
