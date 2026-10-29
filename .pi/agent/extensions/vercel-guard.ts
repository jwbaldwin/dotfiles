import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const GUARDED_VERCEL_COMMANDS = [
  /\bvercel\s+deploy\b/,
  /\bvercel\b.*\s--prod\b/,
  /\bvercel\s+env\s+(add|rm)\b/,
  /\bvercel\s+alias\b/,
  /\bvercel\s+rollback\b/,
];

export default function vercelGuard(pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;
    const command = String((event.input as { command?: unknown }).command ?? "");
    if (!GUARDED_VERCEL_COMMANDS.some((pattern) => pattern.test(command))) return;

    if (!ctx.hasUI) {
      return { block: true, reason: "Vercel production commands need James's approval in an interactive session." };
    }
    const approved = await ctx.ui.confirm("Run Vercel command?", command);
    if (!approved) return { block: true, reason: "James declined this Vercel command." };
  });
}
