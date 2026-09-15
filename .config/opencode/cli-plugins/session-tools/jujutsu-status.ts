import { execFile } from "node:child_process";
import { promisify } from "node:util";

const exec = promisify(execFile);

export type JujutsuStatus = {
  changeID: string;
  currentBookmarks: string;
  description: string;
  changedFiles: number;
  bookmark?: string;
  distance: number;
};

export async function readJujutsuStatus(
  directory: string,
  signal: AbortSignal,
): Promise<JujutsuStatus | undefined> {
  const jj = async (...args: string[]) => {
    const { stdout } = await exec(
      "jj",
      [
        "--ignore-working-copy",
        "--no-pager",
        "--color=never",
        ...args,
      ],
      { cwd: directory, signal, timeout: 2000, maxBuffer: 65536 },
    );
    return stdout;
  };

  try {
    const revisions = await jj(
      "log",
      "--no-graph",
      "-r",
      "@ | latest(heads(::@ & bookmarks()))",
      "-T",
      'current_working_copy ++ "\t" ++ change_id.shortest(4) ++ "\t" ++ commit_id ++ "\t" ++ local_bookmarks.join(",") ++ "\t" ++ description.first_line() ++ "\n"',
    );
    const entries = revisions
      .trimEnd()
      .split("\n")
      .map((line) => line.split("\t"));
    const current = entries.find(([workingCopy]) => workingCopy === "true");
    if (!current || !current[1] || !/^[a-f0-9]+$/.test(current[2] ?? "")) return;
    const diff = await jj("diff", "--stat");
    const summary = diff.trimEnd().split("\n").at(-1) ?? "";
    const status = {
      changeID: current[1],
      currentBookmarks: current[3] ?? "",
      description: current.slice(4).join("\t").trim(),
      changedFiles: Number(summary.match(/^(\d+) files? changed/)?.[1] ?? 0),
    };
    const bookmarked = entries.find((entry) => entry[3]);
    if (!bookmarked) return { ...status, distance: 0 };
    const [, , commitID, bookmark] = bookmarked;
    if (!commitID || !/^[a-f0-9]+$/.test(commitID)) return;
    const commits = await jj(
      "log",
      "--no-graph",
      "-r",
      `${commitID}..${current[2]}`,
      "-T",
      '"x"',
    );
    if (!/^x*$/.test(commits)) return;
    return { ...status, bookmark, distance: commits.length };
  } catch {
    return undefined;
  }
}
