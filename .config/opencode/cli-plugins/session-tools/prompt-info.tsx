import type { Context } from "@opencode/plugin/tui/context";

import { CliRenderEvents } from "@opentui/core";
import {
  createEffect,
  createMemo,
  createSignal,
  onCleanup,
  Show,
} from "solid-js";

import { readJujutsuStatus, type JujutsuStatus } from "./jujutsu-status.ts";

export function PromptInfo(props: {
  context: Context;
  sessionID?: string;
  mode: "normal" | "shell";
}) {
  const context = props.context;
  const session = () =>
    props.sessionID ? context.data.session.get(props.sessionID) : undefined;
  const location = () =>
    session()?.location ?? context.location ?? context.data.location.default();
  const workingDirectory = createMemo(() => location().directory);
  const model = createMemo(() =>
    context.data.location.model
      .list(location())
      ?.find(
        (model) =>
          model.id === session()?.model?.id &&
          model.providerID === session()?.model?.providerID,
      ),
  );
  const directory = createMemo(() => {
    const path = context.ui.format.path(workingDirectory());
    const parts = path.split("/").filter(Boolean);
    return parts.length <= 3
      ? path
      : `${path.startsWith("~") ? "~" : "…"}/…/${parts.slice(-2).join("/")}`;
  });
  const percent = createMemo(() => {
    if (!props.sessionID) return "ctx —";
    const messages = context.data.session.message.list(props.sessionID) ?? [];
    const last = messages.findLast(
      (message) => message.type === "assistant" && message.tokens,
    );
    const limit = model()?.limit.context;
    if (last?.type !== "assistant" || !last.tokens || !limit) return "ctx —";
    const tokens = last.tokens;
    return `${Math.round(((tokens.input + tokens.output + tokens.cache.read + tokens.cache.write) / limit) * 100)}%`;
  });
  const [jujutsu, setJujutsu] = createSignal<JujutsuStatus>();

  createEffect(() => {
    const directory = workingDirectory();
    setJujutsu(undefined);
    if (!directory) return;
    const controller = new AbortController();
    let timer: ReturnType<typeof setTimeout> | undefined;
    let running = false;
    let pending = false;

    const refresh = async () => {
      if (controller.signal.aborted) return;
      if (running) {
        pending = true;
        return;
      }
      running = true;
      const status = await readJujutsuStatus(directory, controller.signal);
      if (!controller.signal.aborted) setJujutsu(status);
      running = false;
      if (pending) {
        pending = false;
        schedule();
      }
    };
    const schedule = () => {
      clearTimeout(timer);
      timer = setTimeout(() => void refresh(), 250);
    };
    const stop = context.data.listen(({ details }) => {
      if (
        details.type === "shell.exited" ||
        details.type === "vcs.branch.updated"
      ) {
        if (details.location?.directory === directory) schedule();
        return;
      }
      if (
        details.type !== "session.execution.succeeded" &&
        details.type !== "session.execution.failed" &&
        details.type !== "session.execution.interrupted"
      )
        return;
      const completed = context.data.session.get(details.data.sessionID);
      if (completed?.location.directory === directory) schedule();
    });
    context.renderer.on(CliRenderEvents.FOCUS, schedule);
    void refresh();
    onCleanup(() => {
      controller.abort();
      clearTimeout(timer);
      stop();
      context.renderer.off(CliRenderEvents.FOCUS, schedule);
    });
  });

  return (
    <box flexDirection="row" gap={2} width="100%" height={1} overflow="hidden">
      <text flexGrow={1} flexShrink={1} wrapMode="none" overflow="hidden">
        <Show when={props.mode === "shell"}>
          <span style={{ fg: context.theme.text.muted }}>! shell </span>
        </Show>
        <span style={{ fg: context.theme.text.feedback.info.base }}>
          {directory()}
        </span>
        <Show when={jujutsu()}>
          {(status) => (
            <>
              <span style={{ fg: context.theme.text.feedback.success.base }}>  </span>
              <span style={{ fg: context.theme.syntax.keyword }}>
                <b>{status().changeID}</b>
              </span>
              <Show when={status().currentBookmarks || status().bookmark}>
                <span style={{ fg: context.theme.syntax.keyword }}>
                  {status().currentBookmarks ? " " : " ← "}
                  {status().currentBookmarks || status().bookmark}
                  <Show when={!status().currentBookmarks && status().distance > 0}>
                    {` ↑${status().distance}`}
                  </Show>
                </span>
              </Show>
              <Show when={status().changedFiles > 0}>
                <span style={{ fg: context.theme.syntax.comment }}>
                  {` ~${status().changedFiles}`}
                </span>
              </Show>
              <Show when={status().description}>
                <span style={{ fg: context.theme.syntax.comment }}>
                  {` ${status().description}`}
                </span>
              </Show>
            </>
          )}
        </Show>
      </text>
      <text fg={context.theme.text.muted} flexShrink={0}>
        {percent()}
      </text>
    </box>
  );
}
