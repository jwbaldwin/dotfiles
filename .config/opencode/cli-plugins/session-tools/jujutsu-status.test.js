import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { readJujutsuStatus } from "./jujutsu-status.ts";

test("reads the current change, nearest local bookmark, and distance from a real Jujutsu repo", async (t) => {
  const directory = mkdtempSync(join(tmpdir(), "opencode-jj-status-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const jj = (...args) =>
    execFileSync("jj", args, {
      cwd: directory,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    }).trim();
  const status = () => readJujutsuStatus(directory, new AbortController().signal);

  assert.equal(await status(), undefined);
  jj("git", "init");
  const changeID = jj("log", "--no-graph", "-r", "@", "-T", "change_id.shortest(4)");
  assert.deepEqual(await status(), { changeID, distance: 0 });

  jj("bookmark", "create", "base");
  assert.deepEqual(await status(), { changeID, bookmark: "base", distance: 0 });
  jj("new");
  jj("bookmark", "create", "feature");
  jj("new");
  jj("new");
  assert.deepEqual(await status(), {
    changeID: jj("log", "--no-graph", "-r", "@", "-T", "change_id.shortest(4)"),
    bookmark: "feature",
    distance: 2,
  });
  const controller = new AbortController();
  controller.abort();
  assert.equal(await readJujutsuStatus(directory, controller.signal), undefined);
});
