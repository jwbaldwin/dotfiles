import {
  highlightCode,
  keyHint,
  type AgentToolResult,
  type ExtensionAPI,
  type Theme,
  type ToolRenderResultOptions,
} from "@earendil-works/pi-coding-agent";
import {
  type Component,
  Text,
  truncateToWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";

import {
  registerFramedTool,
  type GenericTool,
  type ToolCardState,
} from "./tool-cards.ts";

const MCP_PREVIEW_ROWS = 10;
type GenericArgs = Record<string, unknown>;

type McpResultDetails = Record<string, unknown> & {
  server?: unknown;
  hintServer?: unknown;
  tool?: unknown;
  requestedTool?: unknown;
};

function stringValue(value: unknown): string | undefined {
  return typeof value === "string" && value ? value : undefined;
}

function mcpCallIdentity(
  tool: GenericTool,
  args: GenericArgs,
  state: ToolCardState,
): string {
  if (tool.name === "mcpScript") return "mcp · script";

  if (tool.name !== "mcp") {
    const toolName = tool.label.replace(/^MCP:\s*/i, "") || tool.name;
    state.mcpTool = toolName;
    return `mcp · ${toolName}`;
  }

  const server =
    stringValue(args.server) ??
    stringValue(args.connect) ??
    stringValue(args.instructions);
  const operation =
    stringValue(args.tool) ??
    (args.connect ? "connect" : undefined) ??
    (args.describe ? `describe ${String(args.describe)}` : undefined) ??
    (args.instructions ? "instructions" : undefined) ??
    (args.search ? `search ${String(args.search)}` : undefined) ??
    stringValue(args.action) ??
    "status";
  state.mcpTool = stringValue(args.tool);
  return ["mcp", server, operation].filter(Boolean).join(" · ");
}

function mcpResultIdentity(
  result: AgentToolResult<McpResultDetails>,
  _args: GenericArgs,
  state: ToolCardState,
): string | undefined {
  const details = result.details;
  const server =
    stringValue(details?.server) ?? stringValue(details?.hintServer);
  const tool =
    stringValue(details?.tool) ??
    stringValue(details?.requestedTool) ??
    stringValue(state.mcpTool);
  if (!server) return state.title;
  return ["mcp", server, tool].filter(Boolean).join(" · ");
}

function formatValue(value: unknown): string {
  if (typeof value === "string") {
    try {
      return JSON.stringify(JSON.parse(value), null, 2);
    } catch {
      return value;
    }
  }

  try {
    return JSON.stringify(value, null, 2);
  } catch {
    return String(value);
  }
}

function mcpCallBody(
  tool: GenericTool,
  args: GenericArgs,
  theme: Theme,
): Component {
  if (tool.name === "mcpScript" && typeof args.code === "string") {
    return new Text(highlightCode(args.code, "javascript").join("\n"), 0, 0);
  }

  const shownArgs = tool.name === "mcp" ? args.args : args;
  if (
    shownArgs === undefined ||
    (typeof shownArgs === "object" &&
      shownArgs !== null &&
      Object.keys(shownArgs).length === 0)
  ) {
    return new Text("", 0, 0);
  }

  return new Text(theme.fg("muted", formatValue(shownArgs)), 0, 0);
}

function resultText(result: AgentToolResult<McpResultDetails>): string {
  const lines = result.content.map((part) => {
    if (part.type === "text") return part.text;
    if (part.type === "image") return `[image: ${part.mimeType}]`;
    return `[${part.type}]`;
  });
  return lines.join("\n").trimEnd();
}

class McpResultPreview implements Component {
  private cachedWidth?: number;
  private cachedLines?: string[];

  constructor(
    private readonly output: string,
    private readonly expanded: boolean,
    private readonly theme: Theme,
  ) {}

  render(width: number): string[] {
    if (this.cachedWidth === width && this.cachedLines) return this.cachedLines;
    if (!this.output) return [this.theme.fg("dim", "(no output)")];

    const rows = this.output
      .split("\n")
      .flatMap((line) =>
        wrapTextWithAnsi(this.theme.fg("toolOutput", line), Math.max(1, width)),
      );
    if (this.expanded || rows.length <= MCP_PREVIEW_ROWS) {
      this.cachedLines = rows.map((line) => truncateToWidth(line, width, ""));
    } else {
      this.cachedLines = [
        ...rows.slice(0, MCP_PREVIEW_ROWS - 1),
        this.theme.fg(
          "dim",
          `… (${rows.length - MCP_PREVIEW_ROWS + 1} more rows, ${keyHint("app.tools.expand", "to expand")})`,
        ),
      ].map((line) => truncateToWidth(line, width, ""));
    }
    this.cachedWidth = width;
    return this.cachedLines;
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.cachedLines = undefined;
  }
}

function frameMcpTool(tool: GenericTool): GenericTool {
  return {
    ...tool,
    frameTitle: (args, state) => mcpCallIdentity(tool, args, state),
    frameResultTitle: (result, args, state) =>
      mcpResultIdentity(result, args, state),
    renderCall: (args, theme) => mcpCallBody(tool, args, theme),
    renderResult: (
      result: AgentToolResult<McpResultDetails>,
      options: ToolRenderResultOptions,
      theme: Theme,
    ) =>
      options.isPartial
        ? new Text(theme.fg("warning", "Running…"), 0, 0)
        : new McpResultPreview(resultText(result), options.expanded, theme),
  };
}

export function registerMcpAdapterWithToolCards(
  pi: ExtensionAPI,
  registerMcpAdapter: (pi: ExtensionAPI) => void,
): void {
  const decoratedPi = new Proxy(pi, {
    get(target, property, receiver) {
      if (property === "registerTool") {
        return (tool: GenericTool) =>
          registerFramedTool(target, frameMcpTool(tool));
      }
      const value = Reflect.get(target, property, receiver);
      return typeof value === "function" ? value.bind(target) : value;
    },
  });

  registerMcpAdapter(decoratedPi);
}
