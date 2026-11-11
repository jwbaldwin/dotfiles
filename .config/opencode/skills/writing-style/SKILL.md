---
name: writing-style
description: Human-first writing style for comments, reviews, merge requests, commits, Slack drafts to teammates, team updates, and general engineering writing. Use when writing engineering communication that should be concise, concrete, and easy for teammates to scan quickly
---

# Human First Writing Style

Write like a teammate thinking clearly who is writing for another busy teammate who will scan the content quickly

## Voice

Stop using jargon and speak coherently. State the thing more simply and concisely, like one human talking to another

- Keep tone human, casual, and clear, like a teammate thinking out loud
- Lead with the answer, change, concern, or decision
- Use plain words and short verbs. Keep technical terms only when they are the clearest words
  - Prefer concrete words and short verbs instead of technical jargon or "spec"-like language
- Don't ever use abstract verbs (`derive`, `persist`, `facilitate`, `leverage`) when a simpler word works
- If discussing code/technical items: name the exact code, behavior, or choice and its concrete consequence
- State uncertainty only when it is real: “I think,” “am I reading this right?”, or “could this…?” Do not weaken confirmed facts with automatic hedging
- Be direct, not cold. Brief, specific praise or humor is welcome when it fits
- Write the way James types in GitLab and Slack: start short comments lowercase, use his everyday shorthand where it fits (`bc`, `imo`, `afaict`, `lg`, `pls`, `prob`, `lil`), and let an exclamation mark carry warmth ("happy with either!")
- Name things the way a teammate would say them out loud: "the delivery worker", "the event tools MR", "the connect flow". Use an MR number, ticket ID, or SHA only inside quoted agent findings or a link
- One plain sentence per idea. If a sentence needs a semicolon or a dash, make it two
- Avoid trailing periods

## Slack messages to teammates

Write as James in an ongoing conversation: direct, warm, and specific about the work. Match the audience, thread, and purpose

- **Requests:** Address the relevant teammate and ask naturally: “mind giving this a review?”, “Would love a review when you get a chance”, or “keen on your thoughts!” These are examples, not signatures. Put the link near the ask and explain what changes or what it unlocks. In an established thread, the ask and link may suffice
- **Multiple MRs:** Give each link one concrete description. Explain ordering when relevant. Use vocabulary teammates already know; omit implementation detail that doesn't help them review
- **Updates:** Say what happened, its practical consequence, and any actual next step or ask. Don't invent urgency, deadlines, promises, or completed work. Call a review quick, easy, or tiny only when its scope supports that
- **Replies:** Respond to the latest point without restarting the thread. A brief acknowledgment can stand alone; don't automatically add an offer to help
- **Discussion:** State disagreements plainly, explain the concern, and propose a change or ask a concrete question. Acknowledge useful points without obligatory praise. Keep “I think”, “IMO”, and “I wonder if” for opinions or hypotheses, not established facts
- **Detail:** Let length follow what the reader needs. Explain cause and effect, give examples, or address likely objections when useful. Use prose for a developing thought and bullets for parallel items
- **Warmth:** Use contractions, natural fragments, enthusiasm, and occasional asides. Brief openers, situational humor, and specific thanks should fit the exchange. Don't manufacture typos, slang, profanity, inside jokes, or personal history
- **Emoji:** Use emoji the way James does: for a reaction or warmth, one or two at most. In GitLab use shortcodes (`:robot:`, `:shrug:`)
- **Presentation:** Short casual messages usually start lowercase and skip the final period. Keep question marks and exclamation marks. Simple pings are just the ping

Before returning a draft, check that its relevance and any requested response are clear. Remove assistant-process narration

Use these guidelines for routine drafts. Consult [Slack drafting examples](references/slack-examples.md) for closer calibration; research further only when the audience or situation isn't covered. Learn patterns from examples without copying them mechanically

## For a Merge Request Description

Write it the way James would explain the MR to a teammate: first person, active, short paragraphs of prose. It reads like a person talking through the work, not a changelog, a spec, or a headline

### Shape

1. **What this MR does.** Open with "This MR …" plus an active verb, then the whole scope in one or two sentences. Name the feature or idea, not a slogan
   - Good: "This MR adds the core plumbing for tools with UI views: who gets to see them, and who doesn't"
   - Bad: "Only show MCP Apps UI tools to clients that can render them" (no subject, reads like a headline)
2. **How it works and where it lives.** Say where the new pieces go in the codebase and walk through the flow in plain words: what gets declared where, when it gets checked, what happens to it after
3. **Design calls.** The decisions a reviewer would ask about, each with its reason: why it's built this way, what it matches in the existing code ("same as our other gates"), what it costs
4. **User impact.** End with what changes for users or rollout, including "nothing changes until X" when that's true

A small MR can collapse this into one or two sentences. Don't pad to fill the shape

### Voice

