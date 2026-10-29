import { CustomEditor, type KeybindingsManager, type Theme } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, type EditorTheme, type TUI, type TuiMouseEvent } from "@earendil-works/pi-tui";

const PLACEHOLDER = "Ask anything, use / for commands";
const GUTTER = 2;
const BOTTOM_EDGE = "\u0000bottom-edge\u0000";

export class BarEditor extends CustomEditor {
  constructor(
    tui: TUI,
    editorTheme: EditorTheme,
    keybindings: KeybindingsManager,
    private readonly appTheme: () => Theme,
  ) {
    super(tui, editorTheme, keybindings, { paddingX: 0 });
  }

  protected override renderTopBorder(_width: number, hiddenLineCount: number): string {
    return hiddenLineCount > 0 ? this.appTheme().fg("dim", `  ↑ ${hiddenLineCount} more`) : "";
  }

  protected override renderBottomBorder(_width: number, hiddenLineCount: number): string {
    return `${BOTTOM_EDGE}${hiddenLineCount}`;
  }

  override render(width: number): string[] {
    if (width <= GUTTER + 1) return super.render(width);

    const lines = super.render(width - GUTTER);
    const bottom = lines.findIndex((line) => line.startsWith(BOTTOM_EDGE));
    const bar = `${this.borderColor("│")} `;
    const isEmpty = this.getText() === "";

    return lines.map((line, index) => {
      if (index === 0) return line;
      if (index === bottom) {
        const hidden = Number(line.slice(BOTTOM_EDGE.length));
        return hidden > 0 ? this.appTheme().fg("dim", `  ↓ ${hidden} more`) : "";
      }
      if (index > bottom) return `${" ".repeat(GUTTER)}${line}`;
      if (index === 1 && isEmpty) {
        return bar + truncateToWidth(`${line.trimEnd()}${this.appTheme().fg("dim", PLACEHOLDER)}`, width - GUTTER, "");
      }
      return bar + line;
    });
  }

  override handleMouse(event: TuiMouseEvent) {
    return super.handleMouse({ ...event, x: event.x - GUTTER, width: event.width - GUTTER });
  }
}
