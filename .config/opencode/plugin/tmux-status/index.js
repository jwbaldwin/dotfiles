import { spawnSync } from "node:child_process";

const STATUS_OPTION = "@opencode-status";
const STATUS_ICON_OPTION = "@opencode-status-icon";
const IDLE_ICON = "";
const BUSY_ICON = "⣿";
const ERROR_ICON = "!";

export const TmuxStatusPlugin = async ({ $ }) => {
  const tmuxPane = process.env.TMUX_PANE;
  if (!process.env.TMUX || !tmuxPane) return {};

  let windowId;
  let currentStatus = "idle";

  const getWindowId = async () => {
    if (!windowId) {
      windowId = (
        await $`tmux display-message -t ${tmuxPane} -p '#{window_id}'`.quiet().text()
      ).trim();
    }
    return windowId;
  };

  const setWindowOption = async (option, value) => {
    const id = await getWindowId();
    await $`tmux set-option -w -t ${id} ${option} ${value}`.nothrow().quiet();
  };

  const unsetWindowOption = async (option) => {
    const id = await getWindowId();
    await $`tmux set-option -w -u -t ${id} ${option}`.nothrow().quiet();
  };

  const setStatus = async (status, icon) => {
    currentStatus = status;
    await setWindowOption(STATUS_OPTION, status);
    await setWindowOption(STATUS_ICON_OPTION, icon);
  };

  const clearStatus = async () => {
    currentStatus = "idle";
    await unsetWindowOption(STATUS_OPTION);
    await setWindowOption(STATUS_ICON_OPTION, IDLE_ICON);
  };

  const clearStatusSync = () => {
    if (!windowId || currentStatus === "idle") return;
    spawnSync("tmux", ["set-option", "-w", "-u", "-t", windowId, STATUS_OPTION], {
      stdio: "ignore",
    });
    spawnSync("tmux", ["set-option", "-w", "-u", "-t", windowId, STATUS_ICON_OPTION], {
      stdio: "ignore",
    });
  };

  process.once("exit", clearStatusSync);

  await setWindowOption(STATUS_ICON_OPTION, IDLE_ICON);

  return {
    event: async ({ event }) => {
      if (event.type === "session.status") {
        const statusType = event.properties?.status?.type;
        if (statusType === "busy" || statusType === "retry") {
          await setStatus("busy", BUSY_ICON);
        } else if (statusType === "idle" && currentStatus !== "error") {
          await clearStatus();
        }
        return;
      }

      if (event.type === "session.idle" && currentStatus !== "error") {
        await clearStatus();
        return;
      }

      if (event.type === "session.error") {
        await setStatus("error", ERROR_ICON);
      }
    },
    "chat.message": async () => {
      await setStatus("busy", BUSY_ICON);
    },
  };
};

export default TmuxStatusPlugin;
