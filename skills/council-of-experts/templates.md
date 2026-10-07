# Council Templates

## 1. Shared Brief (`council-brief.md`)

```markdown
# Council Brief: [artifact title]

- **Date:** [YYYY-MM-DD]
- **Artifact type:** [feature spec | bug fix | architecture proposal | ...]
- **Artifact:** [path(s), PR/diff ref, or inline text below]
- **Panel:** [chair] (chair), [member], [member], ...

## Question
[The single question the council must answer.]

## Decision options
approve / approve-with-changes / reject / needs-info

## Scope
- In: [...]
- Out: [...]

## Constraints
[Deadlines, compatibility, budget, compliance, stack limits.]

## Pre-read digest (optional)
[Haiku 5.5 sweep output: paths with line ranges, call sites, current behavior, related tests/docs.]
```

## 2. Pre-Read Dispatch (optional, `model: haiku`)

Dispatch with a read-only agent type (`Explore`, or a roster agent with only Read/Grep/Glob) and per-invocation `model: haiku`.

```text
Read-only fact-gathering sweep for a council review. Today is [YYYY-MM-DD].
Read: [paths / diff]. Return a digest of at most [N] lines:
relevant file paths with line ranges, call sites, current behavior, related tests and docs.
Facts only. No judgment, no recommendations. Do not edit, create, or delete files.
```

## 3. Member Dispatch Lines

Add to every member brief, after the shared brief:

```text
You are a member of a council of experts reviewing the artifact in the brief.
Review only that artifact and the question asked. If you see an out-of-scope concern, note it in one line at the end; do not pursue it.
This is a read-only review: do not edit, create, or delete files. Report findings only.
Do not launch reviewer sub-agents or start extra review rounds on your own. If you think a deeper review is worth doing, say so at the end.
Keep working until the review is complete, and only stop to ask when you can't go on without the user.
Return findings and evidence in the member report format below. Do not include your reasoning process.
```

## 4. Member Report Format

```markdown
## [agent-id] report

| # | Severity | Ref | Finding | Evidence | Recommendation | Confidence |
|---|----------|-----|---------|----------|----------------|------------|
| 1 | Critical / High / Medium / Low | file:line or section | ... | ... | ... | high / medium / low |

**Position on the question:** [approve / approve-with-changes / reject / needs-info], one line why.
**Out of scope (optional):** [one line]
```

## 5. Cross-Critique Dispatch

```text
Council cross-critique on item [#]: [topic]. Ref: [file:line / section].
Position A ([agent-id]): [one-paragraph summary].
Position B ([agent-id]): [one-paragraph summary].
Reply with: agree with A / agree with B / refine, plus evidence (file:line or section) and a confidence.
Read-only. Answer this item only.
```

## 6. Verdict

```markdown
# Council Verdict: [artifact title]

| Field | Value |
|-------|-------|
| Decision | approve / approve-with-changes / reject / needs-info |
| Chair | [agent-id] |
| Panel | [agent-ids] |
| Rounds | independent + [critique on N items / no critique] |
| Findings | Critical [n] / High [n] / Medium [n] / Low [n] |

## Required Changes (ranked)
| # | Severity | Ref | Change | Owner role | Raised by |
|---|----------|-----|--------|------------|-----------|

## Recommended Changes (non-blocking)
- [...]

## Dissent
- [agent-id]: [position and reason, one line]

## Open Questions
- [Question, who can answer it, whether it blocks]

## Rationale
- [3-5 concise bullets: what drove the decision]
```

Decision rules: an unresolved Critical means reject or needs-info. Any High means at least approve-with-changes. Uncorroborated low-confidence findings go to Recommended.
