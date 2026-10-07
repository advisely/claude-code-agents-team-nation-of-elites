---
name: council-of-experts
description: Convene a council (panel of experts) of 3-5 roster specialists to audit, analyze and deliberate on a feature spec, bug fix, architecture proposal, security change, API contract or release plan. Independent parallel review, one cross-critique round on disputed items, then a ranked verdict. Triggers - "council of experts", "council", "panel of experts", "deliberate", "audit this spec/proposal/fix".
---

# Council of Experts

Convene a small panel of roster specialists to review one artifact. Each member reviews alone, the panel cross-critiques only what is disputed, and the main session writes the verdict. Invoke with `/council-of-experts [artifact or question]`, or say "invoke the council of experts to audit, analyze and deliberate on ...".

**This skill runs in the main session, not as an agent.** The user sees the deliberation and can steer it at each checkpoint. The main session dispatches members as parallel subagents and holds the chair role for synthesis.

**Review is read-only.** Members report findings. Nobody edits files unless the user asks to implement (see Follow-Through).

## When to Use This Skill

- A feature spec, FSD, or set of acceptance criteria before build starts
- A non-trivial bug fix or incident write-up (root cause and fix both in question)
- An architecture proposal, ADR, or migration plan
- A security-sensitive change, an API/contract change, or a data/ML change
- A release or deploy plan, a BD proposal, pricing, or a content/localization deliverable
- Any decision where the user wants more than one expert view and a recorded dissent

## When Not to Use It

- A single-file, low-risk fix: one `code-reviewer` pass is enough
- A pre-merge gate on a diff: use `/pipeline-quality`
- Pure fact-finding ("where is X used?"): a search subagent is enough
- The answer turns on one specialist's domain: delegate to that agent directly

## Panel Selection

Pick the row for the artifact type in [panels.md](panels.md): one **chair** plus 2-4 **members**, 3-5 agents in total.

- **Chair:** the most senior relevant `opus` agent. Its lens breaks ties in the verdict
- **Scribe:** `functional-analyst` whenever a spec, ACs, or traceability are in scope
- **Gates:** add `code-reviewer` when code is in scope, `cyber-sentinel` when security is
- **User override:** if the user names members, use them. Fill to 3 only if asked, and flag a missing gate role instead of adding it silently
- Mixed artifacts: take the chair from the dominant row and swap in at most two members from the other. Never exceed 5

State the panel and one line on why before dispatching. That is checkpoint 1: the user may swap members.

## Protocol

### Round 0: Brief

Write **one shared brief** to the session scratchpad (`council-brief.md`) using the template in [templates.md](templates.md). It holds the artifact (path, diff, or inline text), scope and out-of-scope, constraints, the question the council must answer, and the decision options. Every member gets the same brief.

**Optional pre-read (cost lever).** If the artifact spans many files or a large diff, first dispatch one fact-gathering sweep with a **read-only agent type** (`Explore`, or a roster agent whose tools are only Read/Grep/Glob) plus per-invocation `model: haiku` (Haiku 5.5). Never use a general-purpose agent here: a `model: haiku` override does not remove its Write/Edit tools. It reads the files and returns a digest: relevant paths with line ranges, call sites, current behavior, related tests and docs. No judgment, no recommendations. Append the digest to the brief. Skip it when the artifact is a single document.

### Round 1: Independent Review

- Dispatch every member with the brief. Members **do not see each other's output**
- Each returns findings in the member report format in [templates.md](templates.md): severity (Critical / High / Medium / Low), a `file:line` or section reference, the evidence, a recommendation, and a confidence (high / medium / low)
- **WIP cap: 2 agents in parallel** (orchestration.md default WIP limit). Batch the panel: a 5-member panel runs as 2 + 2 + 1. Launch each batch in a single message with multiple tool uses
- Do not re-derive a member's findings yourself. Commit to the delegation

After Round 1, merge findings by topic and mark each as **agreed** (two or more members, no conflict), **single** (one member), or **disputed** (members conflict on fact, severity, or fix). Show the user the merged table. That is checkpoint 2.

### Round 2: Cross-Critique (once, targeted)

- Only for **disputed** items and **Critical/High** items raised by a single member
- Send each relevant member the conflicting positions, not the full reports. Ask: agree / disagree / refine, with evidence
- Members outside an item's dispute are not re-dispatched for it
- **One critique round only.** Anything still disputed goes into the verdict as recorded dissent
- Skip Round 2 when nothing is disputed and no single-member Critical/High exists

### Round 3: Verdict

The main session, in the chair's lens, synthesizes the verdict with the template in [templates.md](templates.md):

- **Decision:** approve / approve-with-changes / reject / needs-info
- **Required changes**, ranked by severity, each with owner role and reference
- **Recommended changes** (non-blocking)
- **Dissent** recorded with member and reason. A minority view is not dropped
- **Open questions** that block or qualify the decision

Rules: any unresolved Critical is a reject or needs-info, never approve. Any High is at least approve-with-changes. Low-confidence findings with no corroboration go to recommended, not required.

## Model Guidance

- Members keep their frontmatter `model` (chairs are `opus`; most specialists are `sonnet`). Do not override a member's model upward or downward
- The only per-invocation override is the optional pre-read: `model: haiku` (Haiku 5.5) for a read-only, no-judgment sweep. Never use Haiku for a panel seat
- On third-party providers the `haiku` alias may not resolve to Haiku 5.5; pin `ANTHROPIC_DEFAULT_HAIKU_MODEL` or skip the pre-read
- **Never ask members to print their reasoning.** That can be declined as `reasoning_extraction`. Ask for findings, evidence, and a confidence

## Member Brief Lines

Include these lines in every member dispatch (full text in [templates.md](templates.md)):

1. **Scope:** review only the artifact and question in the brief. Report out-of-scope concerns in one line at the end, do not pursue them
2. **Read-only:** do not edit, create, or delete files. Report findings only
3. **No sprawl:** do not launch reviewer sub-agents or start extra review rounds on your own
4. **Keep working:** finish the review before replying. Only stop to ask when you cannot go on without the user
5. **Output:** use the member report format. Findings and evidence, not your reasoning

## Follow-Through (only if the user asks to implement)

1. Turn the ranked required changes into tasks. Map each to an implementer by stack (see `docs/rules/agent-selection.md`)
2. Give implementers **disjoint file ownership**. No two agents edit the same file. Respect the 2-agent WIP cap
3. Implementer briefs carry the scope line from orchestration.md: stop and report when done, no unrequested features, tests, files, or docs
4. Close with one `code-reviewer` pass over the combined diff (or `/pipeline-quality` for a merge gate). Verification stays in the main loop

## Checkpoints

| # | After | User may |
|---|-------|----------|
| 1 | Panel selection | Swap, add, or drop members |
| 2 | Round 1 merged findings | Drop items, force a critique on an item, stop early |
| 3 | Verdict | Accept, ask for follow-through, or reconvene with a new brief |

## Target Agents

- `chief-operations-orchestrator` - Convenes complex or multi-artifact councils
- `functional-analyst` - Scribe for spec, AC, and traceability questions
- `code-reviewer` - Gate seat when code is in scope; final pass on follow-through
- `cyber-sentinel` - Gate seat when security is in scope
- Panel members per artifact type: see [panels.md](panels.md)
