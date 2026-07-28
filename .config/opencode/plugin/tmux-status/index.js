import { spawnSync } from "node:child_process";

const STATUS_OPTION = "@opencode-status";
const STATUS_ICON_OPTION = "@opencode-status-icon";
const ICON = {
  idle: "✓",
  busy: "◉",
  attention: "?",
  error: "!",
};

const runTmux = (...args) => {
  spawnSync("tmux", args, { stdio: "ignore" });
};

const TmuxStatusTuiPlugin = async (api) => {
  const tmuxPane = process.env.TMUX_PANE;
  if (!process.env.TMUX || !tmuxPane) return;
  let currentStatus;
  const parentSessionIDs = new Map();

  const setPaneOption = (option, value) => {
    runTmux("set-option", "-p", "-t", tmuxPane, option, value);
  };

  const unsetPaneOption = (option) => {
    runTmux("set-option", "-p", "-u", "-t", tmuxPane, option);
  };

  const applyStatus = (status) => {
    if (status === currentStatus) return;
    currentStatus = status;

    if (status === "off") {
      unsetPaneOption(STATUS_OPTION);
      unsetPaneOption(STATUS_ICON_OPTION);
      return;
    }

    if (status === "idle") {
      unsetPaneOption(STATUS_OPTION);
    } else {
      setPaneOption(STATUS_OPTION, status);
    }
    setPaneOption(STATUS_ICON_OPTION, ICON[status]);
  };

  const selectedSessionID = () => {
    const route = api.route.current;
    return route.name === "session" ? route.params.sessionID : undefined;
  };

  const belongsToSelectedSession = (sessionID) => {
    const selected = selectedSessionID();
    while (sessionID) {
      if (sessionID === selected) return true;
      sessionID = parentSessionIDs.get(sessionID);
    }
    return false;
  };

  const syncSelectedSession = () => {
    if (!api.state.ready) return;

    const sessionID = selectedSessionID();
    if (!sessionID) {
      applyStatus("idle");
      return;
    }

    if (
      api.state.session.permission(sessionID).length > 0 ||
      api.state.session.question(sessionID).length > 0
    ) {
      applyStatus("attention");
      return;
    }

    const type = api.state.session.status(sessionID)?.type;
    applyStatus(type === "busy" || type === "retry" ? "busy" : "idle");
  };

  const handleEvent = (event) => {
    const sessionID = event.properties?.sessionID;

    if (event.type === "session.created" || event.type === "session.updated") {
      const info = event.properties?.info;
      if (info?.id && info.parentID) parentSessionIDs.set(info.id, info.parentID);
      return;
    }

    if (event.type === "tui.session.select" || event.type === "server.connected") {
      syncSelectedSession();
      return;
    }

    if (event.type === "permission.asked" || event.type === "question.asked") {
      if (belongsToSelectedSession(sessionID)) applyStatus("attention");
      return;
    }

    if (
      event.type === "permission.replied" ||
      event.type === "question.replied" ||
      event.type === "question.rejected"
    ) {
      if (belongsToSelectedSession(sessionID)) syncSelectedSession();
      return;
    }

    if (sessionID !== selectedSessionID()) return;

    if (event.type === "session.status") {
      const type = event.properties?.status?.type;
      if (type === "busy" || type === "retry") applyStatus("busy");
      if (type === "idle") applyStatus("idle");
      return;
    }

    if (event.type === "session.idle") {
      applyStatus("idle");
      return;
    }

    if (event.type === "session.error") {
      applyStatus("error");
    }
  };

  // Remove values left by the old server-side plugin, which used window scope.
  runTmux("set-option", "-w", "-u", "-t", tmuxPane, STATUS_OPTION);
  runTmux("set-option", "-w", "-u", "-t", tmuxPane, STATUS_ICON_OPTION);

  const eventTypes = [
    "server.connected",
    "tui.session.select",
    "session.created",
    "session.updated",
    "session.status",
    "session.idle",
    "session.error",
    "permission.asked",
    "permission.replied",
    "question.asked",
    "question.replied",
    "question.rejected",
  ];
  const unsubscribe = eventTypes.map((type) => api.event.on(type, handleEvent));
  const clearStatus = () => applyStatus("off");
  let lastSelectedSessionID;
  let stateWasReady = false;
  const syncTimer = setInterval(() => {
    const selected = selectedSessionID();
    if (!api.state.ready) return;
    if (stateWasReady && selected === lastSelectedSessionID) return;
    stateWasReady = true;
    lastSelectedSessionID = selected;
    syncSelectedSession();
  }, 100);

  api.lifecycle.onDispose(() => {
    clearInterval(syncTimer);
    for (const stop of unsubscribe) stop();
    clearStatus();
    process.removeListener("exit", clearStatus);
  });
  process.once("exit", clearStatus);

  applyStatus("idle");
};

export default {
  id: "tmux-status",
  tui: TmuxStatusTuiPlugin,
};
