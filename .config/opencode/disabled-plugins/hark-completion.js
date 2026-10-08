import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { appendFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join, basename } from "node:path";

const run = promisify(execFile);
const harkctl = join(homedir(), ".local/share/mise/shims/harkctl");
const logPath = join(homedir(), "Library/Logs/Hark/completion.log");

async function log(message) {
  await appendFile(logPath, `${new Date().toISOString()} ${message}\n`);
}

export default {
  id: "hark-completion",
  setup(ctx) {
    const controller = new AbortController();

    async function notify(event) {
      if (event.type !== "session.execution.succeeded" && event.type !== "session.execution.failed") return;
      const session = await ctx.session.get({ sessionID: event.data.sessionID });
      if (session.location.directory !== ctx.location.directory || session.parentID) return;
      const title = event.type === "session.execution.failed" ? "OpenCode needs attention" : "OpenCode finished";
      const body = `${session.title || "Session"} · ${basename(ctx.location.directory)}`;
      const { stdout } = await run(harkctl, [
        "notify", body, "--title", title,
        "--idempotency-key", `opencode-completion-${event.id}`,
      ], { timeout: 15_000, signal: controller.signal });
      await log(`${event.data.sessionID} ${stdout.trim()}`);
    }

    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        try {
          await notify(event);
        } catch (error) {
          if (!controller.signal.aborted) await log(String(error));
        }
      }
    })().catch((error) => {
      if (!controller.signal.aborted) void log(`Event stream stopped: ${error}`).catch(console.error);
    });

    return () => controller.abort();
  },
};
