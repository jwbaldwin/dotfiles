import { spawnSync } from "node:child_process";

const frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const icons = { idle: "✓", parked: "◌", attention: "?", error: "!" };

export function trackTmuxStatus(readStatus) {
  const pane = process.env.TMUX_PANE;
  if (!process.env.TMUX || !pane) return () => {};

  let previous;
  let frame = 0;
  const tmux = (...args) => spawnSync("tmux", args, { stdio: "ignore", timeout: 1000 });
  const update = () => {
    const status = readStatus();
    if (status !== previous) {
      frame = 0;
      tmux("set-option", "-p", "-t", pane, "@opencode-status", status);
    }
    if (status !== previous || status === "busy") {
      const icon = status === "busy" ? frames[frame++ % frames.length] : icons[status];
      tmux("set-option", "-p", "-t", pane, "@opencode-status-icon", icon);
    }
    previous = status;
  };

  update();
  const timer = setInterval(update, 80);
  timer.unref();
  const clear = () => {
    clearInterval(timer);
    tmux("set-option", "-p", "-u", "-t", pane, "@opencode-status");
    tmux("set-option", "-p", "-u", "-t", pane, "@opencode-status-icon");
  };
  process.once("exit", clear);
  return () => {
    process.removeListener("exit", clear);
    clear();
  };
}
