import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";

import { BarEditor } from "./editor.ts";
import { readBookmarkLabel, renderFooterLine } from "./footer.ts";
import { attachDroppedImagesOnSubmit, attachImageDrop } from "./image-drop.ts";
import { registerToolGroups } from "./tool-groups.ts";
import { drawLightTables, drawUserMessagesWithBar } from "./transcript-patches.ts";

export default function ui(pi: ExtensionAPI) {
  let activeContext: ExtensionContext | undefined;
  let bookmarkLabel: string | undefined;
  let requestRender: (() => void) | undefined;
  let refreshing = false;

  const currentTheme = (): Theme | undefined => activeContext?.ui.theme;

  drawUserMessagesWithBar(currentTheme);
  drawLightTables(currentTheme);
  registerToolGroups(pi);
  attachDroppedImagesOnSubmit(pi);

  const refreshBookmark = async () => {
    const ctx = activeContext;
    if (!ctx || refreshing) return;
    refreshing = true;
    try {
      const label = await readBookmarkLabel(ctx.cwd);
      if (ctx !== activeContext) return;
      bookmarkLabel = label;
      requestRender?.();
    } finally {
      refreshing = false;
    }
  };

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    activeContext = ctx;
    bookmarkLabel = undefined;

    ctx.ui.setEditorComponent((tui, editorTheme, keybindings) => {
      const editor = new BarEditor(tui, editorTheme, keybindings, () => ctx.ui.theme);
      attachImageDrop(editor);
      return editor;
    });

    ctx.ui.setFooter((tui, theme, footerData) => {
      requestRender = () => tui.requestRender();
      const stopWatchingBranch = footerData.onBranchChange(() => void refreshBookmark());
      return {
        dispose: stopWatchingBranch,
        invalidate() {},
        render: (width: number) => [
          renderFooterLine(pi, ctx, theme, bookmarkLabel ?? footerData.getGitBranch() ?? undefined, footerData.getExtensionStatuses().values(), width),
        ],
      };
    });

    void refreshBookmark();
  });

  const rerender = () => requestRender?.();
  pi.on("model_select", rerender);
  pi.on("thinking_level_select", rerender);
  pi.on("message_end", rerender);
  pi.on("session_compact", rerender);
  pi.on("tool_execution_end", (event) => {
    if (event.toolName === "bash") void refreshBookmark();
  });
  pi.on("agent_settled", () => void refreshBookmark());
  pi.on("user_bash", () => {
    setTimeout(() => void refreshBookmark(), 500);
  });

  pi.on("session_shutdown", (_event, ctx) => {
    if (ctx.mode === "tui") {
      ctx.ui.setFooter(undefined);
      ctx.ui.setEditorComponent(undefined);
    }
    activeContext = undefined;
    requestRender = undefined;
  });
}
