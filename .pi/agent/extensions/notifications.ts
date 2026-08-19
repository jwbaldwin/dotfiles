import { spawn, spawnSync } from "node:child_process";
import path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const GHOSTTY_BUNDLE_ID = "com.mitchellh.ghostty";
const MINIMUM_TURN_DURATION_MS = 15_000;
const TITLE_UPDATE_DELAY_MS = 400;
const COMPLETION_SOUND = path.join(process.env.HOME ?? "", "Library/Sounds/codex-notification.wav");

function run(command: string, args: string[]): string | undefined {
  const result = spawnSync(command, args, { encoding: "utf8" });
  if (result.status !== 0) return undefined;
  return result.stdout.trim() || undefined;
}

function frontmostBundleIdentifier(): string | undefined {
  const application = run("/usr/bin/lsappinfo", ["front"]);
  if (!application) return undefined;

  const applicationInfo = run("/usr/bin/lsappinfo", ["info", "-only", "bundleid", application]);
  return applicationInfo?.match(/"CFBundleIdentifier"="([^"]+)"/)?.[1];
}

function notificationTitle(ctx: ExtensionContext): string {
  if (process.env.TMUX && process.env.TMUX_PANE) {
    const tmuxSession = run("tmux", ["display-message", "-p", "-t", process.env.TMUX_PANE, "#S"]);
    if (tmuxSession) return tmuxSession;
  }

  return `${path.basename(ctx.cwd)} · pi`;
}

function safeTerminalText(text: string): string {
  return text.replace(/[\x00-\x1f\x7f]/g, " ").replaceAll(";", ",").trim();
}

function terminalSequence(sequence: string): string {
  if (!process.env.TMUX) return sequence;
  return `\x1bPtmux;${sequence.replaceAll("\x1b", "\x1b\x1b")}\x1b\\`;
}

function writeTerminalSequence(sequence: string): void {
  process.stdout.write(terminalSequence(sequence));
}

function setTerminalTitle(title: string): void {
  writeTerminalSequence(`\x1b]2;${safeTerminalText(title)}\x1b\\`);
}

function sendNotification(title: string): void {
  writeTerminalSequence(`\x1b]777;notify;${safeTerminalText(title)};\x07`);

  const sound = spawn("/usr/bin/afplay", [COMPLETION_SOUND], {
    detached: true,
    stdio: "ignore",
  });
  sound.unref();
}

function delay(milliseconds: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, milliseconds));
}

export default function notifications(pi: ExtensionAPI) {
  let turnStartedAt: number | undefined;

  pi.on("agent_start", () => {
    turnStartedAt ??= Date.now();
  });

  pi.on("agent_settled", async (_event, ctx) => {
    const startedAt = turnStartedAt;
    turnStartedAt = undefined;

    if (ctx.mode !== "tui" || startedAt === undefined) return;
    if (Date.now() - startedAt <= MINIMUM_TURN_DURATION_MS) return;

    const frontmostApplication = frontmostBundleIdentifier();
    if (!frontmostApplication || frontmostApplication === GHOSTTY_BUNDLE_ID) return;

    const sessionName = pi.getSessionName() ?? path.basename(ctx.cwd);
    setTerminalTitle(sessionName);
    await delay(TITLE_UPDATE_DELAY_MS);
    sendNotification(notificationTitle(ctx));
  });
}
