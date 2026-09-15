# Session tools for OpenCode V2

CLI-only commands and pane status, loaded from `~/.config/opencode/cli.json`.

A Pi-style prompt footer uses the theme's info color for the shortened directory,
success color for the repository marker, syntax keyword color for the Jujutsu
change ID and current bookmarks. When the current change has no bookmark, the
same label shows the nearest ancestor bookmark and commit distance instead.
The changed-file count (`~1`) and first line of the change description use dim text.
The context percentage sits on the right. Repository fields
appear only in Jujutsu repositories. Repository status
refreshes asynchronously on terminal focus, shell completion, branch changes,
and completed agent work. Refreshes are debounced and never overlap. Reads do
not snapshot the working copy. The status clips at the right edge in narrow
terminals so the directory, change ID, file count, and description keep their order.
Context usage comes from the latest assistant response, not cumulative session
tokens. OpenCode's built-in agent/model row inside the prompt box remains; the
plugin API exposes only the footer below it.

- `/park [note]` saves a session to the parking inbox.
- `/unpark` removes the current session from the inbox.
- `/inbox` previews and opens parked sessions.
- `/btw <question>` answers a side question using the current conversation without adding it to the transcript.
- `/bg <task>` starts a separate session with the current context and tools.
- `/bg` opens background tasks and their results.

Parking saves an optional note and keeps the current session open. Sending a new
prompt automatically unparks it. The inbox shows the note and last assistant
response before opening a session.

`/btw` opens a side panel. Press `c` to copy its answer or Escape to cancel/dismiss
it. Running `/btw` without a question reopens the last answer for that session.

Background tasks run as independent root sessions in the same working directory.
They survive closing the TUI. `/bg` lets you open, stop, copy, or remove a task from
the list. **Bring result into original chat** explicitly queues its answer for the
next main-chat turn; otherwise its prompt and results stay out of that chat.

tmux uses the pane options `@opencode-status` and `@opencode-status-icon`:
`busy` (animated), `attention` (`?`), `parked` (`◌`), `idle` (`✓`), and `error` (`!`).

The plugin runs in the terminal client so each tmux pane reports its own session.

## Development

`npm ci`, then `npm run types` and `npm test`.

`python3 smoke-test.py` exercises the installed V2 TUI in a disposable tmux server.
It makes three short model requests, checks transcript isolation, and removes its
test sessions afterward. It requires macOS, tmux, Jujutsu, and an authenticated OpenCode
service.
