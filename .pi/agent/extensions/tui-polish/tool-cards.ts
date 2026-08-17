import type { Component } from "@earendil-works/pi-tui";

import {
  createBashToolDefinition,
  createEditToolDefinition,
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createReadToolDefinition,
  createWriteToolDefinition,
  highlightCode,
  keyHint,
  type AgentToolResult,
  type BashToolDetails,
  type BashToolInput,
  type ExtensionAPI,
  type Theme,
  type ThemeColor,
  type ToolDefinition,
  type ToolRenderResultOptions,
} from "@earendil-works/pi-coding-agent";
import {
  Text,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { basename, dirname } from "node:path";

const PREVIEW_ROWS = 10;
const HORIZONTAL = "─";
type ToolCardState = {
  startedAt?: number;
  endedAt?: number;
  hasResult?: boolean;
  isPartial?: boolean;
  isError?: boolean;
  title?: string;
};

type BashCardState = ToolCardState;

type BashResult = {
  content: Array<{ type: string; text?: string }>;
  details?: BashToolDetails;
};

type BashRenderContext = {
  args: BashToolInput;
  state: BashCardState;
  lastComponent?: Component;
  executionStarted: boolean;
  isError: boolean;
};

function textOutput(result: BashResult): string {
  return result.content
    .filter(
      (part): part is { type: "text"; text: string } => part.type === "text",
    )
    .map((part) => part.text)
    .join("\n")
    .trimEnd();
}

function borderColor(state: BashCardState): ThemeColor {
  if (!state.hasResult || state.isPartial) return "borderMuted";
  return state.isError ? "error" : "borderMuted";
}

function padAnsi(text: string, width: number): string {
  const fitted = truncateToWidth(text, width, "");
  return `${fitted}${" ".repeat(Math.max(0, width - visibleWidth(fitted)))}`;
}

function borderLine(
  theme: Theme,
  color: ThemeColor,
  left: string,
  width: number,
  right: string,
): string {
  return theme.fg(
    color,
    `${left}${HORIZONTAL.repeat(Math.max(0, width - 2))}${right}`,
  );
}

function contentLine(
  theme: Theme,
  color: ThemeColor,
  text: string,
  width: number,
): string {
  const innerWidth = Math.max(1, width - 4);
  return `${theme.fg(color, "│")} ${padAnsi(text, innerWidth)} ${theme.fg(color, "│")}`;
}

function sectionLine(
  theme: Theme,
  color: ThemeColor,
  label: string,
  width: number,
): string {
  const prefix = "├─── ";
  const suffix = " ";
  const used =
    visibleWidth(prefix) + visibleWidth(label) + visibleWidth(suffix) + 1;
  if (width < used) return borderLine(theme, color, "├", width, "┤");

  return `${theme.fg(color, prefix)}${theme.fg("toolTitle", label)}${suffix}${theme.fg(
    color,
    `${HORIZONTAL.repeat(width - used)}┤`,
  )}`;
}

function commandLines(command: string, theme: Theme): string[] {
  const highlighted = highlightCode(command || "…", "bash");
  if (highlighted.length === 0) return [theme.fg("dim", "$")];
  return highlighted.map((line, index) =>
    index === 0 ? `${theme.fg("dim", "$ ")}${line}` : line,
  );
}

function outputRows(
  output: string,
  width: number,
  expanded: boolean,
  theme: Theme,
): string[] {
  if (!output) return [theme.fg("dim", "(no output)")];

  const innerWidth = Math.max(1, width - 4);
  const logicalLines = output.split("\n");
  const styled = (line: string) =>
    theme.fg("toolOutput", line.replaceAll("\t", "  "));

  if (expanded) {
    return logicalLines.flatMap((line) =>
      wrapTextWithAnsi(styled(line), innerWidth),
    );
  }

  const visible: string[] = [];
  let firstVisibleLine = logicalLines.length;
  for (
    let index = logicalLines.length - 1;
    index >= 0 && visible.length < PREVIEW_ROWS;
    index--
  ) {
    const wrapped = wrapTextWithAnsi(styled(logicalLines[index]!), innerWidth);
    const available = PREVIEW_ROWS - visible.length;
    visible.unshift(...wrapped.slice(-available));
    firstVisibleLine = index;
  }

  const hiddenLines = firstVisibleLine;
  if (hiddenLines > 0) {
    visible.unshift(
      theme.fg(
        "dim",
        `… (${hiddenLines} earlier ${hiddenLines === 1 ? "line" : "lines"}, ${keyHint("app.tools.expand", "to expand")})`,
      ),
    );
  }
  return visible;
}

function timingLine(
  args: BashToolInput,
  state: BashCardState,
  theme: Theme,
): string | undefined {
  if (!state.endedAt || !state.startedAt) return undefined;
  const parts = [
    `Took ${((state.endedAt - state.startedAt) / 1000).toFixed(1)}s`,
  ];
  if (typeof args.timeout === "number") parts.push(`Timeout ${args.timeout}s`);
  return theme.fg("dim", `⟨${parts.join(" | ")}⟩`);
}

class BashCallCard implements Component {
  private cachedWidth?: number;
  private cachedHasResult?: boolean;
  private cachedColor?: ThemeColor;
  private cachedLines?: string[];

  constructor(
    private args: BashToolInput,
    private theme: Theme,
    private state: BashCardState,
  ) {}

  update(args: BashToolInput, theme: Theme): void {
    this.args = args;
    this.theme = theme;
    this.invalidate();
  }

  render(width: number): string[] {
    if (width < 8)
      return commandLines(this.args.command, this.theme).map((line) =>
        truncateToWidth(line, width),
      );
    const color = borderColor(this.state);
    if (
      this.cachedWidth === width &&
      this.cachedHasResult === this.state.hasResult &&
      this.cachedColor === color &&
      this.cachedLines
    )
      return this.cachedLines;

    const innerWidth = Math.max(1, width - 4);
    const lines = [titleLine(this.theme, color, "bash", width)];
    for (const command of commandLines(this.args.command, this.theme)) {
      for (const wrapped of wrapTextWithAnsi(command, innerWidth)) {
        lines.push(contentLine(this.theme, color, wrapped, width));
      }
    }
    if (!this.state.hasResult)
      lines.push(borderLine(this.theme, color, "╰", width, "╯"));

    this.cachedWidth = width;
    this.cachedHasResult = this.state.hasResult;
    this.cachedColor = color;
    this.cachedLines = lines;
    return lines;
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.cachedHasResult = undefined;
    this.cachedColor = undefined;
    this.cachedLines = undefined;
  }
}

class BashResultCard implements Component {
  private cachedWidth?: number;
  private cachedLines?: string[];

  constructor(
    private result: BashResult,
    private options: ToolRenderResultOptions,
    private args: BashToolInput,
    private theme: Theme,
    private state: BashCardState,
  ) {}

  update(
    result: BashResult,
    options: ToolRenderResultOptions,
    args: BashToolInput,
    theme: Theme,
  ): void {
    this.result = result;
    this.options = options;
    this.args = args;
    this.theme = theme;
    this.invalidate();
  }

  render(width: number): string[] {
    const output = textOutput(this.result);
    if (width < 8) {
      return outputRows(output, width, this.options.expanded, this.theme).map(
        (line) => truncateToWidth(line, width, ""),
      );
    }
    const color = borderColor(this.state);
    if (this.cachedWidth === width && this.cachedLines) return this.cachedLines;

    const lines = [sectionLine(this.theme, color, "Output", width)];
    for (const outputLine of outputRows(
      output,
      width,
      this.options.expanded,
      this.theme,
    )) {
      lines.push(contentLine(this.theme, color, outputLine, width));
    }
    const timing = timingLine(this.args, this.state, this.theme);
    if (timing) lines.push(contentLine(this.theme, color, timing, width));
    lines.push(borderLine(this.theme, color, "╰", width, "╯"));

    this.cachedWidth = width;
    this.cachedLines = lines;
    return lines;
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.cachedLines = undefined;
  }
}

type GenericArgs = Record<string, unknown>;
type GenericRenderContext = {
  args: GenericArgs;
  state: ToolCardState;
  lastComponent?: Component;
  executionStarted: boolean;
  isError: boolean;
};
type GenericTool = {
  name: string;
  label: string;
  renderCall?: (
    args: GenericArgs,
    theme: Theme,
    context: GenericRenderContext,
  ) => Component;
  renderResult?: (
    result: AgentToolResult<any>,
    options: ToolRenderResultOptions,
    theme: Theme,
    context: GenericRenderContext,
  ) => Component;
  [key: string]: unknown;
};

function titleLine(
  theme: Theme,
  color: ThemeColor,
  title: string,
  width: number,
): string {
  const prefix = "╭── ";
  const suffix = " ";
  const used =
    visibleWidth(prefix) + visibleWidth(title) + visibleWidth(suffix) + 1;
  if (width < used) return borderLine(theme, color, "╭", width, "╮");

  return `${theme.fg(color, prefix)}${theme.fg("toolTitle", theme.bold(title))}${suffix}${theme.fg(
    color,
    `${HORIZONTAL.repeat(width - used)}╮`,
  )}`;
}

function toolTitle(toolName: string, args: GenericArgs): string {
  if (toolName !== "read" || typeof args.path !== "string") return toolName;

  const path = args.path;
  if (basename(path).toLowerCase() !== "skill.md") return toolName;
  return `skill · ${basename(dirname(path))}`;
}

class ToolCallCard implements Component {
  private cachedWidth?: number;
  private cachedHasResult?: boolean;
  private cachedColor?: ThemeColor;
  private cachedTitle?: string;
  private cachedLines?: string[];

  constructor(
    public inner: Component,
    private theme: Theme,
    private state: ToolCardState,
  ) {}

  update(inner: Component, theme: Theme): void {
    this.inner = inner;
    this.theme = theme;
    this.invalidate();
  }

  render(width: number): string[] {
    if (width < 8)
      return this.inner
        .render(width)
        .map((line: string) => truncateToWidth(line, width, ""));
    const color = borderColor(this.state);
    const title = this.state.title ?? "tool";
    if (
      this.cachedWidth === width &&
      this.cachedHasResult === this.state.hasResult &&
      this.cachedColor === color &&
      this.cachedTitle === title &&
      this.cachedLines
    )
      return this.cachedLines;

    const innerWidth = Math.max(1, width - 4);
    const lines = [titleLine(this.theme, color, title, width)];
    for (const line of this.inner.render(innerWidth)) {
      lines.push(contentLine(this.theme, color, line, width));
    }
    if (!this.state.hasResult)
      lines.push(borderLine(this.theme, color, "╰", width, "╯"));

    this.cachedWidth = width;
    this.cachedHasResult = this.state.hasResult;
    this.cachedColor = color;
    this.cachedTitle = title;
    this.cachedLines = lines;
    return lines;
  }

  invalidate(): void {
    this.inner.invalidate();
    this.cachedWidth = undefined;
    this.cachedHasResult = undefined;
    this.cachedColor = undefined;
    this.cachedTitle = undefined;
    this.cachedLines = undefined;
  }
}

class ToolResultCard implements Component {
  private cachedWidth?: number;
  private cachedColor?: ThemeColor;
  private cachedLines?: string[];

  constructor(
    public inner: Component,
    private theme: Theme,
    private state: ToolCardState,
  ) {}

  update(inner: Component, theme: Theme): void {
    this.inner = inner;
    this.theme = theme;
    this.invalidate();
  }

  render(width: number): string[] {
    if (width < 8)
      return this.inner
        .render(width)
        .map((line: string) => truncateToWidth(line, width, ""));
    const color = borderColor(this.state);
    if (
      this.cachedWidth === width &&
      this.cachedColor === color &&
      this.cachedLines
    ) {
      return this.cachedLines;
    }

    const innerWidth = Math.max(1, width - 4);
    const lines = [sectionLine(this.theme, color, "Result", width)];
    for (const line of this.inner.render(innerWidth)) {
      lines.push(contentLine(this.theme, color, line, width));
    }
    if (this.state.startedAt && this.state.endedAt) {
      const seconds = (
        (this.state.endedAt - this.state.startedAt) /
        1000
      ).toFixed(1);
      lines.push(
        contentLine(
          this.theme,
          color,
          this.theme.fg("dim", `⟨Took ${seconds}s⟩`),
          width,
        ),
      );
    }
    lines.push(borderLine(this.theme, color, "╰", width, "╯"));

    this.cachedWidth = width;
    this.cachedColor = color;
    this.cachedLines = lines;
    return lines;
  }

  invalidate(): void {
    this.inner.invalidate();
    this.cachedWidth = undefined;
    this.cachedColor = undefined;
    this.cachedLines = undefined;
  }
}

function registerFramedTool(pi: ExtensionAPI, base: GenericTool): void {
  const originalRenderCall = base.renderCall;
  const originalRenderResult = base.renderResult;

  const decorated = {
    ...base,
    renderShell: "self" as const,
    renderCall(args: GenericArgs, theme: Theme, context: GenericRenderContext) {
      const cardContext = context;
      cardContext.state.startedAt ??= Date.now();
      cardContext.state.title = toolTitle(base.name, args);

      const previousCard =
        cardContext.lastComponent instanceof ToolCallCard
          ? cardContext.lastComponent
          : undefined;
      const innerContext = {
        ...cardContext,
        lastComponent: previousCard?.inner,
      };
      const inner =
        originalRenderCall?.(args, theme, innerContext) ??
        new Text(theme.fg("toolTitle", base.label || base.name), 0, 0);
      const card =
        previousCard ?? new ToolCallCard(inner, theme, cardContext.state);
      card.update(inner, theme);
      return card;
    },
    renderResult(
      result: AgentToolResult<any>,
      options: ToolRenderResultOptions,
      theme: Theme,
      context: GenericRenderContext,
    ) {
      const cardContext = context;
      cardContext.state.hasResult = true;
      cardContext.state.isPartial = options.isPartial;
      cardContext.state.isError = cardContext.isError;
      if (!options.isPartial) cardContext.state.endedAt ??= Date.now();

      const previousCard =
        cardContext.lastComponent instanceof ToolResultCard
          ? cardContext.lastComponent
          : undefined;
      const innerContext = {
        ...cardContext,
        lastComponent: previousCard?.inner,
      };
      const inner =
        originalRenderResult?.(result, options, theme, innerContext) ??
        new Text(
          theme.fg(
            options.isPartial ? "warning" : "success",
            options.isPartial ? "Working…" : "Done",
          ),
          0,
          0,
        );
      const card =
        previousCard ?? new ToolResultCard(inner, theme, cardContext.state);
      card.update(inner, theme);
      return card;
    },
  };

  pi.registerTool(decorated as unknown as ToolDefinition<any, any, any>);
}

export function registerToolCards(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    // Extension and MCP tools already use Pi's generic card shell. Built-ins
    // supply their own renderers, so wrap those renderers to give every tool
    // the same frame without replacing their rich output and diffs.
    const framedTools = [
      createReadToolDefinition(ctx.cwd),
      createEditToolDefinition(ctx.cwd),
      createWriteToolDefinition(ctx.cwd),
      createGrepToolDefinition(ctx.cwd),
      createFindToolDefinition(ctx.cwd),
      createLsToolDefinition(ctx.cwd),
    ] as unknown as GenericTool[];
    for (const tool of framedTools) registerFramedTool(pi, tool);

    const base = createBashToolDefinition(ctx.cwd);
    pi.registerTool({
      ...base,
      renderShell: "self",
      renderCall(args, theme, context) {
        const cardContext = context as BashRenderContext;
        if (
          cardContext.executionStarted &&
          cardContext.state.startedAt === undefined
        ) {
          cardContext.state.startedAt = Date.now();
        }
        const card =
          cardContext.lastComponent instanceof BashCallCard
            ? cardContext.lastComponent
            : new BashCallCard(args, theme, cardContext.state);
        card.update(args, theme);
        return card;
      },
      renderResult(result, options, theme, context) {
        const cardContext = context as BashRenderContext;
        cardContext.state.hasResult = true;
        cardContext.state.isPartial = options.isPartial;
        cardContext.state.isError = cardContext.isError;
        if (!options.isPartial) cardContext.state.endedAt ??= Date.now();

        const card =
          cardContext.lastComponent instanceof BashResultCard
            ? cardContext.lastComponent
            : new BashResultCard(
                result,
                options,
                cardContext.args,
                theme,
                cardContext.state,
              );
        card.update(result, options, cardContext.args, theme);
        return card;
      },
    });
  });
}
