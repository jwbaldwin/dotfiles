import { UserMessageComponent, type Theme } from "@earendil-works/pi-coding-agent";
import { Markdown } from "@earendil-works/pi-tui";

// Pi exposes no hook for how user messages and Markdown tables are drawn, so these wrap the
// renderers. Each patch checks that the method still exists; if a Pi update renames it, the
// transcript falls back to Pi's own style instead of breaking.

const ORIGINAL = Symbol.for("james.ui.original");
const ESCAPES = /\x1b\[[0-9;]*m|\x1b\][^\x07]*\x07|\x1b\][^\x1b]*\x1b\\/g;

type Method = (this: unknown, ...args: never[]) => string[];
type Patched<T extends Method> = T & { [ORIGINAL]?: T };

const plain = (line: string) => line.replace(ESCAPES, "");

function patch<T extends Method>(target: object, name: string, wrap: (original: T) => T): void {
  const current = Reflect.get(target, name) as Patched<T> | undefined;
  if (typeof current !== "function") return;
  const original = current[ORIGINAL] ?? current;
  const wrapped = wrap(original) as Patched<T>;
  wrapped[ORIGINAL] = original;
  Reflect.set(target, name, wrapped);
}

export function drawUserMessagesWithBar(theme: () => Theme | undefined): void {
  type Render = (this: unknown, width: number) => string[];
  patch<Render>(UserMessageComponent.prototype, "render", (original) =>
    function (width) {
      if (width < 4) return original.call(this, width);
      const lines = original.call(this, width - 2);
      const first = lines.findIndex((line) => plain(line).trim() !== "");
      const last = lines.findLastIndex((line) => plain(line).trim() !== "");
      const bar = theme()?.fg("text", "│") ?? "│";
      return lines.map((line, index) => (index >= first && index <= last ? `${bar} ${line}` : line));
    },
  );
}

export function drawLightTables(theme: () => Theme | undefined): void {
  type RenderTable = (this: unknown, ...args: never[]) => string[];
  patch<RenderTable>(Markdown.prototype, "renderTable", (original) =>
    function (...args) {
      const lines = original.apply(this, args);
      const dim = (text: string) => theme()?.fg("dim", text) ?? text;
      let headerRuleSeen = false;
      return lines.flatMap((line) => {
        const start = plain(line).trimStart()[0];
        if (start === "┌" || start === "└") return [];
        if (start === "├") {
          if (headerRuleSeen) return [];
          headerRuleSeen = true;
          return [dim(line)];
        }
        return [line.replaceAll("│", dim("│"))];
      });
    },
  );
}
