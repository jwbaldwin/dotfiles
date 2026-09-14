import { execFile } from "node:child_process";
import { promisify } from "node:util";

const exec = promisify(execFile);

export type JujutsuStatus = {
  changeID: string;
  bookmark?: string;
  distance: number;
};

export async function readJujutsuStatus(
  directory: string,
  signal: AbortSignal,
): Promise<JujutsuStatus | undefined> {
  const log = async (revisions: string, template: string) => {
    const { stdout } = await exec(
      "jj",
      [
        "--ignore-working-copy",
        "--no-pager",
        "--color=never",
        "log",
        "--no-graph",
        "-r",
        revisions,
        "-T",
        template,
      ],
      { cwd: directory, signal, timeout: 2000, maxBuffer: 65536 },
    );
    return stdout;
  };

  try {
    const revisions = await log(
      "@ | latest(heads(::@ & bookmarks()))",
      'current_working_copy ++ "\t" ++ change_id.shortest(4) ++ "\t" ++ commit_id ++ "\t" ++ local_bookmarks.join(",") ++ "\n"',
    );
    const entries = revisions
      .trimEnd()
      .split("\n")
      .map((line) => line.split("\t"));
    const current = entries.find(([workingCopy]) => workingCopy === "true");
    if (!current || !current[1] || !/^[a-f0-9]+$/.test(current[2] ?? "")) return;
    const changeID = current[1];
    const bookmarked = entries.find((entry) => entry[3]);
    if (!bookmarked) return { changeID, distance: 0 };
    const [, , commitID, bookmark] = bookmarked;
    if (!commitID || !/^[a-f0-9]+$/.test(commitID)) return;
    const commits = await log(`${commitID}..${current[2]}`, '"x"');
    if (!/^x*$/.test(commits)) return;
    return { changeID, bookmark, distance: commits.length };
  } catch {
    return undefined;
  }
}
