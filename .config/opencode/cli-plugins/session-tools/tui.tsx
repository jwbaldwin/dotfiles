import { Plugin } from "@opencode/plugin/tui";
import { createEffect, createRoot, Show } from "solid-js";

import { setupBackground } from "./background.ts";
import { BackgroundResult } from "./background-result.tsx";
import { setupBtw } from "./btw.tsx";
import { setupParking } from "./parking.ts";
import { PromptInfo } from "./prompt-info.tsx";
import { currentSessionID, sessionStatus, showError } from "./sessions.ts";
import { trackTmuxStatus } from "./tmux-status.js";

export default Plugin.define({
  id: "james.session-tools",
  setup(context) {
    return createRoot((dispose) => {
      const parking = setupParking(context);
      const background = setupBackground(context);
      const btw = setupBtw(context);
      const removePromptStatus = context.ui.slot({
        replace: "prompt.footer.status",
        render: (prompt) => (
          <PromptInfo
            context={context}
            sessionID={prompt.sessionID}
            mode={prompt.mode}
          />
        ),
      });
      const commands = [
        ...parking.commands,
        ...background.commands,
        ...btw.commands,
      ];
      const removeCommands = context.ui.slot({
        append: "app",
        render: () => {
          context.keymap.layer(() => ({
            mode: "global",
            commands: commands.map((command) => ({
              ...command,
              run: async (input, event) => {
                try {
                  await command.run(input, event);
                } catch (error) {
                  showError(context, error);
                }
              },
            })),
          }));
          return null;
        },
      });

      const refreshed = new Set<string>();
      const relatedSessions = (sessionID: string) => [
        sessionID,
        ...context.data.session.family(sessionID),
        ...Object.values(background.state.tasks)
          .filter((task) => task.originSessionID === sessionID)
          .flatMap((task) => [
            task.sessionID,
            ...context.data.session.family(task.sessionID),
          ]),
      ];
      createEffect(() => {
        const sessionID = currentSessionID(context);
        if (!sessionID) return;
        for (const id of new Set(relatedSessions(sessionID))) {
          if (refreshed.has(id)) continue;
          refreshed.add(id);
          void context.data.session
            .sync(id)
            .then(() =>
              Promise.all([
                context.data.session.permission.sync(id),
                context.data.session.form.sync(
                  id,
                  context.data.session.get(id)?.location,
                ),
              ]),
            )
            .catch((error) => showError(context, error));
        }
      });

      const stopTmux = trackTmuxStatus(() => {
        const sessionID = currentSessionID(context);
        if (!sessionID) return "idle";
        const statuses = relatedSessions(sessionID).map((id) =>
          sessionStatus(context, id),
        );
        if (statuses.includes("attention")) return "attention";
        if (
          statuses.includes("busy") ||
          (btw.state.question?.sessionID === sessionID &&
            btw.state.question.status === "running")
        )
          return "busy";
        return parking.state.sessions[sessionID]
          ? "parked"
          : sessionStatus(context, sessionID);
      });
      const removeReminder = context.ui.slot({
        append: "session.composer.top",
        render: (session) => (
          <box flexDirection="column">
            <BackgroundResult
              context={context}
              sessionID={session.sessionID}
              background={background}
            />
            <Show when={parking.state.sessions[session.sessionID]}>
              {(record) => (
                <text fg={context.theme.text.base}>
                  ◌ Parked{record().note ? ` — ${record().note}` : ""}
                </text>
              )}
            </Show>
            <Show
              when={Object.values(background.state.tasks).some(
                (task) => task.originSessionID === session.sessionID,
              )}
            >
                <text fg={context.theme.text.base}>
                Background tasks:{" "}
                {
                  Object.values(background.state.tasks).filter(
                    (task) => task.originSessionID === session.sessionID,
                  ).length
                }{" "}
                · /bg to view
              </text>
            </Show>
          </box>
        ),
      });
      return () => {
        stopTmux();
        parking.dispose();
        background.dispose();
        btw.dispose();
        removeReminder();
        removeCommands();
        removePromptStatus();
        dispose();
      };
    });
  },
});
