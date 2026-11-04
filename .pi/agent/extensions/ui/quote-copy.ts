import { copyToClipboard, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { TuiAltScreen } from "@earendil-works/pi-tui";

import { patchMethod, plain } from "./patch.ts";

// Fullscreen selection copies the drawn `│ ` quote gutter with the text, and Pi has no hook for
// clicks on assistant messages. Option+click on a quote copies that quote's Markdown source instead.

const SGR_MOUSE = /^\x1b\[<(\d+);(\d+);(\d+)([Mm])$/;
const OPTION_KEY = 8;
const MOTION = 32;
const QUOTE_GUTTER = /^\s*│(?: |$)/;
const QUOTE_BLOCK = /^ {0,3}>.*(?:\n {0,3}>.*)*/gm;
const MIN_SIMILARITY = 0.8;

interface TranscriptPoint {
  row: number;
  col: number;
  scrollView?: unknown;
}

interface AltScreen {
  getPrimaryScrollView(): unknown;
  getScrollSelectionPoint(scrollView: unknown, x: number, y: number): TranscriptPoint | undefined;
  getSelectionSourceLine(point: TranscriptPoint): string;
  flash(message: string): void;
}

type ViewportInput = (this: AltScreen, data: string) => { consume?: boolean } | undefined;

const comparable = (text: string) => text.toLowerCase().replace(/[^\p{L}\p{N}]+/gu, "");

// Rendering drops Markdown syntax and, in terminals with clickable links, link URLs, so the shown
// text only approximately matches its source. Dice similarity over character pairs tolerates that.
function similarity(a: string, b: string): number {
  if (a === b) return 1;
  if (a.length < 2 || b.length < 2) return 0;
  const pairs = new Map<string, number>();
  for (let i = 0; i < a.length - 1; i++) {
    const pair = a.slice(i, i + 2);
    pairs.set(pair, (pairs.get(pair) ?? 0) + 1);
  }
  let shared = 0;
  for (let i = 0; i < b.length - 1; i++) {
    const pair = b.slice(i, i + 2);
    const count = pairs.get(pair) ?? 0;
    if (count > 0) {
      pairs.set(pair, count - 1);
      shared++;
    }
  }
  return (2 * shared) / (a.length + b.length - 2);
}

function quoteShownAt(screen: AltScreen, x: number, y: number): string | undefined {
  const point = screen.getScrollSelectionPoint(screen.getPrimaryScrollView(), x, y);
  if (!point) return undefined;
  const rowText = (row: number) => plain(screen.getSelectionSourceLine({ ...point, row }));
  const isQuoteRow = (row: number) => QUOTE_GUTTER.test(rowText(row));
  if (!isQuoteRow(point.row)) return undefined;

  let first = point.row;
  while (first > 0 && isQuoteRow(first - 1)) first--;
  let last = point.row;
  while (isQuoteRow(last + 1)) last++;

  const rows: string[] = [];
  for (let row = first; row <= last; row++) rows.push(rowText(row).replace(QUOTE_GUTTER, ""));
  return rows.join("\n");
}

function assistantQuotes(ctx: ExtensionContext): string[] {
  const quotes: string[] = [];
  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type !== "message" || entry.message.role !== "assistant") continue;
    for (const block of entry.message.content) {
      if (block.type !== "text") continue;
      for (const quote of block.text.match(QUOTE_BLOCK) ?? []) {
        quotes.push(quote.replace(/^ {0,3}> ?/gm, ""));
      }
    }
  }
  return quotes;
}

function sourceOfQuote(ctx: ExtensionContext, shownText: string): string | undefined {
  const shown = comparable(shownText);
  let best: string | undefined;
  let bestScore = MIN_SIMILARITY;
  for (const quote of assistantQuotes(ctx)) {
    const score = similarity(comparable(quote), shown);
    if (score >= bestScore) {
      best = quote;
      bestScore = score;
    }
  }
  return best;
}

export function copyQuoteOnOptionClick(context: () => ExtensionContext | undefined): void {
  const required = ["getPrimaryScrollView", "getScrollSelectionPoint", "getSelectionSourceLine", "flash"];
  if (!required.every((name) => typeof Reflect.get(TuiAltScreen.prototype, name) === "function")) return;

  let swallowNextRelease = false;
  patchMethod<ViewportInput>(TuiAltScreen.prototype, "handleViewportInput", (original) =>
    function (data) {
      const mouse = SGR_MOUSE.exec(data);
      if (!mouse) return original.call(this, data);

      const button = Number(mouse[1]);
      const released = mouse[4] === "m";
      if (released && swallowNextRelease) {
        swallowNextRelease = false;
        return { consume: true };
      }

      const isOptionClick = !released && (button & (OPTION_KEY | MOTION | 3)) === OPTION_KEY;
      const ctx = context();
      const shownText = isOptionClick && ctx ? quoteShownAt(this, Number(mouse[2]) - 1, Number(mouse[3]) - 1) : undefined;
      const source = ctx && shownText ? sourceOfQuote(ctx, shownText) : undefined;
      if (source === undefined) return original.call(this, data);

      swallowNextRelease = true;
      copyToClipboard(source).then(
        () => this.flash("Copied quote"),
        () => this.flash("Copy failed"),
      );
      return { consume: true };
    },
  );
}
