import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import mcpAdapter from "../../npm/node_modules/pi-mcp-adapter/index.ts";
import { registerMcpAdapterWithToolCards } from "./mcp-tool-cards.ts";
import { registerToolCards } from "./tool-cards.ts";
import { registerTranscriptPolish } from "./transcript.ts";

export default function tuiPolish(pi: ExtensionAPI) {
  registerMcpAdapterWithToolCards(pi, mcpAdapter);
  registerToolCards(pi);
  registerTranscriptPolish(pi);
}
