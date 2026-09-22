import { generateSyntax } from "@opencode/theme/tui";
import { createMemo, onCleanup, Show } from "solid-js";
import type { Context, KeymapCommand } from "@opencode/plugin/tui/context";
import { copyText } from "./clipboard.js";
import { currentSessionID, showError } from "./sessions.ts";

type SideQuestion = { sessionID: string; question: string } & (
  | { status: "running" }
  | { status: "complete"; answer: string }
  | { status: "error"; message: string }
);

export function setupBtw(context: Context) {
  const [state, update] = context.storage.memory<{ question?: SideQuestion }>("btw", {
    initial: {},
  });
  let controller: AbortController | undefined;
  const dismiss = () => {
    controller?.abort();
    controller = undefined;
    update((draft) => {
      if (draft.question?.status === "running") delete draft.question;
    });
    context.ui.panel.close();
  };
  const commands: KeymapCommand[] = [
    {
      id: "session-tools.btw",
      title: "Ask a side question",
      group: "Session tools",
      palette: true,
      slash: { name: "btw", arguments: true },
      enabled: () => Boolean(currentSessionID(context)),
      run: (input = "") => {
        const sessionID = currentSessionID(context);
        if (!sessionID) return;
        const question = input.trim();
        if (!question) {
          if (state.question?.sessionID === sessionID) context.ui.panel.open("session-tools.btw");
          else context.ui.toast.show({ message: "Usage: /btw <question>" });
          return;
        }
        controller?.abort();
        const request = new AbortController();
        controller = request;
        update((draft) => {
          draft.question = { sessionID, question, status: "running" };
        });
        context.ui.panel.open("session-tools.btw");
        void context.client.session
          .generate(
            {
              sessionID,
              prompt: `Answer this side question briefly using the current conversation.\n\n${question}`,
            },
            { signal: request.signal },
          )
          .then(({ text }) => {
            if (request.signal.aborted) return;
            update((draft) => {
              draft.question = { sessionID, question, status: "complete", answer: text };
            });
          })
          .catch((error: unknown) => {
            if (request.signal.aborted) return;
            update((draft) => {
              draft.question = {
                sessionID,
                question,
                status: "error",
                message: error instanceof Error ? error.message : String(error),
              };
            });
          });
      },
    },
  ];

  const removePanel = context.ui.slot({
    append: "session.panel",
    render: (panel) => (
      <Show
        when={panel.name === "session-tools.btw" && state.question?.sessionID === panel.sessionID}
      >
        {(() => {
          const syntaxStyle = createMemo(() => {
            const style = generateSyntax(context.theme);
            onCleanup(() => style.destroy());
            return style;
          });
          const answer = () => {
            const question = state.question;
            return question?.status === "complete" ? question.answer : undefined;
          };
          context.keymap.layer(() => ({
            commands: [
              { id: "session-tools.btw.dismiss", bind: "escape", run: dismiss },
              {
                id: "session-tools.btw.copy",
                bind: "c",
                run: async () => {
                  const question = state.question;
                  if (question?.status !== "complete") return;
                  try {
                    await copyText(question.answer);
                    context.ui.toast.show({ message: "Copied side answer." });
                  } catch (error) {
                    showError(context, error);
                  }
                },
              },
            ],
          }));
          return (
            <box width="100%" height="100%" padding={1} alignItems="center">
              <box
                width="100%"
                maxWidth={96}
                height="100%"
                flexDirection="column"
                border={["top", "bottom"]}
              borderColor={context.theme.border.base}
                title=" /btw "
                paddingX={1}
                paddingY={1}
                gap={1}
              >
                <scrollbox flexGrow={1} minHeight={0}>
                  <box flexDirection="column" gap={1}>
                    <text fg={context.theme.text.feedback.warning.base} wrapMode="word">
                      {state.question?.question}
                    </text>
                    <Show
                      when={answer()}
                      fallback={
                        <text
                          fg={
                            state.question?.status === "error"
                              ? context.theme.text.feedback.error.base
                              : context.theme.text.muted
                          }
                        >
                          {state.question?.status === "running"
                            ? "Thinking…"
                            : state.question?.status === "error"
                              ? state.question.message
                              : "No text returned."}
                        </text>
                      }
                    >
                      {(text) => (
                        <markdown
                          content={text()}
                          syntaxStyle={syntaxStyle()}
                          fg={context.theme.markdown.text}
                          conceal
                          streaming={false}
                        />
                      )}
                    </Show>
                  </box>
                </scrollbox>
                <text fg={context.theme.text.muted}>
                  {state.question?.status === "running" ? "Esc cancel" : "c copy · Esc dismiss"}
                </text>
              </box>
            </box>
          );
        })()}
      </Show>
    ),
  });
  return {
    state,
    commands,
    dispose: () => {
      controller?.abort();
      update((draft) => {
        if (draft.question?.status === "running") delete draft.question;
      });
      removePanel();
    },
  };
}
