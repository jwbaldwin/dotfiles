import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

import { spawnSync } from "node:child_process";
import path from "node:path";

import {
  PARKING_STATUS_EVENT,
  isParkingStatusEvent,
  readParkedSession,
} from "./parking/storage.ts";

const STATUS_OPTION = "@pi-status";
const STATUS_ICON_OPTION = "@pi-status-icon";
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const SPINNER_INTERVAL_MS = 80;

export default function sessionTitle(pi: ExtensionAPI) {
  const tmuxPane = process.env.TMUX_PANE;
  let timer: ReturnType<typeof setInterval> | undefined;
  let frame = 0;
  let parked = false;
  let statusBeforePrompt: "idle" | "parked" | "working" = "idle";

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
    setPaneOption(STATUS_OPTION, "idle");
    setPaneOption(STATUS_ICON_OPTION, "✓");
  };

  const setParked = () => {
    stopSpinner();
    setPaneOption(STATUS_OPTION, "parked");
    setPaneOption(STATUS_ICON_OPTION, "◌");
  };

  const setWaitingForInput = () => {
    stopSpinner();
    setPaneOption(STATUS_OPTION, "waiting-for-input");
    setPaneOption(STATUS_ICON_OPTION, "?");
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

  const showRestingStatus = () => {
    if (parked) setParked();
    else setIdle();
  };

  const clearStatus = () => {
    stopSpinner();
    unsetPaneOption(STATUS_OPTION);
    unsetPaneOption(STATUS_ICON_OPTION);
  };

  const unsubscribeParkingStatus = pi.events.on(
    PARKING_STATUS_EVENT,
    (value) => {
      if (!isParkingStatusEvent(value)) return;
      parked = value.parked;
      showRestingStatus();
    },
  );

  pi.on("session_start", async (_event, ctx) => {
    renderTitle(ctx);
    parked = Boolean(
      await readParkedSession(ctx.sessionManager.getSessionId()),
    );
    showRestingStatus();
  });
  pi.on("session_info_changed", (_event, ctx) => renderTitle(ctx));
  pi.on("agent_start", setWorking);
  pi.on("agent_settled", showRestingStatus);
  pi.on("ui_prompt_start", () => {
    statusBeforePrompt = timer ? "working" : parked ? "parked" : "idle";
    setWaitingForInput();
  });
  pi.on("ui_prompt_end", () => {
    if (statusBeforePrompt === "working") setWorking();
    else showRestingStatus();
  });
  pi.on("session_shutdown", () => {
    unsubscribeParkingStatus();
    clearStatus();
  });
}
