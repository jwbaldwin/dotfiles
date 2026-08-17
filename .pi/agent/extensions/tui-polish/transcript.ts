import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const RESPONSE_SEPARATOR = "---";
const MARKDOWN_HEADING = /^[ \t]{0,3}#{1,6}[ \t]+(.+?)(?:[ \t]+#+)?[ \t]*$/gm;
const STRONG_SUMMARY = /^[ \t]*(\*\*|__)(.+?)\1[ \t]*$/gm;

function finishThinkingTrace(markdown: string): string {
  const softened = markdown
    .replace(MARKDOWN_HEADING, "$1")
    .replace(STRONG_SUMMARY, "$2");

  if (!softened.trim()) return softened;
  return `${softened}\n\n${RESPONSE_SEPARATOR}`;
}

export function registerTranscriptPolish(pi: ExtensionAPI) {
  let previousThinking = "";
  let previousDisplay = "";

  pi.registerMarkdownTransformer((markdown, { messageType }) => {
    if (messageType !== "assistant-thinking") return markdown;
    if (markdown === previousThinking) return previousDisplay;

    previousThinking = markdown;
    previousDisplay = finishThinkingTrace(markdown);
    return previousDisplay;
  });
}
