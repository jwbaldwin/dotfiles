import type { AssistantMessage } from "@earendil-works/pi-ai";
import type {
  AgentToolResult,
  ExtensionAPI,
  ExtensionContext,
  Theme,
  ToolRenderers,
} from "@earendil-works/pi-coding-agent";
import { Text, truncateToWidth, type Component } from "@earendil-works/pi-tui";
import { basename, dirname } from "node:path";

const TURN_SUMMARY = "turn-summary";
const DETAIL_INDENT = "  ";
const COLLAPSED_RESULT_LINES = 12;

type ToolArgs = Record<string, unknown>;
type ToolRenderContext = Parameters<NonNullable<ToolRenderers["renderCall"]>>[2];

const asToolArgs = (args: unknown): ToolArgs =>
  typeof args === "object" && args !== null && !Array.isArray(args) ? (args as ToolArgs) : {};

type ToolCall = {
  toolName: string;
  args: ToolArgs;
  result?: AgentToolResult<unknown>;
  finished: boolean;
  isError: boolean;
  rendererState: Record<string, unknown>;
  renderers?: ToolRenderers;
};

type ToolGroup = { callIds: string[] };

type Activity = { key: string; item?: string };

const SEARCH_TOOLS = new Set(["grep", "find", "ls", "ffgrep", "fffind"]);

function activityOf(toolName: string, args: ToolArgs): Activity {
  const path = typeof args.path === "string" ? args.path : undefined;
  if (toolName === "bash") return { key: "command" };
  if (toolName === "read" && path && basename(path).toLowerCase() === "skill.md") {
    return { key: "skill", item: basename(dirname(path)) };
  }
  if (toolName === "read") return { key: "read", item: path && basename(path) };
  if (toolName === "edit" || toolName === "write") return { key: "edit", item: path && basename(path) };
  if (SEARCH_TOOLS.has(toolName)) return { key: "search" };
  if (toolName === "codemode") return { key: "script" };
  const mcp = toolName.match(/^mcp__(.+?)__/);
  if (mcp) return { key: `mcp:${mcp[1]}`, item: mcp[1] };
  return { key: `tool:${toolName}`, item: toolName };
}

const plural = (count: number, word: string) => `${count} ${word}${count === 1 ? "" : "s"}`;

function describeActivity(key: string, items: (string | undefined)[], nameSingleItems: boolean): string {
  const count = items.length;
  const only = nameSingleItems && count === 1 ? items[0] : undefined;
  if (key === "command") return `Ran ${plural(count, "command")}`;
  if (key === "skill") return only ? `Loaded ${only} skill` : `Loaded ${plural(count, "skill")}`;
  if (key === "read") return only ? `Read ${only}` : `Read ${plural(count, "file")}`;
  if (key === "edit") return only ? `Edited ${only}` : `Edited ${plural(count, "file")}`;
  if (key === "search") return `Ran ${count === 1 ? "1 search" : `${count} searches`}`;
  if (key === "script") return `Ran ${plural(count, "script")}`;
  const name = items[0] ?? key;
  const times = count === 1 ? "" : ` ${count} times`;
  return key.startsWith("mcp:") ? `Called ${name}${times}` : `Used ${name}${times}`;
}

export function summarizeTools(calls: { toolName: string; args: ToolArgs }[], nameSingleItems: boolean): string {
  const byActivity = new Map<string, (string | undefined)[]>();
  for (const call of calls) {
    const activity = activityOf(call.toolName, call.args);
    byActivity.set(activity.key, [...(byActivity.get(activity.key) ?? []), activity.item]);
  }
  return [...byActivity].map(([key, items]) => describeActivity(key, items, nameSingleItems)).join(", ");
}

function formatDuration(milliseconds: number): string {
  const seconds = milliseconds / 1000;
  if (seconds < 60) return `${Math.round(seconds)}s`;
  if (seconds < 3600) return `${(seconds / 60).toFixed(1)}m`;
  return `${(seconds / 3600).toFixed(1)}h`;
}

