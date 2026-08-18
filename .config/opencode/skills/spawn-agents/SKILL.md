---
name: spawn-agents
description: Spawn persistent coding agent sessions (OpenCode or pi) in Herdr tabs or tmux windows with preloaded prompts. Use when James asks to launch or spawn agents, open agent tabs/windows/panes, or run multiple agents in parallel.
---

# Spawn Agents

Launch one visible, persistent agent TUI per requested agent. Use Herdr when the current agent runs inside Herdr, tmux when it runs inside tmux, and the multiplexer James explicitly names when he asks for one.

## Choose The Agent CLI

Spawn the same harness this skill is invoked from, unless James names one explicitly:

1. If James explicitly says pi or OpenCode, use that.
2. Otherwise, if `PI_SESSION_ID` is set, you are running inside pi — spawn `pi`.
3. Otherwise spawn `opencode`.

The two CLIs take prompts differently:

- **pi**: prompt is a positional argument — `pi "Review the current diff."`
- **opencode**: prompt goes through `--prompt` — `opencode --prompt "Review the current diff."`. Never use `opencode "prompt"`; OpenCode interprets the positional argument as a project path.

Herdr's `agent start --kind` value matches the CLI name: `pi` or `opencode`.

## Choose The Backend

1. If James explicitly says Herdr, require `HERDR_ENV=1` and use Herdr.
2. If James explicitly says tmux, require `TMUX` and use tmux.
3. Otherwise use Herdr when `HERDR_ENV=1`.
4. Otherwise use tmux when `TMUX` is set.
5. If neither environment is active, ask where to launch the agents.

Prefer one Herdr tab or tmux window per agent unless James explicitly requests split panes. Use short, unique names that satisfy Herdr agent names: `[a-z][a-z0-9_-]{0,31}`.

## Herdr Workflow

Confirm the current Herdr context and resolve the caller's current workspace rather than relying on UI focus:

```sh
test "${HERDR_ENV:-}" = 1
current="$(herdr pane current --current)"
workspace_id="$(printf '%s\n' "$current" | jq -r '.result.pane.workspace_id')"
herdr tab list --workspace "$workspace_id"
```

Create a background tab in the caller's working directory and capture its root pane ID:

```sh
created="$(herdr tab create --workspace "$workspace_id" --cwd "$PWD" --label "reviewer" --no-focus)"
pane_id="$(printf '%s\n' "$created" | jq -r '.result.root_pane.pane_id')"
```

Start and name the agent in that shell pane (`--kind pi` or `--kind opencode` per the CLI choice above), then submit the work through Herdr's agent surface:

```sh
herdr agent start reviewer --kind pi --pane "$pane_id"
herdr agent prompt reviewer "Review the current diff and report actionable findings."
```

Do not add `--wait` when spawning independent background work unless James asks to wait for completion. Herdr validates that the expected agent owns the pane before accepting `agent prompt`, so do not use raw `send-keys` for normal prompts.

For a long or heavily quoted prompt, write it under the approved temporary directory, read it into one quoted argument, then remove the file after `agent prompt` succeeds:

```sh
herdr agent prompt reviewer "$(</var/folders/m8/gss9chjj74l9hwrb58cb_4j00000gp/T/opencode/reviewer-prompt.txt)"
```

Verify the named agent and tab:

```sh
herdr agent get reviewer
herdr tab list --workspace "$workspace_id"
```

If startup or prompting fails, inspect before retrying:

```sh
herdr pane process-info --pane "$pane_id"
herdr pane read "$pane_id" --source visible
```

Never close a Herdr tab or pane that this workflow did not create.

## Tmux Workflow

Confirm the current tmux context:

```sh
tmux display-message -p '#S #{session_id} #{socket_path}'
tmux list-windows
```

Create an empty window first, then launch the agent through its shell so the window remains open if the agent exits:

```sh
# pi
tmux new-window -n "reviewer"
tmux send-keys -t "reviewer" 'pi "Review the current diff."' C-m

# opencode
tmux new-window -n "reviewer"
tmux send-keys -t "reviewer" 'opencode --prompt "Review the current diff."' C-m
```

For long, multiline, or heavily quoted prompts, write the prompt under the approved temporary directory and send a short command that reads it:

```sh
tmux new-window -n "reviewer"
tmux send-keys -t "reviewer" 'pi "$(</var/folders/m8/gss9chjj74l9hwrb58cb_4j00000gp/T/opencode/reviewer-prompt.txt)"' C-m
# or: opencode --prompt "$(<...)"
```

Remove temporary prompt files after the agent has launched. Verify both the window and prompt delivery:

```sh
tmux list-windows
tmux capture-pane -t "reviewer" -p -S -20
```

If the command is sitting at a shell prompt, send `C-c` and retry with the prompt-file form.
