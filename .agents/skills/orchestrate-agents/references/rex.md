# Rex logistics

Load the installed Rex skill (`~/.agents/skills/rex/SKILL.md`) and run `rex __internal skill`. If unavailable, use `rex whoami --json` and installed command help. The installed guide is the authority for commands and API versions; do not keep another static copy here.

## Target and ownership

- With no requested location, use the caller's `REX_SESSION` and `REX_BLOCK`, then verify they exist. A remote Rex server may use different filesystem paths from your local machine
- For a named session/pane, resolve that explicit target. For “the focused tab”, inspect the app/session focus; your inherited IDs do not necessarily identify what the user sees
- If no session is known, list sessions and ask which to use if ambiguous
- For a new team session, `rex new NAME -c "$RUN" --window Manager --json` returns its session and initial pane IDs. It does not automatically switch the user's app. Keep the original focus unless asked to switch
- Use meaningful short tab/pane labels. Distinguish the team session label, Rex window label, pane label, terminal title, and the agent's own conversation name
- Record returned IDs before any further step. Inspect the session after a creation timeout before retrying

## Layout recipes

Tabs are the default; split only when requested. Options go before `--`, and the executable/arguments go after it. `-c` sets the server-side cwd. Always keep prompt text in one quoted argument, not shell interpolation inside a generated command.

```sh
# Persistent worker in a background tab
created=$(rex window new -s "$SESSION" "$TASK" -c "$WORKSPACE" \
  --focus=false --keep-open --json -- pi --model "$MODEL" -- "$PROMPT")
WORKER=$(printf '%s' "$created" | jq -er '.block_ids[0]')

# Worker beside an explicit anchor, preserving focus
created=$(rex split -s "$SESSION" -b "$ANCHOR" --split=right --ratio 40 \
  -c "$WORKSPACE" --label "$TASK" --focus=false --keep-open --json -- \
  pi --model "$MODEL" -- "$PROMPT")
```

Substitute the correct agent launch command from `agents.md`; do not always launch Pi.

### Floats

Floats are Rex floating layers, not a special kind of agent. Discover the installed API before building arguments:

```sh
rex api describe session.new_layer --json
rex block types --json
```

The current server accepts an explicit window ID, `focus: false`, bounds as `[x, y, width, height]` fractions, and a layout containing a terminal block. Its terminal flavor is `com.superlogical.terminal.shell`; options include `cwd`, `command` (an argv array), and `exit.on_completion: false`. Verify these fields against the installed schemas.

Build JSON with a JSON encoder, not string concatenation. An example layout node is:

```json
{
  "block": {
    "flavor": "com.superlogical.terminal.shell",
    "label": "reviewer",
    "options": {
      "cwd": "/absolute/workspace",
      "command": ["pi", "--model", "provider/model", "Read /absolute/task.md"],
      "exit": {"on_completion": false}
    }
  }
}
```

Call `rex api call -s "$SESSION" session.new_layer @/absolute/arguments.json`. Save its returned block/layer IDs, bind the new worker, and inspect the session to confirm placement. Do not use `initial_input` to type arbitrary commands into an existing agent. Do not silently switch to a tab if floats are unavailable; report the limitation and ask for an alternative.

## Inspect, interact, and preserve work

```sh
rex session inspect "$SESSION" --json
rex block call -s "$SESSION" -b "$WORKER" process
rex block call -s "$SESSION" -b "$WORKER" program_status
rex capture -s "$SESSION" -b "$WORKER" --trim --unwrap | tail -40
```

Use program status for state, the screen for prompts, and reports/diffs for results. An unknown status is not idle or done. Nested status records belong to subtasks, not necessarily the root agent turn.

For user-approved menu keys, recheck the recorded worker's process and screen first, then use `rex send-key` on that exact pane. Never send keys to the manager itself, a busy editor, or an unowned pane.

Prefer `team.py send` for normal follow-up prompts. Never blindly resend after a timeout: input may already be queued. A `sending` task phase deliberately requires inspection.

Leave completed workers visible unless the user asked for cleanup. Close only this run's owned blocks, not an entire tab that may also contain user panes. Inspect uncommitted work before removing any workspace. Never terminate Rex processes or restart its shared server as agent cleanup.
