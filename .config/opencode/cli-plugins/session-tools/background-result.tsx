import { generateSyntax } from "@opencode/theme/tui";
import type { Context } from "@opencode/plugin/tui/context";
import { createMemo, createSignal, onCleanup, Show } from "solid-js";
import type { setupBackground } from "./background.ts";
import { showError } from "./sessions.ts";

export function BackgroundResult(props: {
  context: Context;
  sessionID: string;
  background: ReturnType<typeof setupBackground>;
}) {
  const context = props.context;
  const [selectedID, select] = createSignal<string>();
  const tasks = createMemo(() =>
    Object.values(props.background.state.tasks)
      .filter(
        (task) =>
          task.originSessionID === props.sessionID && task.completion && !task.completion.dismissed,
      )
      .sort((a, b) => (a.completion?.finishedAt ?? 0) - (b.completion?.finishedAt ?? 0)),
  );
  const selected = createMemo(
    () => tasks().find((task) => task.sessionID === selectedID()) ?? tasks()[0],
  );
  const next = () => {
    const index = tasks().findIndex((task) => task.sessionID === selected()?.sessionID);
    select(tasks()[(index + 1) % tasks().length]?.sessionID);
  };
  const actions = async () => {
    const task = selected();
    if (task)
      await props.background.actions(
        task,
        task.completion?.answer,
        true,
        tasks().length > 1 ? next : undefined,
      );
  };
  const run = (action: () => Promise<void>) =>
    void action().catch((error) => showError(context, error));
  context.keymap.layer(() => ({
    mode: "global",
    commands: [
      {
        id: "session-tools.bg-result",
        title: "Background result actions",
        group: "Session tools",
        palette: true,
        slash: { name: "bg-result" },
        enabled: () => Boolean(selected()),
        run: () => run(actions),
      },
    ],
  }));
  const syntaxStyle = createMemo(() => {
    const style = generateSyntax(context.theme, context.themeMode);
    onCleanup(() => style.destroy());
    return style;
  });
  return (
    <Show when={!props.background.dialogOpen() && selected()}>
      {(task) => (
        <box
          flexDirection="column"
          border={["top", "bottom"]}
          borderColor={context.theme.border.default}
          paddingX={1}
          gap={1}
        >
          <text
            fg={
              task().completion?.outcome === "complete"
                ? context.theme.text.status.question
                : context.theme.text.feedback.error.default
            }
            wrapMode="word"
          >
            Background task {task().completion?.outcome} — {task().task}
          </text>
          <scrollbox maxHeight={10} minHeight={1}>
            <markdown
              content={task().completion?.answer ?? ""}
              syntaxStyle={syntaxStyle()}
              fg={context.theme.markdown.text}
              conceal
              streaming={false}
            />
          </scrollbox>
          <box flexDirection="row" gap={2}>
            <text fg={context.theme.text.subdued} onMouseDown={() => run(actions)}>
              Actions · /bg-result
            </text>
            <Show when={tasks().length > 1}>
              <text fg={context.theme.text.subdued} onMouseDown={next}>
                {tasks().findIndex((entry) => entry.sessionID === task().sessionID) + 1} of{" "}
                {tasks().length} · Next
              </text>
            </Show>
            <text
              fg={context.theme.text.subdued}
              onMouseDown={() => run(() => props.background.dismiss(task().sessionID))}
            >
              Dismiss
            </text>
          </box>
        </box>
      )}
    </Show>
  );
}
