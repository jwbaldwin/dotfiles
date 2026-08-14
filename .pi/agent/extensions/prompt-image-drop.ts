import { readFileSync, statSync } from "node:fs";
import { readFile } from "node:fs/promises";
import type { ImageContent } from "@earendil-works/pi-ai";
import {
  CustomEditor,
  type ExtensionAPI,
  type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import type { Component, EditorTheme, TUI } from "@earendil-works/pi-tui";

const BRACKETED_PASTE = /^\x1b\[200~([\s\S]*)\x1b\[201~$/;
const IMAGE_MARKER = /\[Image #(\d+)(?:, \d+x\d+)?\]/g;
const IMAGE_MARKER_ORANGE = "\x1b[38;2;255;158;100m";

type PromptEditor = Component & {
  handleInput(data: string): void;
  getExpandedText(): string;
  insertTextAtCursor(text: string): void;
  setText(text: string): void;
};

type DroppedImage = {
  path: string;
  marker: string;
  mediaType: ImageContent["source"]["mediaType"];
};

function shellWords(text: string): string[] | undefined {
  const words: string[] = [];
  let word = "";
  let quote: "'" | '"' | undefined;
  let escaping = false;
  let started = false;

  for (const character of text.trim()) {
    if (escaping) {
      word += character;
      escaping = false;
      started = true;
      continue;
    }
    if (character === "\\" && quote !== "'") {
      escaping = true;
      started = true;
      continue;
    }
    if (quote) {
      if (character === quote) quote = undefined;
      else word += character;
      started = true;
      continue;
    }
    if (character === "'" || character === '"') {
      quote = character;
      started = true;
      continue;
    }
    // Finder escapes ASCII spaces but leaves narrow no-break spaces in screenshot names literal.
    if (/[\t\n\r ]/.test(character)) {
      if (started) {
        words.push(word);
        word = "";
        started = false;
      }
      continue;
    }
    word += character;
    started = true;
  }

  if (escaping || quote) return undefined;
  if (started) words.push(word);
  return words;
}

function imageType(bytes: Buffer): DroppedImage["mediaType"] | undefined {
  if (bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
    return "image/png";
  }
  if (bytes[0] === 0xff && bytes[1] === 0xd8) return "image/jpeg";
  if (bytes.subarray(0, 6).toString("ascii").match(/^GIF8[79]a$/)) return "image/gif";
  if (
    bytes.subarray(0, 4).toString("ascii") === "RIFF" &&
    bytes.subarray(8, 12).toString("ascii") === "WEBP"
  ) {
    return "image/webp";
  }
  return undefined;
}

function imageDimensions(bytes: Buffer, mediaType: DroppedImage["mediaType"]): string | undefined {
  if (mediaType === "image/png" && bytes.length >= 24) {
    return `${bytes.readUInt32BE(16)}x${bytes.readUInt32BE(20)}`;
  }
  if (mediaType === "image/gif" && bytes.length >= 10) {
    return `${bytes.readUInt16LE(6)}x${bytes.readUInt16LE(8)}`;
  }
  if (mediaType !== "image/jpeg") return undefined;

  let offset = 2;
  while (offset + 9 < bytes.length) {
    if (bytes[offset] !== 0xff) {
      offset += 1;
      continue;
    }
    const marker = bytes[offset + 1]!;
    if (marker === 0xd8 || marker === 0xd9) {
      offset += 2;
      continue;
    }
    const length = bytes.readUInt16BE(offset + 2);
    if (length < 2 || offset + length + 2 > bytes.length) return undefined;
    if (marker >= 0xc0 && marker <= 0xc3) {
      return `${bytes.readUInt16BE(offset + 7)}x${bytes.readUInt16BE(offset + 5)}`;
    }
    offset += length + 2;
  }
  return undefined;
}

function droppedImagePaths(data: string): string[] | undefined {
  const pasted = data.match(BRACKETED_PASTE)?.[1] ?? data;
  const paths = shellWords(pasted);
  if (!paths?.length) return undefined;

  for (const path of paths) {
    try {
      if (!statSync(path).isFile()) return undefined;
      if (!imageType(readFileSync(path).subarray(0, 32))) return undefined;
    } catch {
      return undefined;
    }
  }
  return paths;
}

export default function promptImageDrop(pi: ExtensionAPI) {
  const images = new Map<number, DroppedImage>();
  let nextImageId = 1;

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    const previousEditor = ctx.ui.getEditorComponent();
    ctx.ui.setEditorComponent((tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) => {
      const editor = (previousEditor?.(tui, theme, keybindings) ??
        new CustomEditor(tui, theme, keybindings)) as PromptEditor;
      const handleInput = editor.handleInput.bind(editor);
      const render = editor.render.bind(editor);
      const pasteStart = "\x1b[200~";
      const pasteEnd = "\x1b[201~";
      let pasteBuffer: string | undefined;

      const insertDroppedImages = (data: string, replaceEditor = false): boolean => {
        const paths = droppedImagePaths(data);
        if (!paths) return false;

        const markers: string[] = [];
        for (const path of paths) {
          const bytes = readFileSync(path);
          const mediaType = imageType(bytes)!;
          const id = nextImageId++;
          const dimensions = imageDimensions(bytes, mediaType);
          const marker = `[Image #${id}${dimensions ? `, ${dimensions}` : ""}]`;
          images.set(id, { path, marker, mediaType });
          markers.push(marker);
        }
        if (replaceEditor) editor.setText("");
        editor.insertTextAtCursor(markers.join(" "));
        return true;
      };

      editor.handleInput = (data: string) => {
        if (pasteBuffer !== undefined) {
          pasteBuffer += data;
          const end = pasteBuffer.indexOf(pasteEnd);
          if (end < 0) return;

          const pasted = pasteBuffer.slice(0, end);
          const remaining = pasteBuffer.slice(end + pasteEnd.length);
          pasteBuffer = undefined;
          if (!insertDroppedImages(pasted)) handleInput(`${pasteStart}${pasted}${pasteEnd}`);
          if (remaining) editor.handleInput(remaining);
          return;
        }

        const start = data.indexOf(pasteStart);
        if (start >= 0) {
          if (start > 0) handleInput(data.slice(0, start));
          const rest = data.slice(start + pasteStart.length);
          const end = rest.indexOf(pasteEnd);
          if (end < 0) {
            pasteBuffer = rest;
            return;
          }

          const pasted = rest.slice(0, end);
          if (!insertDroppedImages(pasted)) handleInput(`${pasteStart}${pasted}${pasteEnd}`);
          const remaining = rest.slice(end + pasteEnd.length);
          if (remaining) editor.handleInput(remaining);
          return;
        }

        if (insertDroppedImages(data)) return;
        handleInput(data);

        // Some terminals deliver a dropped path one character at a time rather than
        // as bracketed paste. Replace it as soon as the complete path exists.
        insertDroppedImages(editor.getExpandedText(), true);
      };

      editor.render = (width: number) =>
        render(width).map((line) =>
          line.replace(
            IMAGE_MARKER,
            (marker) => `${IMAGE_MARKER_ORANGE}\x1b[4m${marker}\x1b[24m\x1b[39m`,
          ),
        );

      return editor;
    });
  });

  pi.on("input", async (event) => {
    const attached: ImageContent[] = [...(event.images ?? [])];
    let foundImage = false;

    for (const match of event.text.matchAll(IMAGE_MARKER)) {
      const image = images.get(Number(match[1]));
      if (!image) continue;
      const bytes = await readFile(image.path);
      attached.push({
        type: "image",
        source: {
          type: "base64",
          mediaType: image.mediaType,
          data: bytes.toString("base64"),
        },
      });
      foundImage = true;
    }

    if (!foundImage) return { action: "continue" };
    return { action: "transform", text: event.text, images: attached };
  });
}
