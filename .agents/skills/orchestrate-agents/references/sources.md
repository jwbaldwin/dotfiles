# Sources and maintenance

This skill replaces James's `spawn-agents` skill. It keeps the original direct-argv launch approach and background-focus default, and adds manager-owned assignments, process-aware follow-ups, review, and resume.

The user experience follows [Claude Projects](https://code.claude.com/docs/en/claude-projects): one ongoing coordinating conversation, shared project context, task threads, and an overview of work versus decisions needed. MonoCode's Mono instructions (`src/features/monos/model/monoFiles.ts`, `session_delegation_rules` and `session_completion_rules`) reinforce reusing related sessions, bounded assignments, background launch, no duplicate work by the manager, and one consolidated result. We use that small workflow, not their cloud runtime, memory system, scheduler, or notification infrastructure.

Lifecycle ideas were informed by [rex-claude](https://github.com/davila7/claude-code-templates/tree/main/cli-tool/components/skills/productivity/rex-claude): program-status waits, pre-send freshness tracking, permission boundaries, and verification outside the terminal. The Python helper is a separate implementation, not a copy of its Claude-specific shell script.

Use the installed Rex guide and API schemas as the command reference. Agent CLI examples must be checked against installed help. Related upstream skill-discovery references:

- [Pi skills](https://pi.dev/docs/skills)
- [Codex skills](https://developers.openai.com/codex/skills)
- [OpenCode skills](https://opencode.ai/docs/skills/)

The canonical installation is `~/.agents/skills/orchestrate-agents`; Claude also has a discovery symlink at `~/.claude/skills/orchestrate-agents`. There is no second copy to keep in sync. Existing running agents may retain the old skill list until reload or restart.

Run helper checks without creating bytecode in the skill directory:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s "$HOME/.agents/skills/orchestrate-agents/tests" -v
```

Unit tests cover the helper's state/ownership checks, not the actual agent TUIs, model availability, layout rendering, sandboxing, or manager judgment. Exercise those in a disposable Rex session before claiming compatibility with a new harness/version.
