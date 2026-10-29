import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const exec = promisify(execFile);

async function jj(cwd: string, ...args: string[]): Promise<string> {
  const { stdout } = await exec("jj", ["--ignore-working-copy", "--no-pager", "--color=never", ...args], {
    cwd,
    timeout: 2000,
    maxBuffer: 65536,
  });
  return stdout.trim();
}

export async function readBookmarkLabel(cwd: string): Promise<string | undefined> {
  try {
    const [bookmarks, commitId] = (
      await jj(cwd, "log", "--no-graph", "-r", "latest(heads(::@ & bookmarks()))", "-T", 'local_bookmarks.join(",") ++ "\\t" ++ commit_id')
    ).split("\t");
    if (!bookmarks || !commitId) return await jj(cwd, "log", "--no-graph", "-r", "@", "-T", "change_id.shortest(4)");
    const distance = (await jj(cwd, "log", "--no-graph", "-r", `${commitId}..@ ~ (@ & empty())`, "-T", '"x"')).length;
    return distance > 0 ? `${bookmarks} ↑${distance}` : bookmarks;
  } catch {
    return undefined;
  }
}

export function renderFooterLine(pi: ExtensionAPI, ctx: ExtensionContext, theme: Theme, vcsLabel: string | undefined, statuses: Iterable<string>, width: number): string {
  const separator = theme.fg("dim", " · ");
  const percent = ctx.getContextUsage()?.percent;
  const parts = [
    theme.fg("text", ctx.model?.id ?? "no model"),
    ctx.model?.reasoning ? theme.fg("muted", pi.getThinkingLevel()) : undefined,
    theme.fg("muted", typeof percent === "number" ? `${percent.toFixed(1)}%` : "—"),
    vcsLabel ? theme.fg("muted", vcsLabel) : undefined,
    ...[...statuses].map((status) => theme.fg("muted", status)),
  ];
  return truncateToWidth(parts.filter(Boolean).join(separator), width, theme.fg("dim", "…"));
}
