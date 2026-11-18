import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// settings.json holds the personal default. Pi has no per-machine settings layer,
// so work machines (WORK=true in the untracked ~/.zshenv) switch fresh sessions here.
const WORK_PROVIDER = "vercel-ai-gateway";
const WORK_MODEL = "anthropic/claude-opus-5.5-fast";

// Pi gives extensions no way to tell a CLI-chosen model from the settings default.
const modelChosenOnCommandLine = process.argv.some((arg) => /^--models?(=|$)/.test(arg));

export default function workModel(pi: ExtensionAPI) {
  if (process.env.WORK !== "true" || modelChosenOnCommandLine) return;

  pi.on("session_start", async (_event, ctx) => {
    const isResumedSession = ctx.sessionManager.getEntries().some((entry) => entry.type === "message");
    if (isResumedSession) return;

    const model = ctx.modelRegistry.find(WORK_PROVIDER, WORK_MODEL);
    if (!model || !(await pi.setModel(model))) {
      ctx.ui.notify(`Work model ${WORK_PROVIDER}/${WORK_MODEL} is unavailable`, "warning");
    }
  });
}
