import type { Context, KeymapCommand } from "@opencode/plugin/tui/context";
import type { BackgroundTask } from "./types.ts";
import { copyText } from "./clipboard.js";
import { backgroundReply, currentSessionID, sessionStatus, showError } from "./sessions.ts";

export function setupBackground(context: Context) {
  const [state, update] = context.storage.store<{ tasks: Record<string, BackgroundTask> }>(
    "background",
    { initial: { tasks: {} } },
  );
  const stop = context.data.listen(({ details }) => {
    if (details.type === "session.deleted" && state.tasks[details.data.sessionID]) {
      void update((draft) => {
        delete draft.tasks[details.data.sessionID];
      }).catch((error) => showError(context, error));
      return;
    }
    if (
      details.type !== "session.execution.succeeded" &&
      details.type !== "session.execution.failed" &&
      details.type !== "session.execution.interrupted"
    )
      return;
    const task = state.tasks[details.data.sessionID];
    if (!task) return;
    context.ui.toast.show({
      title:
        details.type === "session.execution.succeeded"
          ? "Background task complete"
          : "Background task stopped",
      message: `${task.task.slice(0, 100)} — /bg to view`,
      variant: details.type === "session.execution.failed" ? "error" : "info",
    });
  });

  const browse = async () => {
    const tasks = Object.values(state.tasks).sort((a, b) => b.startedAt - a.startedAt);
    if (!tasks.length) {
      context.ui.toast.show({ message: "No background tasks yet. Use /bg <task>." });
      return;
    }
    const task = await context.ui.dialog.select({
      title: "Background tasks",
      options: tasks.map((task) => ({
        title: task.task,
        value: task,
        description:
          task.error ??
          `${sessionStatus(context, task.sessionID)} · ${context.ui.format.path(task.directory)}`,
      })),
    });
    if (!task) return;
    const sessionID = task.sessionID;
    let reply: string | undefined;
    try {
      reply = backgroundReply(await context.client.session.context({ sessionID }), sessionID);
      await context.data.session.sync(sessionID);
    } catch (error) {
      showError(context, error);
      const remove = await context.ui.dialog.confirm({
        title: "Task unavailable",
        message: "Remove this entry from the background task list?",
      });
      if (remove)
        await update((draft) => {
          delete draft.tasks[sessionID];
        });
      return;
    }
    await context.ui.dialog.alert({
      title: task.task,
      message: task.error ?? reply ?? "No background response yet.",
    });
    const action = await context.ui.dialog.select({
      title: "Background task",
      options: [
        { title: "Open task session", value: "open" },
        { title: "Copy result", value: "copy", disabled: !reply },
        { title: "Bring result into original chat", value: "bring", disabled: !reply },
        { title: "Stop task", value: "stop" },
        { title: "Remove from task list", value: "remove" },
      ],
    });
    if (action === "open") context.ui.router.navigate({ type: "session", sessionID });
    if (action === "copy" && reply) {
      await copyText(reply);
      context.ui.toast.show({ message: "Copied result." });
    }
    if (action === "bring" && reply) {
      await context.client.session.synthetic({
        sessionID: task.originSessionID,
        text: `Background task: ${task.task}\n\n${reply}`,
        resume: false,
      });
      context.ui.toast.show({ message: "Result queued for the next turn in the original chat." });
    }
    if (action === "stop") await context.client.session.interrupt({ sessionID, continue: false });
    if (action === "remove")
      await update((draft) => {
        delete draft.tasks[sessionID];
      });
  };

  const commands: KeymapCommand[] = [
    {
      id: "session-tools.bg",
      title: "Run or view background tasks",
      group: "Session tools",
      palette: true,
      slash: { name: "bg", arguments: true },
      run: async (input = "") => {
        const task = input.trim();
        if (!task) return browse();
        const originSessionID = currentSessionID(context);
        if (!originSessionID) {
          context.ui.toast.show({ message: "Open a session before starting /bg." });
          return;
        }
        const origin = await context.client.session.get({ sessionID: originSessionID });
        const messages = await context.client.session.context({ sessionID: originSessionID });
        const detached = messages.length
          ? await context.client.session.fork({
              sessionID: originSessionID,
              boundary: { type: "through" },
            })
          : await context.client.session.create({
              location: origin.location,
              agent: origin.agent,
              model: origin.model,
              permissions: origin.permissions,
            });
        const sessionID = detached.id;
        await update((draft) => {
          draft.tasks[sessionID] = {
            sessionID,
            originSessionID,
            task,
            directory: origin.location.directory,
            startedAt: Date.now(),
          };
        });
        try {
          await context.client.session.rename({ sessionID, title: `BG: ${task.slice(0, 90)}` });
          await context.client.session.prompt({
            sessionID,
            metadata: { "session-tools.background": sessionID },
            text: `Complete this background task using the conversation context and available tools. Return a concise result with useful links or identifiers.\n\n${task}`,
          });
          await context.data.session.sync(sessionID);
          context.ui.toast.show({
            title: "Background task started",
            message: "/bg to view, copy, open, or stop it.",
          });
        } catch (error) {
          await update((draft) => {
            const saved = draft.tasks[sessionID];
            if (saved) saved.error = error instanceof Error ? error.message : String(error);
          });
          showError(context, error);
        }
      },
    },
  ];
  return { state, commands, dispose: stop };
}
