# Agent commands

Resolve the requested executable and run its `--help` on the Rex server. These are launch patterns, not a promise that every installed version supports every flag. Rex's login shell may not have the same PATH as your interactive shell: use the verified absolute executable when necessary. Do not use print/exec mode when the user asked for a persistent visible worker.

The manager and worker harnesses are independent. All four can read this skill. Do not assume the manager's inherited agent environment identifies its actual foreground process.

## Pi

```sh
pi --model "$MODEL" --thinking low --name "$TASK" --session-id "$CONVERSATION_ID" -- "$PROMPT"
```

- Prompt is positional; `--` prevents a leading dash from becoming an option
- Resolve candidate provider/models with `pi --list-models <search>` and check credentials with `pi auth check --model <provider/id> --json`. These checks do not prove account access: a ChatGPT login can reject an advertised Mini, and an Anthropic login can require extra usage for a third-party app. A successful bounded model turn is the access check. Never print credentials or enable paid extra usage to get past a failure
- Small models such as an available Mini are reasonable for mechanical work. Pass `--thinking off` when the selected model has no reasoning support
- `--no-mcp` disables unrelated MCP startup for a self-contained scratch exercise, without changing saved settings. Do not remove tools that a real task needs
- Generate a stable conversation ID for `--session-id` and record it with `team.py ... conversation <task> --id <id>` before launch. Resume that exact ID/file, not `--continue` (which may select unrelated work). If using `--session-dir`, record that directory in the run brief and use it again on resume
- Current Rex reports use app `pi`. Check actual `program_status`; don't assume older versions report it
- Pi project trust and tool permissions are not the same thing. Do not add `--approve` without inspecting the project-local configuration being trusted

## Claude Code

```sh
claude --model "$MODEL" --name "$TASK" --session-id "$CONVERSATION_ID" -- "$PROMPT"
```

- Prompt is positional. Use an explicitly available cheaper model for simple work rather than inheriting Opus. Check supported aliases/version; do not assume `haiku` resolves on every account
- Current versions support `--effort low`; check help before adding it
- Generate a UUID for `--session-id` and record it with the helper's `conversation` command before launch; resume the recorded ID with `--resume <id>`
- Current Rex app is `claude-code`, while the process executable is `claude`
- A startup trust dialog may precede prompt execution. Read the actual screen. Only trust a directory the user owns or that this run created, after inspecting its local configuration. Never copy a hardcoded “down, Enter” sequence across versions
- Do not add `--dangerously-skip-permissions`, `--permission-mode bypassPermissions`, `acceptEdits`, or “always allow” to get past a blocked worker
- Claude often uses an alternate screen with no scrollback. Ask for a report on disk and inspect the diff rather than relying on captured final text
- Noninteractive `--print --max-budget-usd` is a different mode, not a budget cap for an interactive TUI

## Codex

```sh
codex --model "$MODEL" --sandbox workspace-write --ask-for-approval on-request -- "$PROMPT"
```

- Prompt is positional. `--cd <directory>` is available, but prefer Rex's `-c` so recorded cwd and actual startup agree
- Select an available small coding model explicitly; do not assume a Pi model catalog implies Codex account availability. The installed Codex model cache can describe account-visible choices (inspect model IDs/descriptions, never auth files). In the 2026-11 field test it described `gpt-6-luna` as fast and affordable; use current availability rather than pinning that name forever
- Reasoning effort is version/provider-specific. Current CLI accepts configuration overrides such as `-c 'model_reasoning_effort="low"'`; inspect help/config before using them
- Once the native conversation ID is available, record it with `team.py ... conversation <task> --id <id>`. Resume it with `codex resume <id>`, not `--last`. Do not substitute a Rex ID, title, or process PID
- Current Rex app is expected to be `codex`; verify it in the running version. If no root status exists, the helper cannot determine turn completion
- Keep approvals and sandboxing intact. No `--dangerously-bypass-approvals-and-sandbox`, bypass-hook-trust, or `--ask-for-approval never` just to make a team unattended
- Native `--worktree` is a Git workflow and is not our workspace policy. Use the `workspace` skill's independent colocated jj clones
- Put the report inside the task's writable workspace. Adding a separate report directory with `--add-dir` widens the sandbox, so only do it deliberately

## OpenCode

```sh
opencode --prompt "$PROMPT"
```

- The optional positional argument is a **directory**, not the prompt
- Inspect top-level help for model selection. Older versions accept `--model`; the installed 2026 CLI may expose it on `run` but not on the TUI
- Where a TUI has no model flag, inspect its installed config schema and use a task-local agent/config or the TUI model picker. Verify the selected model before submitting work. Do not silently launch the expensive default, change global defaults, invent a flag, or substitute `opencode run` while claiming a persistent TUI
- `opencode models` lists available IDs. Some providers expose free models; availability and reliability still need checking
- Record the actual conversation ID with the helper's `conversation` command and resume it with `--session <id>`, not `--continue`
- Current Rex app is expected to be `opencode`; inspect live reports
- Do not pass `--auto` to bypass permission prompts. Preserve configured boundaries

## Common readiness and fallback rules

Use direct CLI prompts at initial launch when possible. For later turns, `team.py send` checks the recorded pane, agent process identity, and root status before typing. It rejects control characters and flattens line breaks; send “Read /absolute/task.md” for structured instructions.

The helper recognizes only process argv0 values matching the selected CLI and root program-status records from that process. Wrappers, remote daemons, and versions without Program Status Protocol may need inspection via their native API. Do not weaken identity checks to make a harness look supported.

`idle` can mean “has not received the assignment”. A fresh `done` is a turn result, not approval of its correctness. Exited, auth-blocked, timeout, or missing status is never a verified task.

For menu interaction, read the screen, confirm current process identity, and use Rex on the recorded pane only. A blocked question may be answered within the assignment. Permission escalation, auth, or product decisions must follow the user's approval rules.
