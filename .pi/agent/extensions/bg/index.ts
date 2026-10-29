import {
  copyToClipboard,
  getMarkdownTheme,
  type ExtensionAPI,
  type ExtensionCommandContext,
  type ExtensionContext,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import { Markdown, Text, type Component } from "@earendil-works/pi-tui";
import { spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import { existsSync, openSync, closeSync } from "node:fs";
import { mkdir } from "node:fs/promises";
import path from "node:path";

import {
  isRunning,
  listTasks,
  logPath,
  readCompletion,
  readCurrentReply,
  removeTask,
  saveTask,
  taskSessionFile,
  tasksDirectory,
  type BackgroundTask,
} from "./tasks.ts";

const CARD_WIDGET = "bg-result";
const RESULT_MESSAGE_TYPE = "bg-result";
const POLL_INTERVAL_MS = 2000;
const CARD_ANSWER_LINES = 10;

const TASK_PROMPT = `You are a background task agent working alongside the main interactive agent.
Complete the task autonomously. Use the available tools when useful, including MCP tools.
Do not ask follow-up questions. Make reasonable low-risk decisions from the supplied conversation context.
The user's /bg command authorizes the task they explicitly requested, including external writes named in that task.
Do not perform unrelated destructive actions, publish communications as the user, deploy, merge, or release.
When finished, return a concise result that states what you did and includes useful links or identifiers.

Task:
`;

function shortTask(task: string, limit = 80): string {
  const line = task.replaceAll(/\s+/g, " ").trim();
  return line.length <= limit ? line : `${line.slice(0, limit - 1)}…`;
}

function relativeTime(timestamp: number): string {
  const minutes = Math.max(0, Math.floor((Date.now() - timestamp) / 60_000));
  if (minutes < 1) return "just now";
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  return hours < 24 ? `${hours}h ago` : `${Math.floor(hours / 24)}d ago`;
}

function taskState(task: BackgroundTask): string {
  if (task.completion) return task.completion.outcome;
  return isRunning(task) ? "running" : "finishing";
}

class ResultCard implements Component {
  constructor(
    private readonly task: BackgroundTask,
    private readonly position: number,
    private readonly total: number,
    private readonly theme: Theme,
  ) {}

  render(width: number): string[] {
    if (width <= 0 || !this.task.completion) return [];
    const { outcome, answer } = this.task.completion;
    const border = this.theme.fg("dim", "─".repeat(width));
    const title = new Text(
      this.theme.fg(outcome === "complete" ? "warning" : "error", `Background task ${outcome} — ${shortTask(this.task.task)}`),
      1,
      0,
    ).render(width);

    const body = new Markdown(answer, 1, 0, getMarkdownTheme()).render(width);
    const clipped = body.length > CARD_ANSWER_LINES;
    const footer = [
      "/bg-result for actions",
      clipped ? "result truncated" : "",
      this.total > 1 ? `${this.position} of ${this.total}` : "",
    ].filter(Boolean).join(" · ");

    return [
      border,
      ...title,
      ...body.slice(0, CARD_ANSWER_LINES),
      ...new Text(this.theme.fg("muted", footer), 1, 0).render(width),
      border,
    ];
  }

  invalidate(): void {}
}

export default function backgroundTasks(pi: ExtensionAPI) {
  let activeContext: ExtensionContext | undefined;
  let pollTimer: ReturnType<typeof setInterval> | undefined;
  let polling = false;
  let selectedCardId: string | undefined;

  const currentSessionId = () => activeContext?.sessionManager.getSessionId();

  const pendingCards = (tasks: BackgroundTask[]) =>
    tasks
      .filter((task) => task.originSessionId === currentSessionId() && task.completion && !task.completion.dismissed)
      .sort((left, right) => (left.completion?.finishedAt ?? 0) - (right.completion?.finishedAt ?? 0));

  const selectedCard = (cards: BackgroundTask[]) =>
    cards.find((task) => task.id === selectedCardId) ?? cards[0];

  const render = async () => {
    const ctx = activeContext;
    if (!ctx || ctx.mode !== "tui") return;
    const tasks = await listTasks();
    if (ctx !== activeContext) return;

    const running = tasks.filter((task) => task.originSessionId === currentSessionId() && !task.completion).length;
    ctx.ui.setStatus("bg", running ? `bg: ${running} running · /bg` : undefined);

    const cards = pendingCards(tasks);
    const card = selectedCard(cards);
    if (!card) {
      ctx.ui.setWidget(CARD_WIDGET, undefined);
      return;
    }
    const position = cards.indexOf(card) + 1;
    ctx.ui.setWidget(CARD_WIDGET, (_tui, theme) => new ResultCard(card, position, cards.length, theme), {
      placement: "aboveEditor",
    });
  };

  const finish = async (task: BackgroundTask) => {
    const completed = { ...task, completion: await readCompletion(task) };
    await saveTask(completed);
    if (completed.originSessionId === currentSessionId()) {
      activeContext?.ui.notify(
        `Background task ${completed.completion.outcome}: ${shortTask(task.task, 60)} — /bg-result`,
        completed.completion.outcome === "failed" ? "error" : "info",
      );
    }
  };

  const poll = async () => {
    if (polling) return;
    polling = true;
    try {
      for (const task of await listTasks()) {
        if (!task.completion && !isRunning(task)) await finish(task);
      }
      await render();
    } catch (error) {
      activeContext?.ui.notify(`/bg: ${error instanceof Error ? error.message : String(error)}`, "error");
    } finally {
      polling = false;
    }
  };

  const update = async (task: BackgroundTask, change: (task: BackgroundTask) => void) => {
    const latest = (await listTasks()).find((entry) => entry.id === task.id);
    if (!latest) return;
    change(latest);
    await saveTask(latest);
    await render();
  };

  const startTask = async (description: string, ctx: ExtensionCommandContext) => {
    const id = randomUUID();
    const sessionId = randomUUID();
    const originFile = ctx.sessionManager.getSessionFile();
    const args = [
      ...(originFile && existsSync(originFile) ? ["--fork", originFile] : []),
      "--session-id", sessionId,
      "--name", `BG: ${shortTask(description, 90)}`,
      ...(ctx.model ? ["--model", `${ctx.model.provider}/${ctx.model.id}`, "--thinking", pi.getThinkingLevel()] : []),
      "--print",
      `${TASK_PROMPT}${description}`,
    ];

    await mkdir(tasksDirectory, { recursive: true });
    const log = openSync(logPath(id), "a");
    const { TMUX: _tmux, TMUX_PANE: _tmuxPane, ...env } = process.env;
    const child = spawn("pi", args, {
      cwd: ctx.cwd,
      detached: true,
      stdio: ["ignore", log, log],
      env: { ...env, PI_BG_TASK_ID: id },
    });
    closeSync(log);
    if (!child.pid) throw new Error("Could not start the background pi process.");
    child.unref();
    child.once("exit", () => void poll());

    await saveTask({
      version: 1,
      id,
      task: description,
      cwd: ctx.cwd,
      originSessionId: ctx.sessionManager.getSessionId(),
      sessionId,
      pid: child.pid,
      startedAt: Date.now(),
    });
    ctx.ui.notify("Background task started. /bg to view, open, or stop it.", "info");
    await render();
  };

  const bringIntoChat = (task: BackgroundTask, answer: string, ctx: ExtensionCommandContext) => {
    pi.sendMessage(
      {
        customType: RESULT_MESSAGE_TYPE,
        content: `Background task: ${task.task}\n\n${answer}`,
        display: true,
        details: { taskId: task.id },
      },
      ctx.isIdle() ? undefined : { deliverAs: "nextTurn" },
    );
    ctx.ui.notify("Result added for the next turn in this chat.", "info");
  };

  const taskActions = async (task: BackgroundTask, ctx: ExtensionCommandContext, cards?: BackgroundTask[]) => {
    const answer = task.completion?.answer ?? readCurrentReply(task);
    const running = !task.completion && isRunning(task);
    const sessionFile = taskSessionFile(task);
    const actions = new Map<string, () => Promise<void> | void>();

    if (answer) {
      actions.set("View full result", async () => {
        await ctx.ui.editor(shortTask(task.task), answer);
      });
    }
    if (cards && cards.length > 1) {
      actions.set("Next completed result", async () => {
        const index = cards.findIndex((card) => card.id === task.id);
        selectedCardId = cards[(index + 1) % cards.length]?.id;
        await render();
      });
    }
    if (sessionFile) {
      actions.set("Open task session", async () => {
        if (running) {
          ctx.ui.notify("Task is still running. Open it after it finishes, or stop it first.", "warning");
          return;
        }
        await ctx.switchSession(sessionFile);
      });
    }
    if (answer) {
      actions.set("Copy result", async () => {
        await copyToClipboard(answer);
        ctx.ui.notify("Copied background result.", "info");
      });
      actions.set("Bring result into this chat", () => bringIntoChat(task, answer, ctx));
    }
    if (running) {
      actions.set("Stop task", async () => {
        await update(task, (latest) => {
          latest.stopRequested = true;
        });
        try {
          process.kill(-task.pid, "SIGTERM");
        } catch {
          process.kill(task.pid, "SIGTERM");
        }
        ctx.ui.notify("Stopping background task.", "info");
      });
    }
    if (task.completion && !task.completion.dismissed) {
      actions.set("Dismiss result card", () =>
        update(task, (latest) => {
          if (latest.completion) latest.completion.dismissed = true;
        }),
      );
    }
    actions.set("Remove from task list", async () => {
      if (running) {
        ctx.ui.notify("Stop the task before removing it.", "warning");
        return;
      }
      await removeTask(task.id);
      await render();
    });

    const choice = await ctx.ui.select(shortTask(task.task), [...actions.keys()]);
    if (choice) await actions.get(choice)?.();
  };

  const browse = async (ctx: ExtensionCommandContext) => {
    const tasks = await listTasks();
    if (!tasks.length) {
      ctx.ui.notify("No background tasks yet. Use /bg <task>.", "info");
      return;
    }
    const labels = tasks.map((task, index) => {
      const place = task.cwd === ctx.cwd ? "" : ` · ${path.basename(task.cwd)}`;
      return `${index + 1}. ${shortTask(task.task, 60)} · ${taskState(task)} · ${relativeTime(task.startedAt)}${place}`;
    });
    const choice = await ctx.ui.select("Background tasks", labels);
    const task = choice ? tasks[labels.indexOf(choice)] : undefined;
    if (task) await taskActions(task, ctx);
  };

  pi.registerMessageRenderer(RESULT_MESSAGE_TYPE, (message) =>
    new Markdown(String(message.content), 1, 1, getMarkdownTheme()),
  );

  pi.registerCommand("bg", {
    description: "Run a background task with this conversation's context, or list background tasks",
    handler: async (args, ctx) => {
      const description = args.trim();
      if (description) await startTask(description, ctx);
      else if (ctx.hasUI) await browse(ctx);
      else ctx.ui.notify("Usage: /bg <task>", "info");
    },
  });

  pi.registerCommand("bg-result", {
    description: "Actions for the background result card above the prompt",
    handler: async (_args, ctx) => {
      const cards = pendingCards(await listTasks());
      const card = selectedCard(cards);
      if (!card) {
        ctx.ui.notify("No background results waiting. /bg lists all tasks.", "info");
        return;
      }
      await taskActions(card, ctx, cards);
    },
  });

  pi.on("session_start", (_event, ctx) => {
    if (process.env.PI_BG_TASK_ID) return;
    activeContext = ctx;
    selectedCardId = undefined;
    clearInterval(pollTimer);
    pollTimer = setInterval(() => void poll(), POLL_INTERVAL_MS);
    pollTimer.unref?.();
    void poll();
  });

  pi.on("session_shutdown", (_event, ctx) => {
    clearInterval(pollTimer);
    pollTimer = undefined;
    if (ctx.mode === "tui") {
      ctx.ui.setWidget(CARD_WIDGET, undefined);
      ctx.ui.setStatus("bg", undefined);
    }
    activeContext = undefined;
  });
}
