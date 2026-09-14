import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { trackTmuxStatus } from "./tmux-status.js";

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

test("shows busy animation, attention, parked and idle states in a real tmux pane, then cleans up", async () => {
  const socket = `opencode-v2-status-${process.pid}`;
  const tmux = (...args) => {
    const result = spawnSync("tmux", ["-L", socket, ...args], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  };
  const oldTmux = process.env.TMUX;
  const oldPane = process.env.TMUX_PANE;
  let stop;
  try {
    tmux("-f", "/dev/null", "new-session", "-d", "-s", "test");
    const pane = tmux("display-message", "-p", "-t", "test", "#{pane_id}");
    process.env.TMUX = `${tmux("display-message", "-p", "-t", "test", "#{socket_path}")},0,0`;
    process.env.TMUX_PANE = pane;
    const icon = () => tmux("show-options", "-pv", "-t", pane, "@opencode-status-icon");
    let status = "busy";
    stop = trackTmuxStatus(() => status);
    const first = icon();
    await wait(120);
    assert.notEqual(icon(), first);
    for (const [next, expected] of [
      ["attention", "?"],
      ["busy", null],
      ["parked", "◌"],
      ["idle", "✓"],
      ["error", "!"],
    ]) {
      status = next;
      await wait(120);
      assert.equal(tmux("show-options", "-pv", "-t", pane, "@opencode-status"), next);
      if (expected) assert.equal(icon(), expected);
    }
    stop();
    stop = undefined;
    assert.equal(tmux("display-message", "-p", "-t", pane, "#{@opencode-status-icon}"), "");
    assert.equal(tmux("display-message", "-p", "-t", pane, "#{@opencode-status}"), "");
  } finally {
    stop?.();
    if (oldTmux === undefined) delete process.env.TMUX;
    else process.env.TMUX = oldTmux;
    if (oldPane === undefined) delete process.env.TMUX_PANE;
    else process.env.TMUX_PANE = oldPane;
    tmux("kill-server");
  }
});
