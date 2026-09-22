# App interaction

## Discover and observe

Discover the computer-use tools exposed by the current harness. In OpenCode, use `execute` with `search({namespace: 'codex-computer-use', ...})` to retrieve exact tool signatures, then call those tools through `tools["codex-computer-use"]`.

- `list_apps` identifies available/running apps. Choose Things 3 and the available personal browser, Helium or Arc.
- `get_app_state` returns the app window, screenshot, and accessibility tree. Call it before interacting with each app in the current assistant turn, as required by the tool, and refresh after navigation or changes that invalidate element references.
- Target an explicit app in each call. Use current accessibility element indices for clicks and edits; use screenshot coordinates when the control lacks a useful accessibility target.
- Read the actual tool schema for keyboard syntax. `press_key` currently uses xdotool-style combinations, such as `super+f` for Command-F. Do not guess a long sequence of shortcuts; prefer visible controls and inspect the resulting state.
- Use `click`, `type_text`, `set_value`, `select_text`, and `scroll` as their current schemas allow. Check focus before typing, especially in task titles, notes, and browser forms.

## Things mechanics

1. Inspect the current Things window. Use its search or visible navigation to find the requested title, project, or `Agent` tag. Searching the word “Agent” is not proof that a task has the tag; inspect the tag/filter itself.
2. Open each relevant to-do to read its full notes and checklist. Scroll the list as needed; the visible viewport may not contain the entire queue.
3. Before editing, distinguish tasks with similar names using their notes and project. Use Things' Copy Link action when available to retain an exact task reference.
4. Edit the intended field. Preserve existing notes unless deliberately condensing the agent's own redundant progress text. Do not replace the entire note just to add a next step.
5. Create follow-ups through Things' visible task controls, then set the project, tags, notes, and dates. Check for duplicates before creation.
6. Move focus away or close the editor as needed to save, then inspect the task again. Confirm completion in the Logbook when necessary. A successful click alone is not evidence of a saved change.

## Browser and 1Password

Use the existing Helium or Arc session and confirm the site/account matches the task. For login, prefer the 1Password extension/autofill; use the 1Password app when needed. Ask James for unlock or authentication steps that require him, then resume from the saved state.

Observe the current page before submitting forms. After submission, read the confirmation or account history before updating Things. When waiting for James, record the page/link and exact next step, not a transcript of clicks.

If tools fail, inspect their status and the app state before retrying. Do not repeat a potentially completed external action. Report persistent access failures without claiming the task is done. Machine-specific temporary helpers from earlier sessions are not installed dependencies of this skill.