function resultText(result: AgentToolResult<unknown>): string {
  return result.content
    .map((part) => (part.type === "text" ? part.text : `[${part.type}]`))
    .join("\n")
    .trimEnd();
}

class EmptyRow implements Component {
  render(): string[] {
    return [];
  }
  invalidate(): void {}
}

class GroupRow implements Component {
  constructor(private readonly renderLines: (width: number) => string[]) {}
  render(width: number): string[] {
    return this.renderLines(width).map((line) => truncateToWidth(line, width, ""));
  }
  invalidate(): void {}
}

export function registerToolGroups(pi: ExtensionAPI) {
  const calls = new Map<string, ToolCall>();
  const groupOfCall = new Map<string, ToolGroup>();
  const redrawCall = new Map<string, () => void>();
  const settledParts = new Map<number, number>();
  let openGroup: ToolGroup | undefined;
  let runStartedAt: number | undefined;

  const redrawLeaderOf = (callId: string) => {
    const leaderId = groupOfCall.get(callId)?.callIds[0];
    if (leaderId && leaderId !== callId) redrawCall.get(leaderId)?.();
  };

  const closeGroup = () => {
    openGroup = undefined;
  };

  const joinOpenGroup = (callId: string) => {
    if (groupOfCall.has(callId)) return;
    openGroup ??= { callIds: [] };
    openGroup.callIds.push(callId);
    groupOfCall.set(callId, openGroup);
    redrawLeaderOf(callId);
  };

  const absorbAssistant = (message: AssistantMessage, complete: boolean) => {
    let index = settledParts.get(message.timestamp) ?? 0;
    for (; index < message.content.length; index++) {
      const part = message.content[index]!;
      const isLast = index === message.content.length - 1;
      if (part.type === "toolCall") {
        joinOpenGroup(part.id);
        continue;
      }
      const hasText = part.type === "text" && part.text.trim() !== "";
      if (hasText) {
        closeGroup();
        continue;
      }
      if (isLast && !complete) break;
    }
    settledParts.set(message.timestamp, index);
  };

  const rebuild = (ctx: ExtensionContext) => {
    calls.clear();
    groupOfCall.clear();
    redrawCall.clear();
    settledParts.clear();
    closeGroup();
    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type !== "message") continue;
      if (entry.message.role === "user") closeGroup();
      if (entry.message.role === "assistant") absorbAssistant(entry.message, true);
    }
  };

  const callRecord = (toolName: string, callId: string, args: ToolArgs, next: () => ToolRenderers | undefined) => {
    const existing = calls.get(callId);
    if (existing) {
      existing.args = args;
      return existing;
    }
    const created: ToolCall = { toolName, args, finished: false, isError: false, rendererState: {}, renderers: next() };
    calls.set(callId, created);
    return created;
  };

  const renderCallDetail = (callId: string, call: ToolCall, theme: Theme, leaderContext: ToolRenderContext, width: number): string[] => {
    const context: ToolRenderContext = {
      ...leaderContext,
      args: call.args,
      toolCallId: callId,
      lastComponent: undefined,
      state: call.rendererState,
      executionStarted: true,
      argsComplete: true,
      isPartial: !call.finished,
      expanded: true,
      isError: call.isError,
      durationMs: undefined,
    };
    const innerWidth = Math.max(1, width - DETAIL_INDENT.length);
    const components: Component[] = [];
    try {
      components.push(call.renderers?.renderCall?.(call.args, theme, context) ?? new Text(theme.fg("toolTitle", `${call.toolName} ${JSON.stringify(call.args)}`), 0, 0));
    } catch {
      components.push(new Text(theme.fg("toolTitle", call.toolName), 0, 0));
    }
    if (call.result) {
      try {
        const rendered = call.renderers?.renderResult?.(call.result, { expanded: true, isPartial: !call.finished }, theme, context);
        if (rendered) components.push(rendered);
        else throw new Error("no result renderer");
      } catch {
        const lines = resultText(call.result).split("\n");
        const shown = lines.slice(0, COLLAPSED_RESULT_LINES).map((line) => theme.fg("toolOutput", line));
        if (lines.length > shown.length) shown.push(theme.fg("dim", `… ${lines.length - shown.length} more lines`));
        components.push(new Text(shown.join("\n"), 0, 0));
      }
    }
    return components.flatMap((component) => component.render(innerWidth)).map((line) => `${DETAIL_INDENT}${line}`);
  };

  const renderGroup = (group: ToolGroup, theme: Theme, leaderContext: ToolRenderContext, width: number): string[] => {
    const members = group.callIds.flatMap((id) => {
      const call = calls.get(id);
      return call ? [{ id, call }] : [];
    });
    const running = members.some(({ call }) => !call.finished);
    const failed = members.filter(({ call }) => call.isError).length;
    const summary = summarizeTools(members.map(({ call }) => call), true) || "Working";
    const marker = failed > 0 ? theme.fg("error", "◇") : running ? theme.fg("text", "◆") : theme.fg("muted", "◇");
    const lines = [
      `${marker} ${theme.fg("muted", `${summary}${running ? "…" : ""}`)}${failed > 0 ? theme.fg("error", ` · ${failed} failed`) : ""}`,
    ];
    if (!leaderContext.expanded) return lines;
    for (const { id, call } of members) {
      lines.push("", ...renderCallDetail(id, call, theme, leaderContext, width));
    }
    return lines;
  };

  pi.registerToolRenderer((toolName, next) => ({
    renderShell: "self",
    renderCall(args: unknown, theme: Theme, context: ToolRenderContext) {
      callRecord(toolName, context.toolCallId, asToolArgs(args), next);
      redrawCall.set(context.toolCallId, context.invalidate);
      joinOpenGroup(context.toolCallId);
      const group = groupOfCall.get(context.toolCallId)!;
      if (group.callIds[0] !== context.toolCallId) {
        redrawLeaderOf(context.toolCallId);
        return new EmptyRow();
      }
      return new GroupRow((width) => renderGroup(group, theme, context, width));
    },
    renderResult(result: AgentToolResult<unknown>, options, _theme: Theme, context: ToolRenderContext) {
      const call = callRecord(toolName, context.toolCallId, asToolArgs(context.args), next);
      call.result = result;
      call.finished = !options.isPartial;
      call.isError = context.isError;
      redrawLeaderOf(context.toolCallId);
      return new EmptyRow();
    },
  }));

  pi.registerEntryRenderer<{ summary: string; durationMs: number }>(TURN_SUMMARY, (entry, _options, theme) => {
    const data = entry.data;
    if (!data) return undefined;
    const parts = [data.summary, formatDuration(data.durationMs)].filter(Boolean);
    return new Text(theme.fg("muted", parts.join(" · ")), 0, 0);
  });

  pi.on("session_start", (_event, ctx) => rebuild(ctx));
  pi.on("session_tree", (_event, ctx) => rebuild(ctx));

  pi.on("message_start", (event) => {
    if (event.message.role === "user") closeGroup();
  });
  pi.on("message_update", (event) => {
    if (event.message.role === "assistant") absorbAssistant(event.message, false);
  });
  pi.on("message_end", (event) => {
    if (event.message.role === "assistant") absorbAssistant(event.message, true);
  });

  pi.on("agent_start", () => {
    runStartedAt ??= Date.now();
  });

  pi.on("agent_before_settle", (event, ctx) => {
    const startedAt = runStartedAt;
    runStartedAt = undefined;
    if (startedAt === undefined) return;

    const branch = ctx.sessionManager.getBranch();
    const lastUser = branch.findLastIndex((entry) => entry.type === "message" && entry.message.role === "user");
    const toolCalls = branch.slice(lastUser + 1).flatMap((entry) =>
      entry.type === "message" && entry.message.role === "assistant"
        ? entry.message.content.flatMap((part) => (part.type === "toolCall" ? [{ toolName: part.name, args: asToolArgs(part.arguments) }] : []))
        : [],
    );
    if (toolCalls.length === 0) return;

    return {
      entries: [
        ...event.entries,
        { type: "custom", customType: TURN_SUMMARY, data: { summary: summarizeTools(toolCalls, false), durationMs: Date.now() - startedAt } },
      ],
    };
  });
}
