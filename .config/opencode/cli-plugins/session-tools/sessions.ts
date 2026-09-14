import type { SessionMessageInfo } from "@opencode/client";
import type { Context } from "@opencode/plugin/tui/context";

export function currentSessionID(context: Context) {
  const route = context.ui.router.current();
  return route.type === "session" ? route.sessionID : undefined;
}

export function lastReply(messages: readonly SessionMessageInfo[]) {
  for (const message of messages.toReversed()) {
    if (message.type !== "assistant") continue;
    const text = message.content
      .filter((part) => part.type === "text")
      .map((part) => part.text)
      .join("\n")
      .trim();
    if (text) return text;
  }
}

export function backgroundReply(messages: readonly SessionMessageInfo[], sessionID: string) {
  const start = messages.findIndex(
    (message) =>
      message.type === "user" && message.metadata?.["session-tools.background"] === sessionID,
  );
  return start === -1 ? undefined : lastReply(messages.slice(start + 1));
}

export function sessionStatus(context: Context, sessionID: string) {
  const family = context.data.session.family(sessionID);
  const ids = new Set([sessionID, ...family]);
  for (const id of ids) {
    const location = context.data.session.get(id)?.location;
    if (
      context.data.session.permission.list(id)?.length ||
      context.data.session.form.list(id, location)?.length
    )
      return "attention";
  }
  if ([...ids].some((id) => context.data.session.status(id) === "running")) return "busy";
  return context.data.session.get(sessionID)?.outcome === "failed" ? "error" : "idle";
}

export function showError(context: Context, error: unknown) {
  context.ui.toast.show({
    message: error instanceof Error ? error.message : String(error),
    variant: "error",
  });
}
