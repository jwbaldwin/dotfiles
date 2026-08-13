import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const MARKER_TYPE = "auto-session-name";
const PROVIDER = "openai-codex";
const MODEL = "gpt-5.6-luna";

type NameMarker = {
  name: string;
  userMessageCount: number;
};

function latestMarker(ctx: ExtensionContext): NameMarker | undefined {
  for (const entry of ctx.sessionManager.getBranch().toReversed()) {
    if (entry.type !== "custom" || entry.customType !== MARKER_TYPE) continue;
    const marker = entry.data as Partial<NameMarker> | undefined;
    if (typeof marker?.name === "string" && typeof marker.userMessageCount === "number") {
      return marker as NameMarker;
    }
  }
  return undefined;
}

function collectUserPrompts(ctx: ExtensionContext): string[] {
  const prompts: string[] = [];
  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type !== "message" || entry.message.role !== "user") continue;
    const text = entry.message.content
      .filter((part): part is { type: "text"; text: string } => part.type === "text")
      .map((part) => part.text)
      .join(" ")
      .replace(/\s+/g, " ")
      .trim();
    if (text) prompts.push(text);
  }
  return prompts;
}

function shouldRefreshName(userMessageCount: number, lastNamedAt: number): boolean {
  if (lastNamedAt === 0) return userMessageCount >= 1;
  if (lastNamedAt === 1) return userMessageCount >= 5;
  return userMessageCount >= lastNamedAt + 5;
}

function namingPrompt(prompts: string[], currentName: string | undefined): string {
  const selected = prompts.length <= 9 ? prompts : [prompts[0]!, ...prompts.slice(-8)];
  const transcript = selected
    .map((prompt, index) => `${index + 1}. ${prompt.slice(0, 600)}`)
    .join("\n");

  return [
    "Name this coding session based on the user's goals and current direction.",
    "Return only a plain 3-7 word title.",
    "Use concrete nouns and verbs. No quotes, markdown, trailing punctuation, or commentary.",
    "Prefer the latest direction when the session has shifted.",
    currentName ? `Current title: ${currentName}` : "Current title: none",
    "User requests:",
    transcript,
  ].join("\n");
}

function titleFromMessage(message: AssistantMessage): string | undefined {
  const raw = message.content
    .filter((part): part is { type: "text"; text: string } => part.type === "text")
    .map((part) => part.text)
    .join(" ")
    .split("\n")
    .find((line) => line.trim().length > 0)
    ?.trim();
  if (!raw) return undefined;

  const words = raw
    .replace(/^(?:title|session name)\s*:\s*/i, "")
    .replace(/^[#*`'"“”]+|[#*`'"“”.,:;!?]+$/g, "")
    .replace(/\s+/g, " ")
    .trim()
    .split(" ")
    .filter(Boolean)
    .slice(0, 8);

  if (words.length < 2) return undefined;
  const title = words.join(" ");
  return title.length <= 60 ? title : `${title.slice(0, 59).trimEnd()}…`;
}

export default function autoSessionName(pi: ExtensionAPI) {
  let activeSessionId: string | undefined;
  let automaticNamingEnabled = true;
  let expectedName: string | undefined;
  let lastNamedAt = 0;
  let naming = false;
  let namingAbort: AbortController | undefined;

  const isActive = (ctx: ExtensionContext) =>
    ctx.sessionManager.getSessionId() === activeSessionId;

  const generateName = async (ctx: ExtensionContext, prompts: string[]) => {
    const model = ctx.modelRegistry.find(PROVIDER, MODEL);
    if (!model) return;
    const provider = ctx.modelRegistry.getProvider(PROVIDER);
    if (!provider) return;

    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (!auth.ok || !isActive(ctx)) return;

    namingAbort = new AbortController();
    const timeout = setTimeout(() => namingAbort?.abort(), 15_000);

    try {
      const stream = provider.streamSimple(
        model,
        {
          systemPrompt: "You write short, accurate titles for coding sessions.",
          messages: [{
            role: "user",
            content: [{ type: "text", text: namingPrompt(prompts, ctx.sessionManager.getSessionName()) }],
            timestamp: Date.now(),
          }],
        },
        {
          apiKey: auth.apiKey,
          headers: auth.headers,
          env: auth.env,
          signal: namingAbort.signal,
          reasoning: "minimal",
          transport: "sse",
          timeoutMs: 15_000,
          maxRetries: 0,
          maxTokens: 40,
          sessionId: `${ctx.sessionManager.getSessionId()}:auto-name:${prompts.length}`,
        },
      );

      let finalMessage: AssistantMessage | undefined;
      for await (const event of stream) {
        if (event.type === "done") finalMessage = event.message;
        if (event.type === "error") throw new Error(event.error.errorMessage || "Session naming failed");
      }

      if (!isActive(ctx) || !automaticNamingEnabled || !finalMessage) return;
      const name = titleFromMessage(finalMessage);
      if (!name) return;

      expectedName = name;
      pi.setSessionName(name);
      lastNamedAt = prompts.length;
      pi.appendEntry(MARKER_TYPE, { name, userMessageCount: lastNamedAt } satisfies NameMarker);
    } finally {
      clearTimeout(timeout);
      namingAbort = undefined;
    }
  };

  pi.on("session_start", (_event, ctx) => {
    activeSessionId = ctx.sessionManager.getSessionId();
    naming = false;
    namingAbort = undefined;
    expectedName = undefined;

    const marker = latestMarker(ctx);
    const currentName = ctx.sessionManager.getSessionName();
    automaticNamingEnabled = currentName === undefined || currentName === marker?.name;
    lastNamedAt = marker?.userMessageCount ?? 0;
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (!isActive(ctx) || !automaticNamingEnabled || naming) return;
    const prompts = collectUserPrompts(ctx);
    if (!shouldRefreshName(prompts.length, lastNamedAt)) return;

    naming = true;
    try {
      await generateName(ctx, prompts);
    } catch {
      // Naming is optional. Retry at the next settled turn if the fast model is unavailable.
    } finally {
      naming = false;
    }
  });

  pi.on("session_info_changed", (event, ctx) => {
    if (!isActive(ctx)) return;
    if (expectedName !== undefined && event.name === expectedName) {
      expectedName = undefined;
      return;
    }
    automaticNamingEnabled = false;
  });

  pi.on("session_shutdown", (_event, ctx) => {
    if (!isActive(ctx)) return;
    namingAbort?.abort();
    namingAbort = undefined;
    activeSessionId = undefined;
  });
}
