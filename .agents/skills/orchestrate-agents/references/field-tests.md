# Field tests — 2026-11-01

Tested in a new disposable Rex session on macOS arm64, using Pi 1.4.0 and Codex CLI 0.164.0. Full scenarios used GPT-6.1-Sol managers and GPT-6-Luna workers, as James requested. The parent independently inspected source changes/reports and reran the acceptance checks rather than trusting manager summaries.

## Three completed scenarios

1. **Mixed-harness team and layouts.** Pi/Luna implemented a whitespace-normalizing tag function in a background tab; Codex/Luna implemented a positive-only sum in a floating layer. Independent original suites passed, three cases each, with original test hashes unchanged. Codex needed launcher recovery, so their successful coding turns did not overlap; this does not prove simultaneous execution or concurrent-write safety.
2. **Same-worker follow-up.** The manager first observed the new underscore-normalization check fail. It sent one turn-2 correction to the same Pi pane/PID with the helper, waited for a fresh completion, inspected the diff, and reran the old and new checks. The record kept the prior completion timestamp and incremented to turn 2. Immediate live status was already working; deterministic unit coverage separately forces the stale-done race.
3. **Fresh manager resume and a decision blocker.** A fresh Sol manager reused the record and both old worker IDs/turns, without resending or duplicating them. It added exactly one Luna worker as a below split (eight panes became nine). That worker reported the deliberately missing JSON/TOML decision instead of inventing it. The manager recorded blocked despite fresh program status done; the parent confirmed no configuration was created.

The helper's 18 stdlib tests cover stale/nested/foreign-process status, self-pane protection, duplicate editors, dependency gating, uncertain sends, done versus verified, conversation-ID recording/validation, and follow-up paths retained on both successful and failed sends. They do not replace the live scenarios above.

## Failures that changed the instructions

- A catalog-listed Mini and ready OpenAI credentials still failed with model_not_found under ChatGPT auth. An Anthropic third-party request required paid extra usage. Neither produced a successful turn; no paid extra usage or expensive fallback was enabled.
- A cheaper initial manager selected the first failed pane as its identity. Instructions now require matching whoami, REX_BLOCK, and the actual process, not choosing a pane by position.
- Bare codex was absent from Rex's login PATH. Its absolute mise shim then failed in the worker environment despite working in the manager. Resolving the real executable and probing it in the actual Rex cwd fixed launch without changing global config.
- Codex's hook-trust prompt initially prevented completion. The manager inspected it and continued without trusting hooks; it did not bypass approval/sandbox controls. Both Pi and Codex subsequently reported root working/done status recognized by the helper.

## Follow-ups implemented after review

- The helper records `conversation_id` separately from Rex IDs and rejects silently replacing it. Each follow-up retains its turn and absolute prompt path before delivery, including uncertain/failed sends.
- Reports and manager summaries now keep one current outcome, with old failures explicitly superseded. One earlier manager's appended note retained an obsolete blocked conclusion, even though its task record was correct.
- The report template separates product changes from report creation and names current user decisions. This addresses the blocked worker calling its changes “none” while writing a report.

A separate Luna-only live exercise recorded a preassigned Pi conversation ID, completed two turns with a blocked-to-complete report, and confirmed the native history ID and stored follow-up path matched. The parent parsed the produced JSON and checked that the current report said complete with no pending decision, while its old blocker appeared only under superseded history. After closing Pi, an explicit resume by that same ID recalled a marker from the first turn using only the write tool, without reading prompt files. Automatic process rebinding remains intentionally unsupported.

Do not add a scheduler, custom UI, memory system, or notification service for these findings. Rex already owns layouts; the skill owns assignments/review. Automatic wake-ups would need a real integration and are not claimed here.

## Limits and usage

Claude Code/OpenCode launch instructions and discovery paths were checked against installed help/upstream docs, but their model execution was not exercised under the requested Sol/Luna profile. The native Codex transcript confirmed discovery of the new skill. The tests used separate scratch directories, not real issue fetching, repository integration, production services, or shared databases.

Pi's recorded catalog-valued usage for the lab was about $0.51, not a billing claim; it excludes the native Codex worker. Luna accounted for about $0.012 of that. Failed model requests recorded zero usage. No key, billing, permission, or global model-default changes were made.

## Cleanup

Verified cleanup: closed the lab session and all nine owned panes only after every program stopped working; removed the disposable run/workspaces and all three test-specific Pi history directories; deleted the exact native Codex test conversation through its supported CLI. No lab session, scratch path, pointer file, or test transcript remains. The follow-up exercise's two owned worker panes, run-local native history, and scratch directory were also removed. Existing Rex sessions and the separate prompt/title agents were left alone. This concise note is the retained test evidence.
