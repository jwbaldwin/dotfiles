import { spawnSync } from "node:child_process";

const STATUS_OPTION = "@opencode-status";
const STATUS_ICON_OPTION = "@opencode-status-icon";
const IDLE_ICON = "";
const BUSY_ICON = "⣿";
const ATTENTION_ICON = "?";
const ERROR_ICON = "!";

export const TmuxStatusPlugin = async ({ $ }) => {
  const tmuxPane = process.env.TMUX_PANE;
  if (!process.env.TMUX || !tmuxPane) return {};

  let currentStatus = "idle";
  let pendingStatus;
  let statusWrite = Promise.resolve();

  const setWindowOption = async (option, value) => {
    await $`tmux set-option -w -t ${tmuxPane} ${option} ${value}`.nothrow().quiet();
  };

  const unsetWindowOption = async (option) => {
    await $`tmux set-option -w -u -t ${tmuxPane} ${option}`.nothrow().quiet();
  };

  const applyStatus = async ({ status, icon }) => {
    if (status === "off") {
      await unsetWindowOption(STATUS_OPTION);
      await unsetWindowOption(STATUS_ICON_OPTION);
      return;
    }

    if (status === "idle") {
      await unsetWindowOption(STATUS_OPTION);
      await setWindowOption(STATUS_ICON_OPTION, icon);
      return;
    }

    await setWindowOption(STATUS_OPTION, status);
    await setWindowOption(STATUS_ICON_OPTION, icon);
  };

  const requestStatus = (status, icon) => {
    currentStatus = status === "off" ? "idle" : status;
    pendingStatus = { status, icon };

    statusWrite = statusWrite.catch(() => {}).then(async () => {
      while (pendingStatus) {
        const nextStatus = pendingStatus;
        pendingStatus = undefined;
        await applyStatus(nextStatus);
      }
    });

    return statusWrite;
  };

  const requestIdle = () => {
    if (currentStatus !== "error") return requestStatus("idle", IDLE_ICON);
    return statusWrite;
  };

  const clearStatus = () => requestStatus("off", "");

  const clearStatusSync = () => {
    spawnSync("tmux", ["set-option", "-w", "-u", "-t", tmuxPane, STATUS_OPTION], {
      stdio: "ignore",
    });
    spawnSync("tmux", ["set-option", "-w", "-u", "-t", tmuxPane, STATUS_ICON_OPTION], {
      stdio: "ignore",
    });
  };

  process.once("exit", clearStatusSync);

  requestStatus("idle", IDLE_ICON);

  return {
    dispose: clearStatus,
    event: async ({ event }) => {
      if (event.type === "session.status") {
        const statusType = event.properties?.status?.type;
        if (statusType === "busy" || statusType === "retry") {
          return requestStatus("busy", BUSY_ICON);
        } else if (statusType === "idle") {
          return requestIdle();
        }
        return;
      }

      if (event.type === "session.idle") {
        return requestIdle();
      }

      if (event.type === "permission.asked" || event.type === "question.asked") {
        return requestStatus("attention", ATTENTION_ICON);
      }

      if (event.type === "session.error") {
        return requestStatus("error", ERROR_ICON);
      }

      if (event.type === "server.instance.disposed") {
        await clearStatus();
      }
    },
    "chat.message": async () => {
      return requestStatus("busy", BUSY_ICON);
    },
  };
};

export default TmuxStatusPlugin;
