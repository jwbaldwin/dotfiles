---
name: explain
description: Explain a technical code change, algorithm, architecture, bug, or concept from first principles by building the concrete mechanism before introducing terminology. Use when the user explicitly asks to understand, learn, or have a technical subject explained. Do not trigger for routine answers, implementation work, summaries, reviews, or generic requests to simplify code.
---

# Explain

## Audience and Goal

Explain to an experienced software engineer who is comfortable with code, systems, databases, networking, runtimes, and computer science fundamentals, but may know essentially nothing about the specific topic.

The goal is not to simplify the topic. The goal is to make the actual mechanism understandable enough that the user can reason about it, question it, and own it.

Do not optimize for brevity on the first pass. Optimize for constructing the correct mental model. Once that model exists, the rest can become concise quickly. Complete does not mean exhaustive: omit details that do not change the user's understanding of the question.

## Primary Rule

Do not mistake naming something for explaining it.

Start from the lowest useful layer. Before introducing terminology, establish what physically or logically exists and what problem needs to be solved. Build the explanation upward from there.

Do not start with:

> Rust provides memory safety through ownership and borrowing.

Start more like:

> A running program has bytes in memory. Some of those bytes represent objects your program created. The first problem is: who is allowed to read or change those bytes, and how do we know they still exist when someone tries to use them?

Then introduce “ownership” once there is something concrete for the word to name.

## Explanation Rules

### Mechanism before terminology

Never use a technical term as its own explanation. Explain the thing first, then give it its conventional name.

Bad:

> Lean uses dependent types.

Better:

> Normally a type says something like “this value is an integer.” Lean lets the type itself contain a proposition such as “this integer is greater than zero.” A value can only have that type if you can also provide evidence that the proposition is true. That broader idea is called dependent typing.

Once a concept has been established, use its correct technical name normally. The pattern is:

```text
concrete mechanism → name the concept → use the name normally thereafter
```

### Explain what is actually happening

Explain what the computer, runtime, compiler, database, or process is literally doing, not merely the API or abstraction presented to programmers.

- For garbage collection, explain objects, references, roots, reachability, and freeing memory.
- For an LSM tree, explain the write hitting memory, becoming sorted data, being flushed to disk, and later being merged.
- For an agent protocol, explain the messages being sent, which process waits for which other process, where state lives, and what triggers the next operation.

When explaining real code, inspect the implementation instead of guessing. Cite the load-bearing files and symbols, show focused snippets only when the exact code matters, and distinguish verified behavior from inference.

### Use a tiny concrete example early

A five-line example is often better than three paragraphs of abstraction.

```text
x = allocate object A
y = x
free(x)
print(y.name)
```

First explain why `y` now refers to memory whose lifetime has ended. Only afterward generalize to the term “use-after-free.”

Use real code, values, names, messages, and paths when available. Prefer one strong example over several weak ones.

### Walk causally: A → B → C

The user should always be able to answer, “Why did the next thing happen?”

Avoid explanations shaped like:

> X has properties A, B, and C and relates to Y and Z.

Prefer:

```text
We need X because of this problem.
X does this.
That creates this new problem.
Y solves that problem.
Therefore the complete system looks like this.
```

Do not skip an obvious-looking step when it is structurally important. Subject-matter experts often jump from step 2 to step 5 because steps 3 and 4 feel obvious. Those missing steps are often exactly what the user is asking about.

If the explanation says, “The compiler sees the borrow is invalid,” immediately answer: how? What information does the compiler have, and what operation lets it reach that conclusion?

### Make state, ownership, and boundaries explicit

For each important part, explain:

- What exists?
- Where does it live?
- Who owns or may change it?
- What information is available at this point?
- What operation happens next?
- What triggers that operation?

For distributed or concurrent systems, also explain which process is running, which process is waiting, what message crosses the boundary, and where durable versus in-memory state lives.

### Distinguish compile time, runtime, and the conceptual model

Explicitly separate these layers when they could be confused.

For example:

> Nothing is checking this while the program runs. The compiler proves this before producing the executable.

Or:

> This data structure is only our mental model. Postgres does not literally store a JavaScript-style object containing these fields.

Also distinguish source code, generated artifacts, operating-system behavior, runtime bookkeeping, and hardware behavior when the distinction matters.

### Break anything that sounds magical

These phrases should trigger another layer of explanation:

- “the compiler knows”
- “the runtime handles it”
- “the framework tracks it”
- “the model learns”
- “the database optimizes it”
- “the type system proves it”
- “the agent decides”

Ask internally: How? What data exists? Where is it stored? What operation happens? What causes that operation to run?

If an invisible actor “just knows,” “just handles,” “just tracks,” or “just decides” something, the explanation probably needs to go one level deeper.

### Compare against something familiar

Use Elixir, TypeScript, JavaScript and Node, Postgres, normal HTTP servers, processes, threads, and conventional application code as reference points when useful.

For example:

> An Erlang process is not an OS process. Think of the BEAM as one OS process containing a scheduler that runs huge numbers of these much smaller process-like units.

Then explain the differences precisely. Do not let the analogy replace the mechanism, and state where the comparison stops being accurate.

### Explain boundaries and exceptions

Once the core model is established, say where that model stops being true.

For example:

> That description is accurate for stack variables, but heap allocation changes the lifetime story, so here is what happens there.

A deliberately simplified model is useful only if the user also learns its boundary. Do not let it harden into a false model.

### Rebuild the whole model

After explaining several pieces, consolidate them with “So putting this together…” and retell the mechanism from beginning to end in roughly 5–10 sentences. This is not a decorative summary; it should connect the parts into one causal sequence.

Do this when several independently explained pieces need to click together. Do not add a repetitive recap when the explanation was already short and linear.

## Visuals

Diagrams should look like systems, not presentations.

Prefer:

```text
source code
    |
    v
compiler
    |
    +--> type and lifetime checks
    |
    v
machine code
    |
    v
CPU executes it
```

Avoid abstract boxes labeled “Safety Layer,” “Ownership Paradigm,” or similar names that hide the mechanism.

Use a compact diagram, pseudocode, call tree, file tree, diff, table, or short snippet when it makes order, state, ownership, or boundaries clearer. Follow the `show-me` skill when a visual would materially improve the explanation. Place each visual beside the point it supports rather than restating the whole visual in prose.

## Choose the Shape to Fit the Subject

Do not force every explanation into the same headings. Use the smallest structure that constructs the full mental model.

Useful shapes include:

- **Code change:** previous behavior → concrete failure or limitation → new mechanism → resulting behavior → trade-offs
- **Algorithm:** concrete problem → state and invariant → step-by-step walkthrough → why each step preserves the invariant → complexity
- **Architecture:** processes and state → boundary or coordination problem → messages and operations → failure behavior → trade-offs
- **Bug:** initial state → triggering operation → incorrect transition → observed symptom → fix → remaining risk
- **Technical concept:** what existed before → problem → concrete mechanism → terminology → full walkthrough → boundaries

Reliability, maintenance, failure handling, history, alternatives, and complexity belong when they change the user's understanding of the question, not as standard sections.

## Internal Test

When the user asks “What is X?”, treat the underlying question as:

> What existed before X? What problem did that create? What does X actually consist of? What happens step-by-step when it operates? Where does the information and state live? Why does that produce the claimed behavior? How is it different from the closest thing I already understand? Where does this model stop being true?

Before finishing, silently check:

1. Did I explain the mechanism before relying on its terminology?
2. Can the user trace the important behavior causally from beginning to end?
3. Did I say what state exists, where it lives, and who acts on it?
4. Did I separate compile time, runtime, and conceptual models where needed?
5. Did I break apart every place where something appeared to “just know” or “just happen”?
6. Did I cover the main boundary or exception that would otherwise make the model false?

End when the correct mental model is complete. Do not add praise, announce the explanation plan, or repeat the same conclusion in several forms.
