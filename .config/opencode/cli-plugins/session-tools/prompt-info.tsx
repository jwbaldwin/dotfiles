import type { Context } from "@opencode/plugin/tui/context";
import { CliRenderEvents } from "@opentui/core";
import { createEffect, createMemo, createSignal, onCleanup, Show } from "solid-js";
import { readJujutsuStatus, type JujutsuStatus } from "./jujutsu-status.ts";

export function PromptInfo(props: { context: Context; sessionID: string }) {
  const context = props.context;
  const session = () => context.data.session.get(props.sessionID);
  const workingDirectory = createMemo(() => session()?.location.directory);
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
      if (details.type === "shell.exited" || details.type === "vcs.branch.updated") {
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
    <Show when={jujutsu()}>
      {(status) => (
        <box
          flexDirection="row"
          gap={2}
          paddingLeft={2}
          paddingRight={2}
          height={1}
          overflow="hidden"
        >
          <text flexShrink={0}>
            <span style={{ fg: context.theme.hue.green[500] }}>⌾ </span>
            <span style={{ fg: context.theme.hue.purple[500] }}>{status().changeID}</span>
          </text>
          <Show when={status().bookmark}>
            <text fg={context.theme.text.subdued} wrapMode="none" truncate flexShrink={1}>
              ← {status().bookmark}
              {status().distance ? ` ↑${status().distance}` : ""}
            </text>
          </Show>
        </box>
      )}
    </Show>
  );
}
