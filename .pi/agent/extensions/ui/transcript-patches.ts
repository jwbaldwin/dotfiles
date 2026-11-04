import { UserMessageComponent, type Theme } from "@earendil-works/pi-coding-agent";
import { Markdown } from "@earendil-works/pi-tui";

import { patchMethod, plain } from "./patch.ts";

export function drawUserMessagesWithBar(theme: () => Theme | undefined): void {
  type Render = (this: unknown, width: number) => string[];
  patchMethod<Render>(UserMessageComponent.prototype, "render", (original) =>
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
  patchMethod<RenderTable>(Markdown.prototype, "renderTable", (original) =>
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
