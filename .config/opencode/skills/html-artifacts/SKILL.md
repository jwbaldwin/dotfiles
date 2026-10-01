---
name: html-artifacts
description: Build standalone HTML artifacts for James (explainers, study guides, diagrams, audits, MR or plan reviews, multi-page field guides) in his house style (Inter and Berkeley Mono, one monochrome canvas, typographic hierarchy, Mermaid diagrams, no generated-design slop). Use whenever producing an HTML page or diagram for James. When visual-explainer, show-me, or plannotator-visual-explainer also apply, keep their workflows but use this skill's visual rules instead of their aesthetic menus.
---

# HTML artifacts in James's style

James reads these pages to understand and decide, often over long study sessions. Anything that is decoration rather than evidence pulls his attention. The target is Vercel-style judgment ([vercel.com/design.md](https://vercel.com/design.md)): precise hierarchy, excellent type, clear evidence, restraint. It is not decoration, and it is not a sterile black-and-white template either.

## Start from the bundled assets

Copy `assets/site.css`, `assets/site.js`, and `assets/page.html` into the artifact directory (default `~/.agent/diagrams/<topic>/`, with CSS/JS under `assets/`). Build pages from the skeleton. Do not invent a parallel theme or edit the shared CSS to restyle one page; page `<style>` blocks are for page-specific layout only.

- Single page: delete the `SITE_PAGES` script; the top bar removes itself.
- Multi-page site: set `window.SITE_TITLE` and `window.SITE_PAGES` (`[href, label]` pairs) in every page.
- `site.js` renders Mermaid with themed zoom/pan, the sticky table of contents, `.filterbar` table filters, and `.qcard` reveal-on-click quizzes.

## Visual rules

**Type.** Inter (Google Fonts, optical sizing) for all prose, headings, labels, tables, and numbers. Berkeley Mono (installed locally) only for code, identifiers, paths, wire values, and short labels such as MUST/SHOULD. Ligatures off in mono. Headings tighten tracking as they grow; body stays near 0. Body 16px, measure about 68ch, `text-wrap: pretty`. Never shrink text to fit density; rewrite or reflow.

**Canvas.** One flat background: white in light mode, near-black (#0a0a0a) in dark, neutral grays, follow `prefers-color-scheme` with no switcher. Structure comes from spacing and type. Use a hairline rule between peer blocks (`.card` renders this way), not boxes. At most one filled panel per page (`.card--hero`), for the decision or core idea.

**Color only for meaning.** Before/after (for example legacy vs new), risk, verdicts, RFC 2119 strength, our code vs a dependency. Pair color with a text cue. Never color a number because the news is good or bad, and never color a label for variety.

**Labels.** `.tag` is an inline Berkeley Mono label, never a pill. Headings are sentence case and state the claim or question.

**Diagrams.** Mermaid inside the `.diagram-shell` + `script.diagram-source` pattern (never bare `<pre class="mermaid">`). No frame around them. Decisions use hexagons `{{...}}`, not diamonds. Fills use 8-digit hex tints; never set `color:` in `classDef`. Sequence messages are plain words: no `{}`, `[]`, `<>`, `&`, `;`, `#`. Flowchart labels go in quotes with `<br/>` for breaks. Keep a diagram under about 12 nodes; split rather than cram. Never put two diagrams side by side. Every diagram gets a caption saying what to notice.

**Tables.** They sit on the canvas: a header rule plus row hairlines, baseline-aligned cells, left-aligned text, right-aligned numbers. A long audit table gets a `.filterbar`.

**Motion.** None on page load, scroll, or hover-movement. Buttons get a `scale(0.97)` press with a strong ease-out at 160ms. Only color, opacity, and transform transitions. Respect reduced motion, reduced transparency, and increased contrast.

## Reject on sight

All-caps or tracked eyebrows and kickers; numbered or `§` section labels; em dashes outside verbatim quotes; emoji; gradients, glows, glass, grid or textured backgrounds, drop shadows; colored side or top stripes; boxes around every card, metric, table, or chart; nested panels; pills or badges for metadata; repeated metric tiles where one sentence or table would do; tiny gray prose; side-by-side diagrams rendered at unreadable zoom; decorative icons; a page-load fade-up; process narration about how the page was built inside the content.

## Content

- Teach mechanism before terminology, in the style of the `explain` skill: what crosses the wire, which process acts, what state exists and where. Then name the concept.
- Plain, active, short sentences following Orwell's rules. Define a term in plain words at first use.
- Every non-obvious claim carries a source link or evidence id. Keep "unconfirmed" visible where the evidence is weak. Never pad a gap with panels.
- The first viewport carries the argument: claim plus decisive evidence, not a masthead.
- Each section answers a new question. One home per claim. End with the decision, implication, or open question, then quiet sources.

## Larger sites

For a multi-page guide, write cited research notes first under `research/` and build pages only from them, especially for topics newer than training data. When delegating pages to subagents, give each the skeleton, these rules, and its source notes. Have them write the file early and extend it in chunks, so an interruption doesn't lose everything.

## Before handing off

Run `scripts/qa.sh <site-dir>`. Every page must show zero render errors and no broken links. Read the light and dark screenshots and fix overflow, cropped or tiny diagrams, empty bands, and anything on the reject list. Check that both fonts actually resolve. Then open the entry page with `open`.