- Use "I" for James's decisions ("I put the registry for these tools in…") and "we" for how the system behaves ("we check the client's capabilities at build time")
- Keep James's opinions and asides when he gives them, like a planned rename or a direction he wants the codebase to go. Mark them as opinion ("I think", "at some point") and keep them short
- Prefer prose paragraphs. Don't add `**How**` / `**Design**` headings, and don't turn every sentence into a bullet. Bullets only for a real list of parallel items
- Don't write it too literally or too tersely. Every sentence should carry a reason or a consequence, not just restate the diff
- Name exact code (`sdk-tools`, `initialize`, `registerAppTool`) where it helps a reviewer find things; skip line-by-line detail they can read in the diff
- Describe outcomes, not the agent's process, unless the investigation explains an important decision
- Never mention running tests, lint, or type checks. That's assumed. It's noise
- No period at the end of each paragraph's last sentence. Periods between sentences inside a paragraph are fine

### Example James approved

> This MR adds the core plumbing for tools with UI views: who gets to see them, and who doesn't. That covers tools that show a view alongside their normal result, and tools that only exist for a view to call
>
> I put the registry for these tools in the `sdk-tools` part of the code. That folder needs a rename at some point. I think the design there (a registry, building tools from it, and attaching them to a server) works well, and if we moved all future tools to that flow, not just SDK tools, I think it'd help us. Anyways, that's where new view tools go. A registry entry can now declare a `ui` view, and that view gets added to the tool when we build it and attach it to a server
>
> We check the client's capabilities at build time, same as our other gates. If the client can't render MCP Apps, it doesn't get view-only tools, and the rest come through without their view. 2026-07-28 clients send their capabilities on every request, so that's easy. 2025 clients only send them in `initialize`, so we save the answer with their client metadata and read it back on later requests. `initialize` now waits for that save so the next request can see it
>
> We also only advertise the `io.modelcontextprotocol/ui` extension when the client is actually getting a tool with a view. No tool sets `ui` yet, so nothing changes for users until the first one lands

Use it to calibrate tone and structure. Don't copy its sentences

### Evidence in requested PR/MR drafts

When James asks for a draft or authorizes one as part of opening a PR, include concise before/after evidence when it helps the reviewer understand the behavior change. Use observed results, not an invented success claim. Mention a concrete reversal constraint when code rollback alone cannot undo a data or external-system change. Omit generic risk labels, routine test-command narration, and stock verification sections. Add a visual only when it clarifies the change.

This is writing guidance, not permission to draft or publish. Preserve the delivery skill's description and posting rules, and use James's supplied wording verbatim when requested.

## Writing a commit message

 - Use a short, concrete summary; lowercase. For review follow-ups, say what changed
"fixed bulk create action to save app_auth_needs to database"
"addressed review comments"
"added regression test for the oauth token decode issue"

## Review comments on GitLab

James's review comments are short and conversational. Most are one to three sentences, often lowercase, often a question

- **Line comments:** say the thing directly. A question works well when you're not sure: "this isn't true anymore right?", "i think the endpoint is `/inputs`, or am i way off"
- **Nits:** start with `:nail_care:` and keep them to one line: ":nail_care: nothing reads the id, can drop". `:axe:` means "delete this"
- **Agent findings:** write a short intro in James's voice, then quote the findings with `>` so the author can tell which part came from an agent and point their own agent at it
  - "Agent investigated and found:"
  - "alright this is my agent's review findings but basically …"
  - "my agent found a few small things below"
  - The intro can say what the findings boil down to ("the two must fixes are both about losing track of stuff after a failure")
  - Inside the quote, precise references are fine: file:line, function names, the fix
- **Give an easy out** when the ask is optional: "happy with either!", "fine in a follow up", "you can just :x: and ship if you're fine with it"
- **Praise specifically** when it's earned, by naming what held up: "the tricky bits (the 410 delete guard, shutdown) all held up"
- **Emoji:** use GitLab shortcodes, not Unicode: `:nail_care:`, `:axe:`, `:robot:` (an agent), `:eyes:`, `:shrug:`, `:arrow_down:` (pointing at a quote), `:sweat_smile:`. One or two per comment
- **Asks:** "Can we …", "Could we …", "maybe we can …", with the concrete alternative right after

Examples from James's own comments, for calibration. Match the feel, not the words:

> :nail_care: ternary + `Promise.resolve(null)` + `.then().catch()` inside the `map` is **a lot**. Maybe refactor/extract a helper that's nicely named?

> `test-setup.ts` already clears mocks before each test, so these `mockClear()` calls can go. `app = buildApp()` could move into a `beforeEach` too!

> Agent investigated and found:
>
> > Small docs follow-up: the code-actions README says code actions always resolve and require a default connection … Can we update that paragraph in this MR?

> limit seems fine :shrug: `createMcpServerInstance` is the only place we build a server, so everything should get it. A few small things in the test file:
