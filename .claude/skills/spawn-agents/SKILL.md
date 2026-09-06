---
name: spawn-agents
description: Spawn OpenCode agent sessions in new tmux windows with preloaded prompts. Use when James asks to open tmux tabs/windows/panes, launch or spawn agents, start OpenCode sessions with prompts, or run multiple OpenCode agents in parallel.
---

# Spawn Agents

## Overview

Launch new OpenCode TUI sessions in tmux windows, one prompt per window. Prefer creating an empty tmux window first, then sending the `opencode --prompt ...` command into that shell so the window remains open if OpenCode exits or prints an error.

For long, multiline, or heavily quoted prompts, write the prompt to a temporary file first and pass it via shell command substitution. Long inline prompts can be left half-entered in the shell or mangled by nested quoting when sent through tmux.

## Workflow

1. Confirm the current tmux context:

```sh
tmux display-message -p '#S #{session_id} #{socket_path}'
tmux list-windows
```

2. Create a new tmux window for each agent:

```sh
tmux new-window -n "window-name"
```

3. Send the OpenCode command into that window for short prompts:

```sh
tmux send-keys -t "window-name" 'opencode --prompt "the prompt text"' C-m
```

4. For long or multiline prompts, create a prompt file under the approved temp directory, send a short command that reads it, then delete the prompt file after the command has launched:

```sh
tmux new-window -n "window-name"
tmux send-keys -t "window-name" 'opencode --prompt "$(</var/folders/lv/tzzgwwhx4pn0_y2fqj9x3jp40000gn/T/opencode/window-name-prompt.txt)"' C-m
```

5. Verify the window exists and note the result to James:

```sh
tmux list-windows
```

6. Verify OpenCode actually received the prompt when using complex prompts:

```sh
tmux capture-pane -t "window-name" -p -S -20
```

If the command is sitting at the shell prompt instead of launching OpenCode, send `C-c` to the window and retry with the prompt-file command.

## Important Details

- Use `opencode --prompt "..."` for a TUI session with a preloaded prompt
- Do not use `opencode "..."` for prompts; the positional argument is interpreted as a project path
- Avoid `tmux new-window -n "name" 'opencode --prompt "..."'` unless the user wants the window to close when OpenCode exits
- Prefer one tmux window per agent unless James explicitly asks for panes
- Use short, unique window names so targets are unambiguous
- Keep prompts quoted carefully; for complex quotes, long prompts, or newlines, use a temporary prompt file instead of inline quoting
- Remove temporary prompt files after OpenCode has launched so no stale prompt artifacts are left behind

## Example

For James's request: "open a new tmux window with an OpenCode session whose prompt is `say hi`"

Run:

```sh
tmux new-window -n "say-hi"
tmux send-keys -t "say-hi" 'opencode --prompt "say hi"' C-m
tmux list-windows
```

If the wrong syntax was used and OpenCode reports `Failed to change directory`, start the correct command in the existing window:

```sh
tmux send-keys -t "say-hi" 'opencode --prompt "say hi"' C-m
```

For a longer prompt:

```sh
tmux new-window -n "issue-123"
tmux send-keys -t "issue-123" 'opencode --prompt "$(</var/folders/lv/tzzgwwhx4pn0_y2fqj9x3jp40000gn/T/opencode/issue-123-prompt.txt)"' C-m
tmux capture-pane -t "issue-123" -p -S -20
```
