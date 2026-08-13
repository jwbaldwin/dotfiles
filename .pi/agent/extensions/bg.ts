import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { AssistantMessage, Message } from "@earendil-works/pi-ai";
import {
  buildSessionContext,
  copyToClipboard,
  createAgentSessionFromServices,
  createAgentSessionRuntime,
  createAgentSessionServices,
  getAgentDir,
  getMarkdownTheme,
  SessionManager,
  type AgentSession,
  type AgentSessionRuntime,
  type AgentSessionEvent,
  type ExtensionAPI,
  type ExtensionCommandContext,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import { Markdown, matchesKey, Text, type Component, type TUI } from "@earendil-works/pi-tui";

const WIDGET_ID = "bg";
const RESULT_MESSAGE_TYPE = "bg-result";

const TASK_PROMPT = `You are a background task agent working alongside the main interactive agent.
Complete the task autonomously. Use the available tools when useful, including MCP tools.
Do not ask follow-up questions. Make reasonable low-risk decisions from the supplied conversation context.
The user's /bg command authorizes the task they explicitly requested, including external writes named in that task.
Do not perform unrelated destructive actions, publish communications as the user, deploy, merge, or release.
When finished, return a concise result that states what you did and includes useful links or identifiers.

Task:
`;

type BgStatus = "starting" | "running" | "complete" | "error" | "cancelled";

type BgRequest = {
  task: string;
  status: BgStatus;
  activity: string;
  partialAnswer: string;
  finalAnswer: string;
  error?: string;
  ctx: ExtensionCommandContext;
  tui?: TUI;
  runtime?: AgentSessionRuntime;
  unsubscribe?: () => void;
};

class BgPanel implements Component {
  constructor(
    private readonly request: BgRequest,
    private readonly theme: Theme,
  ) {}

  render(width: number): string[] {
    if (width <= 0) return [];

    const border = this.theme.fg("dim", "─".repeat(width));
    const task = new Text(this.theme.fg("accent", this.request.task), 1, 0).render(width);
    const body = this.renderBody(width);
    const footer = new Text(this.renderFooter(), 1, 0).render(width);
    return [border, "", ...task, "", ...body, "", ...footer, "", border];
  }

  invalidate(): void {}

  private renderBody(width: number): string[] {
    if (this.request.status === "error") {
      return new Text(this.theme.fg("error", this.request.error ?? "Unknown error"), 1, 0).render(width);
    }

    if (this.request.status === "cancelled") {
      return new Text(this.theme.fg("warning", "Cancelled"), 1, 0).render(width);
    }

    const answer = this.request.finalAnswer || this.request.partialAnswer;
    if (answer) return new Markdown(answer, 1, 0, getMarkdownTheme()).render(width);

    return new Text(this.theme.fg("dim", `◌ ${this.request.activity}`), 1, 0).render(width);
  }

  private renderFooter(): string {
    switch (this.request.status) {
      case "starting":
      case "running":
        return this.theme.fg("muted", "Esc cancel /bg");
      case "complete":
        return this.theme.fg("muted", "c copy · i bring into chat · Esc dismiss");
      case "error":
        return this.theme.fg("error", "✗ Error · Esc dismiss");
      case "cancelled":
        return this.theme.fg("warning", "Cancelled · Esc dismiss");
    }
  }
}

function assistantText(message: AssistantMessage | AgentMessage | undefined): string {
  if (!message || message.role !== "assistant" || !Array.isArray(message.content)) return "";
  return message.content
    .filter((part): part is { type: "text"; text: string } => part.type === "text")
    .map((part) => part.text)
    .join("")
    .trim();
}

function lastAssistantMessage(session: AgentSession): AssistantMessage | undefined {
  for (let index = session.messages.length - 1; index >= 0; index--) {
    const message = session.messages[index];
    if (message?.role === "assistant") return message as AssistantMessage;
  }
  return undefined;
}

function seedMessages(ctx: ExtensionCommandContext, streamingAssistant?: AgentMessage): Message[] {
  const messages = buildSessionContext(ctx.sessionManager.getEntries(), ctx.sessionManager.getLeafId()).messages as Message[];
  if (!streamingAssistant) return messages;

  const last = messages.at(-1);
  if (last?.role === "assistant") messages[messages.length - 1] = streamingAssistant as Message;
  else messages.push(streamingAssistant as Message);
  return messages;
}

export default function bgExtension(pi: ExtensionAPI) {
  let activeRequest: BgRequest | undefined;
  let streamingAssistant: AgentMessage | undefined;
  let removeInputListener: (() => void) | undefined;

  const render = (request: BgRequest) => request.tui?.requestRender();

  const disposeSession = async (request: BgRequest, abort: boolean) => {
    request.unsubscribe?.();
    request.unsubscribe = undefined;

    const runtime = request.runtime;
    request.runtime = undefined;
    if (!runtime) return;

    if (abort) {
      try {
        await runtime.session.abort();
      } catch {
        // The request may already have settled.
      }
    }
    await runtime.dispose();
  };

  const dismiss = async (cancel: boolean) => {
    const request = activeRequest;
    if (!request) return;

    activeRequest = undefined;
    request.ctx.ui.setWidget(WIDGET_ID, undefined);
    if (cancel && (request.status === "starting" || request.status === "running")) {
      request.status = "cancelled";
      await disposeSession(request, true);
    } else {
      await disposeSession(request, false);
    }
  };

  const injectResult = (request: BgRequest) => {
    if (request.status !== "complete" || !request.finalAnswer) return;

    const content = `Background task: ${request.task}\n\n${request.finalAnswer}`;
    pi.sendMessage(
      {
        customType: RESULT_MESSAGE_TYPE,
        content,
        display: true,
        details: { task: request.task, result: request.finalAnswer },
      },
      request.ctx.isIdle() ? undefined : { deliverAs: "nextTurn" },
    );
    request.ctx.ui.notify(
      request.ctx.isIdle() ? "Added /bg result to the chat" : "Queued /bg result for the next chat turn",
      "info",
    );
    void dismiss(false);
  };

  const applySessionEvent = (request: BgRequest, event: AgentSessionEvent) => {
    if (activeRequest !== request) return;

    if (event.type === "tool_execution_start") {
      request.activity = `Running ${event.toolName}…`;
      request.partialAnswer = "";
    } else if (event.type === "message_update" && event.message.role === "assistant") {
      request.partialAnswer = assistantText(event.message);
      request.activity = "Working…";
    } else if (event.type === "turn_start") {
      request.activity = "Thinking…";
    }
    render(request);
  };

  const runTask = async (request: BgRequest, contextMessages: Message[]) => {
    try {
      request.activity = "Loading tools…";
      render(request);

      const agentDir = getAgentDir();
      const model = request.ctx.model;
      const thinkingLevel = request.ctx.thinkingLevel;
      const tools = pi.getActiveTools();
      const createRuntime = async (options: {
        cwd: string;
        agentDir: string;
        sessionManager: SessionManager;
        sessionStartEvent?: { type: "session_start"; reason: "startup" | "reload" | "new" | "resume" | "fork"; previousSessionFile?: string };
      }) => {
        const services = await createAgentSessionServices({ cwd: options.cwd, agentDir: options.agentDir });
        const result = await createAgentSessionFromServices({
          services,
          sessionManager: options.sessionManager,
          sessionStartEvent: options.sessionStartEvent,
          model,
          thinkingLevel,
          tools,
        });
        return { ...result, services, diagnostics: services.diagnostics };
      };
      const runtime = await createAgentSessionRuntime(createRuntime, {
        cwd: request.ctx.cwd,
        agentDir,
        sessionManager: SessionManager.inMemory(),
      });
      const session = runtime.session;

      if (activeRequest !== request) {
        await runtime.dispose();
        return;
      }

      request.runtime = runtime;
      await session.bindExtensions({ mode: "print" });
      if (activeRequest !== request) {
        await disposeSession(request, true);
        return;
      }

      session.agent.state.messages = contextMessages as typeof session.agent.state.messages;
      request.unsubscribe = session.subscribe((event) => applySessionEvent(request, event));
      request.status = "running";
      request.activity = "Working…";
      render(request);

      await session.prompt(`${TASK_PROMPT}${request.task}`, { source: "extension" });
      if (activeRequest !== request) return;

      const finalMessage = lastAssistantMessage(session);
      if (!finalMessage) throw new Error("Background task finished without a response.");
      if (finalMessage.stopReason === "error") {
        throw new Error(finalMessage.errorMessage || "Background task failed.");
      }
      if (finalMessage.stopReason === "aborted") {
        request.status = "cancelled";
        request.activity = "Cancelled";
        render(request);
        return;
      }

      request.finalAnswer = assistantText(finalMessage) || "Completed without a text response.";
      request.partialAnswer = "";
      request.status = "complete";
      request.activity = "Complete";
      render(request);
      await disposeSession(request, false);
    } catch (error) {
      if (activeRequest !== request) return;
      request.status = "error";
      request.error = error instanceof Error ? error.message : String(error);
      render(request);
      await disposeSession(request, true);
    }
  };

  pi.registerMessageRenderer(RESULT_MESSAGE_TYPE, (message, _options, theme) => {
    return new Markdown(String(message.content), 1, 1, getMarkdownTheme());
  });

  pi.registerCommand("bg", {
    description: "Run a background task with the current context and active tools",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify("/bg requires interactive mode", "error");
        return;
      }

      const task = args.trim();
      if (!task) {
        ctx.ui.notify("Usage: /bg <task>", "info");
        return;
      }
      if (!ctx.model) {
        ctx.ui.notify("No active model available for /bg.", "error");
        return;
      }

      await dismiss(true);

      const request: BgRequest = {
        task,
        status: "starting",
        activity: "Starting…",
        partialAnswer: "",
        finalAnswer: "",
        ctx,
      };
      activeRequest = request;

      ctx.ui.setWidget(
        WIDGET_ID,
        (tui, theme) => {
          request.tui = tui;
          return new BgPanel(request, theme);
        },
        { placement: "aboveEditor" },
      );

      const contextMessages = seedMessages(ctx, streamingAssistant);
      void runTask(request, contextMessages);
    },
  });

  pi.on("message_update", (event) => {
    if (event.message.role === "assistant") streamingAssistant = event.message;
  });

  pi.on("message_end", (event) => {
    if (event.message.role === "assistant") streamingAssistant = undefined;
  });

  pi.on("session_start", (_event, ctx) => {
    removeInputListener?.();
    removeInputListener = ctx.ui.onTerminalInput((data) => {
      const request = activeRequest;
      if (!request || request.tui?.hasOverlay()) return;

      if (matchesKey(data, "escape")) {
        void dismiss(true);
        return { consume: true };
      }

      if (ctx.ui.getEditorText().trim() || request.status !== "complete" || !request.finalAnswer) return;

      if (matchesKey(data, "c")) {
        void copyToClipboard(request.finalAnswer)
          .then(() => ctx.ui.notify("Copied /bg result to clipboard", "info"))
          .catch((error) => ctx.ui.notify(error instanceof Error ? error.message : String(error), "error"));
        return { consume: true };
      }

      if (matchesKey(data, "i")) {
        injectResult(request);
        return { consume: true };
      }
    });
  });

  pi.on("session_shutdown", async () => {
    removeInputListener?.();
    removeInputListener = undefined;
    streamingAssistant = undefined;
    await dismiss(true);
  });
}
