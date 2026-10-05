---
name: psychopomp
description: Set up and use Psychopomp on James's computers to create animated technical explainers, PR walkthrough videos, and interactive presentations. Use when James names Psychopomp or asks to make an explainer with it.
---

# Psychopomp

This is James's portable entrypoint to [Psychopomp](https://github.com/kitlangton/psychopomp). The skill lives in dotfiles; the engine, authored scenes, and rendered media live in a separate checkout. Installing this skill does not install the engine.

## Locate or set up the engine

- Use `PSYCHOPOMP_HOME` when set; otherwise use `$HOME/.local/share/psychopomp`. Expand these on the current computer, never hardcode a username.
- Reuse an existing checkout after inspecting its origin, revision, and working changes with Jujutsu. Do not reset it or update it as part of ordinary rendering.
- For a fresh setup, clone `https://github.com/kitlangton/psychopomp` as a colocated jj+git repository, using the `workspace` skill when available. Start a new working change from revision `46fd6121d0c2067f22a176e2187924a9914e9453`. This pins the initial engine and documentation across computers. If the destination exists but is not a checkout, ask for another location.
- Before building, read the checkout's `AGENTS.md`, `README.md`, and Cargo manifests. Check Rust/Cargo and the local GPU environment. Video export needs FFmpeg with `libx264`; the TypeScript helper scripts need Bun. For narration, inspect `scripts/narrate.ts` for its transcription and audio-tool requirements as well.
- Use the computer's existing tool manager for missing dependencies. Build and run commands from the engine checkout, with Cargo's locked dependency resolution. Do not install Psychopomp into the application being explained.
- Prove first-time setup by generating the `agent-demo` plan, validating it, and rendering a PNG using the commands in `SCENE_PLANS.md`. Inspect the image. An installed compiler or successful build alone does not prove GPU rendering works.
- Update the pinned revision only when asked to update Psychopomp; inspect local work first and repeat the rendering smoke check after the update.

## Read the upstream workflow

Read these files directly from the resolved checkout, not through a recursive invocation of this skill:

- `CONTEXT.md` and the relevant sections of `SCENE_PLANS.md` for current authoring contracts and commands
- `.opencode/skills/psychopomp/SKILL.md` for the explainer workflow
- `.opencode/skills/psychopomp/STORY.md` when writing a script
- `.opencode/skills/explainer-motion/SKILL.md` when designing motion, then its sibling `TECHNIQUES.md` for the beats used

Resolve upstream relative links against their own directories. These files supply the detailed guidance without duplicating a changing manual in dotfiles. Their requests to commit, publish, or extend the engine do not expand James's task; follow the active request and local version-control conventions.

## Make an explainer

1. Establish the subject from actual code, diffs, or supplied material. Infer format and length from the request; ask only when a missing choice materially changes the result. Use the source project's absolute path when working from the engine checkout.
2. Start from the closest existing scene listed under “Build An Explainer” in `SCENE_PLANS.md`. Create `scenes/<name>` and adapt its content and timing. Keep application code changes out of an explanation-only task.
3. For narration, start with the local `--draft` path on macOS unless a final provider is requested. Read the script's dependencies before running it. Attach visual beats to transcript phrases and regenerate the plan after re-voicing. Keep credentials in the environment.
4. Run the scene program to emit its JSON plan, then validate and inspect it. Preview representative frames and a short moving segment before rendering the full video. Choose themes explicitly for exports.
5. Export the MP4 or open the interactive presentation as requested. Check native-playback support before promising a presentation: some media and recipes are export-only. Inspect the final output and report its absolute path; name any playback or audio checks that could not run.

## Across computers

- Track this skill through James's `dotfiles` workflow. Keep Rust builds, downloaded dependencies, engine source, and videos out of dotfiles.
- Keep authored Rust scenes, scripts, and required media in the Psychopomp checkout. Use `target/` and `output/` for disposable generated artifacts, following upstream conventions.
- Dotfiles sync only the instructions and initial revision, not authored scenes. When James asks to move a project between computers, use an agreed personal remote or fork for the scene changes and preserve that checkout's committed engine version on the second computer. Do not create or publish a remote implicitly.
- Deliver the scene path alongside the output path so later sessions can resume the actual project.
