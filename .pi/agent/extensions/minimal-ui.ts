import {
  CustomEditor,
  type ExtensionAPI,
  type ExtensionContext,
  type KeybindingsManager,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import type { Component, EditorTheme, TUI } from "@earendil-works/pi-tui";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const STATUS_WIDGET = "minimal-ui-status";
const ANSI_PATTERN = /\x1b\[[0-?]*[ -/]*[@-~]/g;

function plainText(text: string): string {
  return text.replace(ANSI_PATTERN, "");
}

function formatDirectory(cwd: string): string {
  const home = process.env.HOME;
  const path = home && cwd.startsWith(home) ? `~${cwd.slice(home.length)}` : cwd;
  const parts = path.split("/").filter(Boolean);
  if (parts.length <= 3) return path;
  return `${path.startsWith("~") ? "~" : "…"}/…/${parts.slice(-2).join("/")}`;
}

function effortDial(theme: Theme, level: string): string {
  const dial = {
    off: "\uf05e",
    minimal: "\u{f0a9e}",
    low: "\u{f0a9f}",
    medium: "\u{f0aa1}",
    high: "\u{f0aa3}",
    xhigh: "\u{f0aa5}",
    max: "\uf06d",
  }[level] ?? "\uf05e";
  return theme.fg("muted", dial);
}

function contextPercent(ctx: ExtensionContext): number | undefined {
  const percent = ctx.getContextUsage()?.percent;
  return typeof percent === "number" ? percent : undefined;
}

function alignStatus(left: string, right: string, width: number, theme: Theme): string {
  if (width <= 0) return "";
  const gap = 2;
  const rightWidth = visibleWidth(right);
  const leftWidth = Math.max(0, width - rightWidth - gap);
  const fittedLeft = truncateToWidth(left, leftWidth, theme.fg("dim", "…"));
  const padding = " ".repeat(Math.max(1, width - visibleWidth(fittedLeft) - rightWidth));
  return truncateToWidth(`${fittedLeft}${padding}${right}`, width, "");
}

class EmptyFooter implements Component {
  render(): string[] {
    return [];
  }

  invalidate(): void {}
}

class RoundedPromptEditor extends CustomEditor {
  constructor(tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) {
    super(tui, theme, keybindings, { paddingX: 0 });
  }

  render(width: number): string[] {
    if (width < 6) return super.render(width);

    const innerWidth = width - 5;
    const lines = super.render(innerWidth);
    if (lines.length < 3) return lines;

    const border = (text: string) => this.borderColor(text);
    const bottomBorder = lines.findIndex(
      (line, index) => index > 0 && plainText(line).includes("─") && /^[─ ↑↓0-9]+$/.test(plainText(line)),
    );
    if (bottomBorder < 2) return lines;

    const result: string[] = [];
    result.push(`${border("╭")}${lines[0]}${border("───╮")}`);

    for (let index = 1; index < bottomBorder; index++) {
      const prompt = index === 1 ? `${border("❯")} ` : "  ";
      result.push(`${border("│")} ${prompt}${lines[index]}${border("│")}`);
    }

    result.push(`${border("╰───")}${lines[bottomBorder]}${border("╯")}`);

    for (const line of lines.slice(bottomBorder + 1)) {
      result.push(`  ${line}   `);
    }

    return result;
  }
}

export default function minimalUi(pi: ExtensionAPI) {
  let activeSessionId: string | undefined;
  let jjStatus = "";
  let requestRender: (() => void) | undefined;

  const isActive = (ctx: ExtensionContext) =>
    ctx.sessionManager.getSessionId() === activeSessionId;

  const refreshJj = async (ctx: ExtensionContext) => {
    const result = await pi.exec("/opt/homebrew/bin/jj-prompt", [], { cwd: ctx.cwd, timeout: 1500 }).catch(() => undefined);
    if (!isActive(ctx)) return;
    jjStatus = result?.code === 0 ? result.stdout.trim() : "";
    requestRender?.();
  };

  const renderStatus = (ctx: ExtensionContext, theme: Theme, width: number): string => {
    const model = (ctx.model?.name || ctx.model?.id || "no model").toLowerCase();
    const effort = effortDial(theme, pi.getThinkingLevel());
    const directory = formatDirectory(ctx.cwd);
    const modelStatus = `${effort} ${theme.fg("muted", model)}`;
    const left = `  ${[modelStatus, theme.fg("accent", directory), jjStatus]
      .filter(Boolean)
      .join("  ")}`;

    const sessionName = ctx.sessionManager.getSessionName();
    const percent = contextPercent(ctx);
    const context = percent === undefined
      ? theme.fg("dim", "ctx —")
      : theme.fg("muted", `${Math.round(percent)}%`);
    const right = [sessionName ? theme.fg("muted", sessionName) : "", context]
      .filter(Boolean)
      .join(theme.fg("dim", " · "));

    return alignStatus(left, right, width, theme);
  };

  const rerender = (ctx: ExtensionContext, refreshJjStatus = false) => {
    if (!isActive(ctx)) return;
    requestRender?.();
    if (refreshJjStatus) void refreshJj(ctx);
  };

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    activeSessionId = ctx.sessionManager.getSessionId();
    jjStatus = "";

    ctx.ui.setFooter(() => new EmptyFooter());
    ctx.ui.setWidget(
      STATUS_WIDGET,
      (tui, theme) => {
        requestRender = () => tui.requestRender();
        return {
          render: (width: number) => [renderStatus(ctx, theme, width)],
          invalidate() {},
        };
      },
      { placement: "aboveEditor" },
    );
    ctx.ui.setEditorComponent(
      (tui, theme, keybindings) => new RoundedPromptEditor(tui, theme, keybindings),
    );

    void refreshJj(ctx);
  });

  pi.on("model_select", (_event, ctx) => rerender(ctx));
  pi.on("thinking_level_select", (_event, ctx) => rerender(ctx));
  pi.on("session_info_changed", (_event, ctx) => rerender(ctx));
  pi.on("message_end", (_event, ctx) => rerender(ctx));
  pi.on("tool_execution_end", (_event, ctx) => rerender(ctx, true));
  pi.on("session_compact", (_event, ctx) => rerender(ctx));

  pi.on("session_shutdown", (_event, ctx) => {
    if (!isActive(ctx)) return;
    ctx.ui.setWidget(STATUS_WIDGET, undefined);
    ctx.ui.setFooter(undefined);
    ctx.ui.setEditorComponent(undefined);
    activeSessionId = undefined;
    requestRender = undefined;
  });
}
