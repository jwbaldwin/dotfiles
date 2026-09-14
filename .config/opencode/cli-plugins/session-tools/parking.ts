import type { Context, KeymapCommand } from "@opencode/plugin/tui/context";
import type { ParkedSession } from "./types.ts";
import { currentSessionID, lastReply, showError } from "./sessions.ts";

export function setupParking(context: Context) {
  const [state, update] = context.storage.store<{ sessions: Record<string, ParkedSession> }>(
    "parking",
    { initial: { sessions: {} } },
  );
  const unpark = async (sessionID: string) => {
    await update((draft) => {
      delete draft.sessions[sessionID];
    });
  };
  const stop = context.data.listen(({ details }) => {
    if (details.type === "session.renamed" && state.sessions[details.data.sessionID]) {
      void update((draft) => {
        const record = draft.sessions[details.data.sessionID];
        if (record) record.title = details.data.title;
      }).catch((error) => showError(context, error));
    }
    if (
      details.type === "session.deleted" ||
      (details.type === "session.inbox.enqueued" && details.data.item.type === "user")
    ) {
      if (state.sessions[details.data.sessionID])
        void unpark(details.data.sessionID).catch((error) => showError(context, error));
    }
  });

  const commands: KeymapCommand[] = [
    {
      id: "session-tools.park",
      title: "Park this session",
      group: "Session tools",
      palette: true,
      slash: { name: "park", arguments: true },
      enabled: () => Boolean(currentSessionID(context)),
      run: async (note = "") => {
        const sessionID = currentSessionID(context);
        if (!sessionID) return;
        const session = await context.client.session.get({ sessionID });
        await update((draft) => {
          draft.sessions[sessionID] = {
            sessionID,
            title: session.title ?? "Untitled session",
            directory: session.location.directory,
            note: note.trim() || draft.sessions[sessionID]?.note || "",
            parkedAt: Date.now(),
          };
        });
        context.ui.toast.show({ message: "Session parked.", variant: "success" });
      },
    },
    {
      id: "session-tools.unpark",
      title: "Unpark this session",
      group: "Session tools",
      palette: true,
      slash: { name: "unpark" },
      enabled: () => Boolean(currentSessionID(context)),
      run: async () => {
        const sessionID = currentSessionID(context);
        if (!sessionID) return;
        const parked = Boolean(state.sessions[sessionID]);
        await unpark(sessionID);
        context.ui.toast.show({
          message: parked ? "Session unparked." : "This session is not parked.",
        });
      },
    },
    {
      id: "session-tools.inbox",
      title: "Open parking inbox",
      group: "Session tools",
      palette: true,
      slash: { name: "inbox" },
      run: async () => {
        while (true) {
          const records = Object.values(state.sessions).sort((a, b) => b.parkedAt - a.parkedAt);
          if (!records.length) {
            context.ui.toast.show({ message: "The parking inbox is empty." });
            return;
          }
          const record = await context.ui.dialog.select({
            title: "Parked sessions",
            options: records.map((record) => ({
              title: context.data.session.get(record.sessionID)?.title ?? record.title,
              description: record.note || context.ui.format.path(record.directory),
              value: record,
              footer: new Date(record.parkedAt).toLocaleString(),
            })),
          });
          if (!record) return;
          let reply: string;
          try {
            reply =
              lastReply(await context.client.session.context({ sessionID: record.sessionID })) ??
              "No assistant response yet.";
          } catch (error) {
            showError(context, error);
            const remove = await context.ui.dialog.confirm({
              title: "Session unavailable",
              message: "Remove this entry from the parking inbox?",
            });
            if (remove) await unpark(record.sessionID);
            continue;
          }
          await context.ui.dialog.alert({
            title: record.title,
            message: [record.directory, record.note, reply].filter(Boolean).join("\n\n"),
          });
          const action = await context.ui.dialog.select({
            title: record.title,
            options: [
              { title: "Open session", value: "open" },
              { title: "Unpark", value: "unpark" },
              { title: "Back", value: "back" },
            ],
          });
          if (action === "back") continue;
          if (action === "unpark") {
            await unpark(record.sessionID);
            continue;
          }
          if (action === "open")
            context.ui.router.navigate({ type: "session", sessionID: record.sessionID });
          return;
        }
      },
    },
  ];
  return { state, commands, dispose: stop };
}
