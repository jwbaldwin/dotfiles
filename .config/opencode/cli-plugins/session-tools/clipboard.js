import { execFile } from "node:child_process";

export function copyText(text) {
  return new Promise((resolve, reject) => {
    const child = execFile("pbcopy", (error) => (error ? reject(error) : resolve()));
    child.stdin.on("error", reject);
    child.stdin.end(text);
  });
}
