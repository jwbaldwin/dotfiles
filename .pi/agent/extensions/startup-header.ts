import {
  SessionManager,
  VERSION,
  type ExtensionAPI,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const MCP_STATUS_EVENT = "pi-mcp-adapter/status/v1";
const RECENT_SESSION_COUNT = 3;
const LOGO = [
  " ▄████████████████████▄ ",
  "████████████████████████",
  "     ████      ████     ",
  "     ████      ████     ",
  "     ████      ████     ",
  "     ████      ████     ",
  "     ████      ████     ",
];

interface McpStatusSnapshot {
  version: 1;
  servers: ReadonlyArray<{
    status: "connected" | "cached" | "failed" | "needs-auth" | "not-connected" | "disabled";
  }>;
}

const GRADIENT = [
  { red: 79, green: 107, blue: 255 },
  { red: 56, green: 217, blue: 255 },
  { red: 168, green: 85, blue: 247 },
] as const;

function interpolate(start: number, end: number, amount: number): number {
  return Math.round(start + (end - start) * amount);
}

function gradientColor(position: number): string {
  const scaled = Math.max(0, Math.min(1, position)) * (GRADIENT.length - 1);
  const startIndex = Math.min(Math.floor(scaled), GRADIENT.length - 2);
  const amount = scaled - startIndex;
  const start = GRADIENT[startIndex]!;
  const end = GRADIENT[startIndex + 1]!;
  const red = interpolate(start.red, end.red, amount);
  const green = interpolate(start.green, end.green, amount);
  const blue = interpolate(start.blue, end.blue, amount);
  return `\x1b[38;2;${red};${green};${blue}m`;
}

function colorLogoLine(line: string): string {
  const width = Math.max(1, visibleWidth(line) - 1);
  return [...line]
    .map((character, index) =>
      character === " " ? character : `${gradientColor(index / width)}${character}`,
    )
    .join("");
}

function center(text: string, width: number): string {
  const fitted = truncateToWidth(text, width, "");
  return `${" ".repeat(Math.max(0, Math.floor((width - visibleWidth(fitted)) / 2)))}${fitted}`;
}

function recentSessionBlock(sessionNames: string[], width: number, theme: Theme): string[] {
  const heading = "recent sessions";
  const blockWidth = Math.min(width, 48);
  const leftPadding = " ".repeat(Math.max(0, Math.floor((width - blockWidth) / 2)));
  const sessionSlots = Array.from(
    { length: RECENT_SESSION_COUNT },
    (_, index) => sessionNames[index],
  );

  return [
    `${leftPadding}${theme.fg("dim", truncateToWidth(heading, blockWidth, ""))}`,
    "",
    ...sessionSlots.map((name) => {
      if (!name) return "";
      const fittedName = truncateToWidth(
        name,
        Math.max(0, blockWidth - 2),
        theme.fg("dim", "…"),
      );
      return `${leftPadding}${theme.fg("dim", "·")} ${fittedName}`;
    }),
  ];
}

function isMcpStatusSnapshot(value: unknown): value is McpStatusSnapshot {
  if (!value || typeof value !== "object") return false;
  const snapshot = value as Partial<McpStatusSnapshot>;
  return snapshot.version === 1 && Array.isArray(snapshot.servers);
}

export default function startupHeader(pi: ExtensionAPI) {
  let recentSessionNames: string[] = [];
  let mcpServerCount = 0;
  let requestRender: (() => void) | undefined;

  const unsubscribeMcpStatus = pi.events.on(MCP_STATUS_EVENT, (snapshot) => {
    if (!isMcpStatusSnapshot(snapshot)) return;
    mcpServerCount = snapshot.servers.filter((server) => server.status !== "disabled").length;
    requestRender?.();
  });

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    // Mount the full-height header before doing any session I/O. The prompt stays
    // interactive while recent session names fill their reserved rows in place.
    ctx.ui.setHeader((tui, theme) => {
      requestRender = () => tui.requestRender();
      return {
        render(width: number): string[] {
          const skillCount = pi.getCommands().filter((command) => command.source === "skill").length;
          const toolCount = pi.getActiveTools().length;
          const facts = `skills ${skillCount} · mcp ${mcpServerCount} · tools ${toolCount}`;

          return [
            "",
            ...LOGO.map((line) => center(colorLogoLine(line), width)),
            "",
            center(`${theme.fg("text", "pi")} ${theme.fg("dim", `v${VERSION}`)}`, width),
            center(theme.fg("muted", facts), width),
            "",
            "",
            ...recentSessionBlock(recentSessionNames, width, theme),
            "",
          ];
        },
        invalidate() {},
      };
    });

    const currentSession = ctx.sessionManager.getSessionFile();
    const projectSessions = await SessionManager.list(ctx.cwd).catch(() => []);
    const namedProjectSessions = projectSessions
      .filter((session) => session.path !== currentSession && session.name)
      .sort((left, right) => right.modified.getTime() - left.modified.getTime());

    let recentSessions = namedProjectSessions;
    if (recentSessions.length < RECENT_SESSION_COUNT) {
      const projectSessionPaths = new Set(projectSessions.map((session) => session.path));
      const otherSessions = await SessionManager.listAll().catch(() => []);
      const namedOtherSessions = otherSessions
        .filter(
          (session) =>
            session.path !== currentSession &&
            !projectSessionPaths.has(session.path) &&
            session.name,
        )
        .sort((left, right) => right.modified.getTime() - left.modified.getTime());
      recentSessions = [...recentSessions, ...namedOtherSessions];
    }

    recentSessionNames = recentSessions
      .slice(0, RECENT_SESSION_COUNT)
      .map((session) => session.name!);
    requestRender?.();
  });

  pi.on("session_shutdown", (_event, ctx) => {
    unsubscribeMcpStatus();
    if (ctx.mode === "tui") ctx.ui.setHeader(undefined);
    requestRender = undefined;
  });
}
