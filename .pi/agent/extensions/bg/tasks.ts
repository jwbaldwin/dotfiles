import { getAgentDir, SessionManager } from "@earendil-works/pi-coding-agent";
import { mkdir, readdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import path from "node:path";

export type TaskOutcome = "complete" | "failed" | "interrupted";

export type BackgroundTask = {
  version: 1;
  id: string;
  task: string;
  cwd: string;
  originSessionId: string;
  sessionId: string;
  pid: number;
  startedAt: number;
  stopRequested?: boolean;
  completion?: {
    outcome: TaskOutcome;
    answer: string;
    finishedAt: number;
    dismissed?: boolean;
  };
};

export const tasksDirectory = path.join(getAgentDir(), "bg-tasks");

const taskPath = (id: string) => path.join(tasksDirectory, `${id}.json`);
export const logPath = (id: string) => path.join(tasksDirectory, `${id}.log`);

export async function saveTask(task: BackgroundTask): Promise<void> {
  await mkdir(tasksDirectory, { recursive: true });
  const temporary = `${taskPath(task.id)}.${process.pid}.${Date.now()}.tmp`;
  await writeFile(temporary, `${JSON.stringify(task, null, 2)}\n`, "utf8");
  await rename(temporary, taskPath(task.id));
}

export async function listTasks(): Promise<BackgroundTask[]> {
  let names: string[];
  try {
    names = await readdir(tasksDirectory);
  } catch {
    return [];
  }
  const tasks = await Promise.all(
    names
      .filter((name) => name.endsWith(".json"))
      .map(async (name) => {
        try {
          const task = JSON.parse(await readFile(path.join(tasksDirectory, name), "utf8"));
          return task?.version === 1 ? (task as BackgroundTask) : undefined;
        } catch {
          return undefined;
        }
      }),
  );
  return tasks
    .filter((task): task is BackgroundTask => Boolean(task))
    .sort((left, right) => right.startedAt - left.startedAt);
}

export async function removeTask(id: string): Promise<void> {
  await rm(taskPath(id), { force: true });
  await rm(logPath(id), { force: true });
}

export function isRunning(task: BackgroundTask): boolean {
  if (task.completion) return false;
  try {
    process.kill(task.pid, 0);
    return true;
  } catch (error) {
    return (error as NodeJS.ErrnoException).code === "EPERM";
  }
}

export function taskSessionFile(task: BackgroundTask): string | undefined {
  return SessionManager.findById(task.cwd, task.sessionId);
}

function lastAssistantReply(task: BackgroundTask) {
  const sessionFile = taskSessionFile(task);
  if (!sessionFile) return undefined;
  const entries = SessionManager.open(sessionFile).getBranch();
  for (const entry of entries.toReversed()) {
    if (entry.type !== "message" || entry.message.role !== "assistant") continue;
    if (entry.message.timestamp < task.startedAt) return undefined;
    return entry.message;
  }
  return undefined;
}

async function logTail(id: string): Promise<string> {
  try {
    return (await readFile(logPath(id), "utf8")).trim().split("\n").slice(-20).join("\n");
  } catch {
    return "";
  }
}

export async function readCompletion(task: BackgroundTask): Promise<NonNullable<BackgroundTask["completion"]>> {
  const reply = lastAssistantReply(task);
  const text = reply?.content
    .filter((part) => part.type === "text")
    .map((part) => part.text)
    .join("\n")
    .trim();

  const outcome: TaskOutcome = task.stopRequested || reply?.stopReason === "aborted"
    ? "interrupted"
    : reply?.stopReason === "stop" || reply?.stopReason === "length"
      ? "complete"
      : "failed";

  const answer = text
    || reply?.errorMessage
    || (await logTail(task.id))
    || "No background response returned.";
  return { outcome, answer, finishedAt: Date.now() };
}

export function readCurrentReply(task: BackgroundTask): string | undefined {
  try {
    const reply = lastAssistantReply(task);
    return reply?.content
      .filter((part) => part.type === "text")
      .map((part) => part.text)
      .join("\n")
      .trim() || undefined;
  } catch {
    return undefined;
  }
}
