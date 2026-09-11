import {
  SessionManager,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import path from "node:path";

import {
  PARKING_STATUS_EVENT,
  PARKING_WIDGET,
  listParkedSessions,
  readParkedSession,
  removeParkedSession,
  saveParkedSession,
  type ParkedSession,
} from "./storage.ts";

function sessionName(pi: ExtensionAPI, ctx: ExtensionContext): string {
  return pi.getSessionName() ?? path.basename(ctx.cwd);
}

function showParkedSessionReminder(
  ctx: ExtensionContext,
  record: ParkedSession,
): void {
  const note = record.note?.split("\n") ?? [];
  ctx.ui.setWidget(PARKING_WIDGET, ["◌ Parked", ...note], {
    placement: "aboveEditor",
  });
}

function hideParkedSessionReminder(ctx: ExtensionContext): void {
  ctx.ui.setWidget(PARKING_WIDGET, undefined);
}

function emitParkingStatus(
  pi: ExtensionAPI,
  sessionId: string,
  parked: boolean,
): void {
  pi.events.emit(PARKING_STATUS_EVENT, { version: 1, sessionId, parked });
}

async function unparkCurrentSession(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
): Promise<boolean> {
  const sessionId = ctx.sessionManager.getSessionId();
  const parkedSession = await readParkedSession(sessionId);
  if (!parkedSession) return false;

  await removeParkedSession(sessionId);
  hideParkedSessionReminder(ctx);
  emitParkingStatus(pi, sessionId, false);
  return true;
}

function compactLine(text: string, limit = 90): string {
  const line = text.replaceAll(/\s+/g, " ").trim();
  return line.length <= limit ? line : `${line.slice(0, limit - 1)}…`;
}

function relativeTime(timestamp: string): string {
  const elapsedMinutes = Math.max(
    0,
    Math.floor((Date.now() - Date.parse(timestamp)) / 60_000),
  );
  if (elapsedMinutes < 1) return "just now";
  if (elapsedMinutes < 60) return `${elapsedMinutes}m ago`;
  const elapsedHours = Math.floor(elapsedMinutes / 60);
  if (elapsedHours < 24) return `${elapsedHours}h ago`;
  return `${Math.floor(elapsedHours / 24)}d ago`;
}

function lastAssistantResponse(record: ParkedSession): string {
  try {
    const entries = SessionManager.open(record.sessionFile).getBranch();
    for (let index = entries.length - 1; index >= 0; index -= 1) {
      const entry = entries[index];
      if (entry.type !== "message" || entry.message.role !== "assistant")
        continue;
      return entry.message.content
        .filter((part) => part.type === "text")
        .map((part) => part.text)
        .join("\n\n")
        .trim();
    }
  } catch {
    return "The saved Pi session could not be read.";
  }
  return "No assistant response has been saved in this session.";
}

function parkedSessionPreview(record: ParkedSession): string {
  const sections = [
    record.name,
    record.cwd,
    `Parked ${relativeTime(record.parkedAt)}`,
  ];
  if (record.note) sections.push(`Note\n${record.note}`);
  sections.push(`Last response\n${lastAssistantResponse(record)}`);
  return sections.join("\n\n");
}

export default function parking(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    const record = await readParkedSession(ctx.sessionManager.getSessionId());
    if (record) showParkedSessionReminder(ctx, record);
    else hideParkedSessionReminder(ctx);
    emitParkingStatus(pi, ctx.sessionManager.getSessionId(), Boolean(record));
  });

  pi.on("session_info_changed", async (_event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    const record = await readParkedSession(sessionId);
    if (!record) return;
    await saveParkedSession({ ...record, name: sessionName(pi, ctx) });
  });

  pi.on("input", async (event, ctx) => {
    if (event.source === "extension") return;
    await unparkCurrentSession(pi, ctx);
  });

  pi.registerCommand("park", {
    description: "Park this session with an optional note",
    handler: async (args, ctx) => {
      const sessionFile = ctx.sessionManager.getSessionFile();
      if (!sessionFile) {
        ctx.ui.notify(
          "This session is not saved, so it cannot be parked.",
          "error",
        );
        return;
      }

      const sessionId = ctx.sessionManager.getSessionId();
      const existingRecord = await readParkedSession(sessionId);
      const note = args.trim() || existingRecord?.note;
      const record: ParkedSession = {
        version: 1,
        sessionId,
        sessionFile,
        cwd: ctx.cwd,
        name: sessionName(pi, ctx),
        ...(note ? { note } : {}),
        parkedAt: new Date().toISOString(),
      };

      await saveParkedSession(record);
      showParkedSessionReminder(ctx, record);
      emitParkingStatus(pi, sessionId, true);
      ctx.ui.notify(
        note ? "Session parked with a note." : "Session parked.",
        "info",
      );
    },
  });

  pi.registerCommand("unpark", {
    description: "Remove this session from the parking inbox",
    handler: async (_args, ctx) => {
      const removed = await unparkCurrentSession(pi, ctx);
      ctx.ui.notify(
        removed ? "Session unparked." : "This session is not parked.",
        "info",
      );
    },
  });

  pi.registerCommand("inbox", {
    description: "Browse parked Pi sessions",
    handler: async (_args, ctx) => {
      while (true) {
        const records = await listParkedSessions();
        if (records.length === 0) {
          ctx.ui.notify("The parking inbox is empty.", "info");
          return;
        }

        const choices = records.map((record, index) => {
          const note = record.note ? ` — ${compactLine(record.note)}` : "";
          return `${index + 1}. ${record.name}${note} · ${relativeTime(record.parkedAt)}`;
        });
        const choice = await ctx.ui.select("Parked sessions", choices);
        if (!choice) return;

        const record = records[choices.indexOf(choice)];
        if (!record) return;
        await ctx.ui.editor(
          "Parked session preview",
          parkedSessionPreview(record),
        );

        const action = await ctx.ui.select(record.name, [
          "Open session",
          "Back",
          "Close inbox",
        ]);
        if (action === "Back") continue;
        if (action !== "Open session") return;
        if (record.sessionFile === ctx.sessionManager.getSessionFile()) {
          ctx.ui.notify("This parked session is already open.", "info");
          return;
        }

        try {
          await ctx.switchSession(record.sessionFile);
        } catch (error) {
          ctx.ui.notify(
            error instanceof Error ? error.message : String(error),
            "error",
          );
        }
        return;
      }
    },
  });
}
