import path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const SPINNER_INTERVAL_MS = 80;
const STARTUP_DELAY_MS = 100;

export default function sessionTitle(pi: ExtensionAPI) {
  let timer: ReturnType<typeof setInterval> | undefined;
  let startupTimer: ReturnType<typeof setTimeout> | undefined;
  let frame = 0;
  let state: "idle" | "working" = "idle";

  const label = (ctx: ExtensionContext) =>
    pi.getSessionName() ?? path.basename(ctx.cwd);

  const render = (ctx: ExtensionContext) => {
    const status = state === "working" ? SPINNER_FRAMES[frame] : ">";
    ctx.ui.setTitle(`${status} ${label(ctx)}`);
  };

  const stopSpinner = () => {
    clearInterval(timer);
    timer = undefined;
    frame = 0;
  };

  const setIdle = (ctx: ExtensionContext) => {
    stopSpinner();
    state = "idle";
    render(ctx);
  };

  const setWorking = (ctx: ExtensionContext) => {
    stopSpinner();
    state = "working";
    render(ctx);
    timer = setInterval(() => {
      frame = (frame + 1) % SPINNER_FRAMES.length;
      render(ctx);
    }, SPINNER_INTERVAL_MS);
    timer.unref?.();
  };

  pi.on("session_start", (_event, ctx) => {
    startupTimer = setTimeout(() => setIdle(ctx), STARTUP_DELAY_MS);
  });
  pi.on("session_info_changed", (_event, ctx) => render(ctx));
  pi.on("agent_start", (_event, ctx) => setWorking(ctx));
  pi.on("agent_settled", (_event, ctx) => setIdle(ctx));
  pi.on("session_shutdown", (_event, ctx) => {
    clearTimeout(startupTimer);
    setIdle(ctx);
  });
}
