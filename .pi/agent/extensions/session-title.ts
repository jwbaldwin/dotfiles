import { spawnSync } from "node:child_process";
import path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_OPTION = "@pi-status";
const STATUS_ICON_OPTION = "@pi-status-icon";
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const SPINNER_INTERVAL_MS = 80;

export default function sessionTitle(pi: ExtensionAPI) {
  const tmuxPane = process.env.TMUX_PANE;
  let timer: ReturnType<typeof setInterval> | undefined;
  let frame = 0;

  const runTmux = (...args: string[]) => {
    if (process.env.TMUX && tmuxPane) {
      spawnSync("tmux", args, { stdio: "ignore" });
    }
  };

  const setPaneOption = (option: string, value: string) => {
    runTmux("set-option", "-p", "-t", tmuxPane!, option, value);
  };

  const unsetPaneOption = (option: string) => {
    runTmux("set-option", "-p", "-u", "-t", tmuxPane!, option);
  };

  const renderTitle = (ctx: ExtensionContext) => {
    ctx.ui.setTitle(pi.getSessionName() ?? path.basename(ctx.cwd));
  };

  const stopSpinner = () => {
    clearInterval(timer);
    timer = undefined;
    frame = 0;
  };

  const setIdle = () => {
    stopSpinner();
    unsetPaneOption(STATUS_OPTION);
    setPaneOption(STATUS_ICON_OPTION, "✓");
  };

  const setWorking = () => {
    stopSpinner();
    setPaneOption(STATUS_OPTION, "working");
    setPaneOption(STATUS_ICON_OPTION, SPINNER_FRAMES[frame]);
    timer = setInterval(() => {
      frame = (frame + 1) % SPINNER_FRAMES.length;
      setPaneOption(STATUS_ICON_OPTION, SPINNER_FRAMES[frame]);
    }, SPINNER_INTERVAL_MS);
    timer.unref?.();
  };

  const clearStatus = () => {
    stopSpinner();
    unsetPaneOption(STATUS_OPTION);
    unsetPaneOption(STATUS_ICON_OPTION);
  };

  pi.on("session_start", (_event, ctx) => {
    renderTitle(ctx);
    setIdle();
  });
  pi.on("session_info_changed", (_event, ctx) => renderTitle(ctx));
  pi.on("agent_start", setWorking);
  pi.on("agent_settled", setIdle);
  pi.on("session_shutdown", clearStatus);
}
