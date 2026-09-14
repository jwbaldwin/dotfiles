# Slack voice evidence

Research date: September 9, 2026

This guidance is based on 144 distinct James-authored messages read in this research pass in #team-mcp-internal, dated February 4 through September 9, 2026. Seven searches returned 140 results, deduplicated to 133 messages; three thread reads added 11 more James-authored messages. Earlier drafting also used 40 overlapping search results. This is a purposive sample, not an exhaustive archive or a statistical description of all his Slack writing. Search slices included recent and older messages, review requests, linked work, and technical opinions. Thread replies from teammates provided context but were not treated as James's writing.

Authorship here means posted by James. We cannot determine which messages were drafted with an agent. Repeated patterns across dates and message types are stronger evidence than any isolated polished announcement. Existing explicit preferences in the skill remain authoritative.

## Patterns to carry into drafts

| Pattern | Evidence | Drafting implication |
| --- | --- | --- |
| Ask directly and give timing only when it matters | [February 26 review request](https://zapier.slack.com/archives/C09FNG9HMC4/p1772118562211839): “Would love a review ... when y'all get a chance”; [July 8 reviewer ping](https://zapier.slack.com/archives/C09FNG9HMC4/p1783514804330129): “mind giving this a review?” | Use a straightforward question addressed to the relevant teammate; avoid formal requests and invented urgency |
| Explain the practical thing a review unlocks | [June 24 request](https://zapier.slack.com/archives/C09FNG9HMC4/p1782347465218029) connects the review to retesting and relaunching code actions; [July 7 request](https://zapier.slack.com/archives/C09FNG9HMC4/p1783451994723119) connects it to testing and polish | Add the next useful outcome, rather than saying only that something is blocked |
| Put links next to concrete changes | [February 26 MR list](https://zapier.slack.com/archives/C09FNG9HMC4/p1772140087263329); [September 3 migration MRs](https://zapier.slack.com/archives/C09FNG9HMC4/p1788468707088269) | Label links with the ticket or recognizable work; give one concrete description per MR |
| Be candid and constructive in disagreement | [March 31 feedback](https://zapier.slack.com/archives/C09FNG9HMC4/p1775010282497229) calls out noisy output, proposes specific changes, and offers help; [May 28 suggestion](https://zapier.slack.com/archives/C09FNG9HMC4/p1779971947300409) acknowledges an idea and proposes a simpler implementation | State the actual concern and a useful next move; do not hide disagreement in generic praise |
| Expand when the reader needs the mechanism | [June 29 failure explanation](https://zapier.slack.com/archives/C09FNG9HMC4/p1782739673438129) walks through why old failures remain visible; [September 4 event-reporting update](https://zapier.slack.com/archives/C09FNG9HMC4/p1788543800202249) includes usage guidance and an anticipated objection | Length follows the decision and context; shortness is not a fixed word limit |
| Let thread replies stay small | [June 25 review thread](https://zapier.slack.com/archives/C09FNG9HMC4/p1782347465218029) contains brief acknowledgments, a situational joke, and later detailed test observations | Respond to the latest turn without restarting the explanation |
| Use humor and emoji for a reason | [February 19 review request](https://zapier.slack.com/archives/C09FNG9HMC4/p1771519643956119) uses eyes and stamp for review; [June 23 update](https://zapier.slack.com/archives/C09FNG9HMC4/p1782239858728289) thanks Dylan as “fastest reviews in the west”; [September 4 update](https://zapier.slack.com/archives/C09FNG9HMC4/p1788543800202249) anticipates a teammate's objection playfully | Warmth is part of the voice, but no fixed joke, emoji count, or signature is warranted |

## Limits and counterexamples

- The sample includes lowercase fragments, full sentences, exclamation marks, and occasional periods. Preserve the skill's preference for omitting a final period on short casual messages without stripping punctuation that aids comprehension
- Brief pings and long technical explanations both occur. Do not impose a universal two-sentence template
- Slang, swearing, typos, and repeated letters appear, but their appearance does not justify inserting them into every generated message
- Do not carry personal details from the sample into reusable writing instructions
- Do not use historical messages as evidence for the current status of an MR, deadline, or commitment
