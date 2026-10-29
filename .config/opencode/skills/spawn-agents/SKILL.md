---
name: spawn-agents
description: Spawn persistent coding agent sessions (pi or OpenCode) in Rex tabs with preloaded prompts. Use when James asks to launch or spawn agents, open agent tabs or panes, or run multiple agents in parallel.
---

# Spawn Agents

Open one Rex tab per agent, running an interactive agent that starts with its prompt. For anything beyond this, such as layouts, other sessions, or app control, run `rex skill show` and follow that guide.

## Pick the agent

Use the agent James names. Otherwise use `pi` when `PI_SESSION_ID` is set, and `opencode` if it isn't.

- pi takes the prompt as a positional argument: `pi "$prompt"`
- OpenCode takes it through a flag: `opencode --prompt "$prompt"`. Never pass a bare positional argument, because OpenCode treats it as a project path.

## Spawn

Give each agent a short, unique tab name. Open it in the background so James keeps his focus:

```sh
rex window new -s "$REX_SESSION" reviewer -c "$PWD" --focus=false --json -- \
  pi "Review the current diff and report actionable findings."
```

Rex passes each word after `--` to the agent as its own argument, so long, multiline, or quoted prompts need no temp file or extra escaping. Keep the prompt in one quoted shell variable or string.

Save `.block_ids[0]` from the JSON output. It identifies the agent's pane.

Use split panes only if James asks for them: `rex split -s "$REX_SESSION" -b "$REX_BLOCK" --split=right --focus=false --json -- pi "$prompt"`.

If `REX_SESSION` is unset, run `rex ls --json` and ask James which session to use.

## Verify

After a few seconds, confirm that each agent started and received its prompt:

```sh
rex capture -s "$REX_SESSION" -b "$block" --trim | tail -20
rex block call -s "$REX_SESSION" -b "$block" program_status
```

`program_status` reports the agent's state, such as `working`, `idle`, or `done`. Use it later to check whether an agent has finished. If the pane has disappeared or shows a shell prompt, read the capture before retrying.

Close only the tabs this workflow opened: `rex window close -s "$REX_SESSION" "$window_id"`.
