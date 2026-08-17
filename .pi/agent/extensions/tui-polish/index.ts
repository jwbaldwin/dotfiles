import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { registerToolCards } from "./tool-cards.ts";
import { registerTranscriptPolish } from "./transcript.ts";

export default function tuiPolish(pi: ExtensionAPI) {
  registerToolCards(pi);
  registerTranscriptPolish(pi);
}
