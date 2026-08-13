import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { AssistantMessage, Message, Tool } from "@earendil-works/pi-ai";
import {
  convertToLlm,
  copyToClipboard,
  getMarkdownTheme,
  sessionEntryToContextMessages,
  type ExtensionAPI,
  type ExtensionCommandContext,
  type SessionManager,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import { Markdown, matchesKey, Text, type Component, type TUI } from "@earendil-works/pi-tui";

const WIDGET_ID = "btw";
const MAX_REPLY_BYTES = 4096;

const SIDE_CHANNEL_REMINDER = `<system-reminder>
Ephemeral side-channel turn; reuses current conversation context.
Tool catalog attached only to keep prompt cache warm; tools NOT available this turn.
Do NOT emit tool calls; reply plain text only. Tool calls discarded without execution.
</system-reminder>`;

function buildQuestionPrompt(question: string): string {
  return `<btw>
Ephemeral side question for current interactive session.
Answer briefly, directly; use conversation context already provided.
NEVER use tools.
NEVER ask follow-up questions.
Question:
${question}
</btw>`;
}

type BtwStatus = "running" | "complete" | "branching" | "error";

type BtwRequest = {
  question: string;
  answer: string;
  status: BtwStatus;
  error?: string;
  abortController: AbortController;
  leafId: string | null;
  sessionId: string;
  assistantMessage?: AssistantMessage;
  ctx: ExtensionCommandContext;
  tui?: TUI;
};

class BtwPanel implements Component {
  constructor(
    private readonly request: BtwRequest,
    private readonly theme: Theme,
  ) {}

  render(width: number): string[] {
    if (width <= 0) return [];

    const border = this.theme.fg("dim", "─".repeat(width));
    const question = new Text(this.theme.fg("accent", this.request.question), 1, 0).render(width);
    const answer = this.renderAnswer(width);
    const footer = new Text(this.renderFooter(), 1, 0).render(width);

    return [border, "", ...question, "", ...answer, "", ...footer, "", border];
  }

  invalidate(): void {}

  private renderAnswer(width: number): string[] {
    if (this.request.status === "error") {
      return new Text(this.theme.fg("error", this.request.error ?? "Unknown error"), 1, 0).render(width);
    }

    if (!this.request.answer) {
      const message = this.request.status === "running" ? "◌ Waiting for response…" : "No text returned.";
      return new Text(this.theme.fg("dim", message), 1, 0).render(width);
    }

    return new Markdown(this.request.answer, 1, 0, getMarkdownTheme()).render(width);
  }

  private renderFooter(): string {
    switch (this.request.status) {
      case "running":
        return this.theme.fg("muted", "Esc cancel /btw");
      case "complete":
        if (!this.request.answer) return this.theme.fg("muted", "Esc dismiss");
        return this.theme.fg("muted", "c copy · b branch to chat · Esc dismiss");
      case "branching":
        return this.theme.fg("muted", "◌ Branching to chat…");
      case "error":
        return this.theme.fg("error", "✗ Error · Esc dismiss");
    }
  }
}

function compressReply(text: string): string {
  if (!text) return text;

  const lines = text.split("\n");
  const compressed: string[] = [];
  let index = 0;

  while (index < lines.length) {
    let end = index + 1;
    while (end < lines.length && lines[end] === lines[index]) end++;

    const count = end - index;
    if (count > 3) {
      compressed.push(lines[index]!, `[…${count}×]`);
    } else {
      for (let offset = 0; offset < count; offset++) compressed.push(lines[index]!);
    }
    index = end;
  }

  let reply = compressed.join("\n");
  const suffix = "\n[…truncated]";
  const maxContentBytes = MAX_REPLY_BYTES - Buffer.byteLength(suffix, "utf8");

  if (Buffer.byteLength(reply, "utf8") > MAX_REPLY_BYTES) {
    while (Buffer.byteLength(reply, "utf8") > maxContentBytes) {
      reply = reply.slice(0, -1);
    }
    reply += suffix;
  }

  return reply;
}

function textFromAssistant(message: AssistantMessage): string {
  return message.content
    .filter((part): part is { type: "text"; text: string } => part.type === "text")
    .map((part) => part.text)
    .join("")
    .trim();
}

function prepareBranchMessage(message: AssistantMessage, answer: string): AssistantMessage {
  const content: AssistantMessage["content"] = [];
  let insertedAnswer = false;

  for (const part of message.content) {
    if (part.type === "toolCall") continue;
    if (part.type === "text") {
      if (!insertedAnswer) {
        content.push({ type: "text", text: answer });
        insertedAnswer = true;
      }
      continue;
    }
    content.push(part);
  }

  if (!insertedAnswer) content.push({ type: "text", text: answer });

  return { ...message, content };
}

function collectContextMessages(ctx: ExtensionCommandContext, streamingAssistant?: AgentMessage): Message[] {
  const agentMessages = ctx.sessionManager
    .buildContextEntries()
    .flatMap((entry) => sessionEntryToContextMessages(entry));

  if (streamingAssistant) {
    const lastMessage = agentMessages.at(-1);
    if (lastMessage?.role === "assistant") agentMessages[agentMessages.length - 1] = streamingAssistant;
    else agentMessages.push(streamingAssistant);
  }

  return convertToLlm(agentMessages);
}

function activeToolCatalog(pi: ExtensionAPI): Tool[] {
  const activeNames = new Set(pi.getActiveTools());
  return pi
    .getAllTools()
    .filter((tool) => activeNames.has(tool.name))
    .map((tool) => ({
      name: tool.name,
      description: tool.description,
      parameters: tool.parameters,
    }));
}

export default function btwExtension(pi: ExtensionAPI) {
  let currentRequest: BtwRequest | undefined;
  let streamingAssistant: AgentMessage | undefined;
  let sideRequestSequence = 0;
  let removeInputListener: (() => void) | undefined;

  const renderRequest = (request: BtwRequest) => {
    request.tui?.requestRender();
  };

  const dismiss = (abort: boolean) => {
    const request = currentRequest;
    if (!request) return;

    currentRequest = undefined;
    if (abort && !request.abortController.signal.aborted) request.abortController.abort();
    request.ctx.ui.setWidget(WIDGET_ID, undefined);
  };

  const branchToChat = async (request: BtwRequest) => {
    if (request.status !== "complete" || !request.assistantMessage || !request.answer) return;
    if (!request.leafId) {
      request.ctx.ui.notify("/btw branch unavailable: the session has no branch point", "info");
      return;
    }
    if (
      request.sessionId !== request.ctx.sessionManager.getSessionId() ||
      request.leafId !== request.ctx.sessionManager.getLeafId()
    ) {
      request.ctx.ui.notify("/btw branch unavailable: the session changed since /btw started", "info");
      return;
    }
    if (!request.ctx.isIdle()) {
      request.ctx.ui.notify("/btw branch unavailable: a turn is still running", "info");
      return;
    }

    request.status = "branching";
    renderRequest(request);

    try {
      const assistantMessage = prepareBranchMessage(request.assistantMessage, request.answer);
      const result = await request.ctx.fork(request.leafId, {
        position: "at",
        withSession: async (replacementCtx) => {
          const sessionManager = replacementCtx.sessionManager as unknown as SessionManager;
          sessionManager.appendMessage({
            role: "user",
            content: [{ type: "text", text: request.question }],
            timestamp: Date.now(),
          });
          sessionManager.appendMessage(assistantMessage);
          replacementCtx.ui.notify("Branched /btw to chat", "info");
        },
      });

      if (result.cancelled) {
        request.status = "complete";
        request.ctx.ui.notify("/btw branch cancelled", "info");
        renderRequest(request);
      }
    } catch (error) {
      request.status = "complete";
      request.ctx.ui.notify(`Cannot branch /btw: ${error instanceof Error ? error.message : String(error)}`, "error");
      renderRequest(request);
    }
  };

  const runSideRequest = async (request: BtwRequest) => {
    try {
      const model = request.ctx.model;
      if (!model) throw new Error("No active model available for /btw.");

      const provider = request.ctx.modelRegistry.getProvider(model.provider);
      if (!provider) throw new Error(`Provider ${model.provider} is unavailable.`);

      const auth = await request.ctx.modelRegistry.getApiKeyAndHeaders(model);
      if (!auth.ok) throw new Error(auth.error);

      const messages = collectContextMessages(request.ctx, streamingAssistant);
      messages.push({
        role: "user",
        content: [
          {
            type: "text",
            text: `${SIDE_CHANNEL_REMINDER}\n\n${buildQuestionPrompt(request.question)}`,
          },
        ],
        timestamp: Date.now(),
      });

      const requestModel = auth.baseUrl ? { ...model, baseUrl: auth.baseUrl } : model;
      const stream = provider.streamSimple(
        requestModel,
        {
          systemPrompt: request.ctx.getSystemPrompt(),
          messages,
          tools: activeToolCatalog(pi),
        },
        {
          apiKey: auth.apiKey,
          headers: auth.headers,
          env: auth.env,
          signal: request.abortController.signal,
          reasoning: request.ctx.thinkingLevel === "off" ? undefined : request.ctx.thinkingLevel,
          cacheRetention: "short",
          sessionId: `${request.sessionId}:side:${++sideRequestSequence}`,
        },
      );

      let streamedText = "";
      let finalMessage: AssistantMessage | undefined;

      for await (const event of stream) {
        if (event.type === "text_delta") {
          streamedText += event.delta;
          if (currentRequest === request) {
            request.answer = streamedText.trim();
            renderRequest(request);
          }
        } else if (event.type === "done") {
          finalMessage = event.message;
        } else if (event.type === "error") {
          throw new Error(event.error.errorMessage || "Ephemeral turn failed");
        }
      }

      if (!finalMessage) throw new Error("Ephemeral turn ended without a final message");
      if (currentRequest !== request) return;

      request.answer = compressReply(textFromAssistant(finalMessage));
      request.assistantMessage = prepareBranchMessage(finalMessage, request.answer);
      request.status = "complete";
      renderRequest(request);
    } catch (error) {
      if (currentRequest !== request || request.abortController.signal.aborted) return;
      request.status = "error";
      request.error = error instanceof Error ? error.message : String(error);
      renderRequest(request);
    }
  };

  pi.registerCommand("btw", {
    description: "Ask an ephemeral side question using the current session context",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify("/btw requires interactive mode", "error");
        return;
      }

      const question = args.trim();
      if (!question) {
        ctx.ui.notify("Usage: /btw <question>", "info");
        return;
      }
      if (!ctx.model) {
        ctx.ui.notify("No active model available for /btw.", "error");
        return;
      }

      dismiss(true);

      const request: BtwRequest = {
        question,
        answer: "",
        status: "running",
        abortController: new AbortController(),
        leafId: ctx.sessionManager.getLeafId(),
        sessionId: ctx.sessionManager.getSessionId(),
        ctx,
      };
      currentRequest = request;

      ctx.ui.setWidget(
        WIDGET_ID,
        (tui, theme) => {
          request.tui = tui;
          return new BtwPanel(request, theme);
        },
        { placement: "aboveEditor" },
      );

      void runSideRequest(request);
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
      const request = currentRequest;
      if (!request) return;

      if (request.tui?.hasOverlay()) return;

      if (matchesKey(data, "escape")) {
        if (request.status === "branching") {
          ctx.ui.notify("/btw branch is in progress", "info");
        } else {
          dismiss(true);
        }
        return { consume: true };
      }

      if (ctx.ui.getEditorText().trim() || request.status !== "complete" || !request.answer) return;

      if (matchesKey(data, "c")) {
        void copyToClipboard(request.answer)
          .then(() => ctx.ui.notify("Copied /btw answer to clipboard", "info"))
          .catch((error) => ctx.ui.notify(error instanceof Error ? error.message : String(error), "error"));
        return { consume: true };
      }

      if (matchesKey(data, "b")) {
        void branchToChat(request);
        return { consume: true };
      }
    });
  });

  pi.on("session_shutdown", () => {
    dismiss(true);
    removeInputListener?.();
    removeInputListener = undefined;
    streamingAssistant = undefined;
  });
}
