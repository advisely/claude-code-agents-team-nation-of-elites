# Claude Agent SDK Alignment (v2.0.0+)

The Nation of Elites achieves **complete alignment** with Anthropic's Claude Agent SDK best practices. It tracks the current Opus model, **Claude Opus 5** (`claude-opus-5`, released 2026-07-24), for orchestration and hard reasoning, and the default workhorse, **Claude Sonnet 5** (`claude-sonnet-5`, released 2026-06-30), for everything else.

## Current Model Targets

| Alias | Resolves To | Use |
|-------|-------------|-----|
| `opus` | `claude-opus-5` | Orchestration, complex reasoning, long-horizon agentic work, agentic coding. 1M context, 128K output, $5/$25 per Mtok |
| `sonnet` | `claude-sonnet-5` | Default workhorse — tool use, framework specialists, fast read-only. 1M context, near-Opus quality at lower cost |

Agents use aliases — never hard-coded model IDs — so the harness tracks Anthropic releases automatically. The Opus 4.8 → Opus 5 move required **no frontmatter sweep**: all 25 `opus` agents inherited it on release day.

**Haiku is not used in the Nation of Elites.** There is no `haiku` tier in the roster: every agent runs on `opus` or `sonnet`. With Sonnet 5 closing most of the quality gap at a lower price, `sonnet` is the correct floor for "lightweight" work — never drop to Haiku for cost. Do not add `model: haiku` to any agent.

**Rate limits are a separate bucket.** Opus 4.8/4.7/4.6/4.5 share one combined Opus pool; Claude Opus 5 does **not** draw from it. Moving the roster to Opus 5 neither frees headroom on the old bucket nor inherits it — check tier limits before shifting heavy orchestration volume.

## ✅ Subagent Coordination
- Chief Operations Orchestrator spawns 3-5 temporary, task-specific subagents for parallel information gathering
- Isolated context windows for efficient parallel processing
- Clear lifecycle: Created → Execute → Report → Terminate
- Descriptive naming convention for clarity (e.g., `subagent-search-logs-morning`)

## ✅ Context Compaction
- Automatic summarization triggers at 80% context usage
- Information hierarchy: Critical → Important → Archivable
- Preserves API contracts, security findings, and active blockers
- Example: 170K tokens → 90K tokens (47% reduction) while maintaining quality
- **New**: Server-side context compaction API (beta) available to supplement manual compaction

## ✅ File System Context Engineering
- Comprehensive guide: `CONTEXT_ENGINEERING.md`
- Efficient large file handling with bash commands (grep, head, tail)
- Hot/warm/cold file organization strategies
- Subagent patterns for parallel file processing

## ✅ MCP Integration
- Integration Specialist (07_Orchestrators) manages Model Context Protocol servers
- Supports 15+ external services: Slack, GitHub, Google Drive, Jira, databases, cloud platforms
- OAuth flow handling and secure authentication management
- Standardized tool/resource access through MCP protocol
- **New**: MCP Connector available for direct remote MCP server connections without client implementation

## ✅ Visual Feedback Loops
- Visual Regression Specialist provides development-time feedback
- Screenshot-based validation at key development checkpoints
- Multi-viewport testing with parallel subagents
- Real-time UI validation during component creation and style changes

## ✅ Code Generation Priority
- Backend Developer emphasizes code over configuration
- Generate vs Configure philosophy for precision and reusability
- Automation as code, rules as code, infrastructure as code
- Testable, composable, infinitely reusable outputs

## ✅ Agent Teams
- Orchestrator can assemble agent teams that work in parallel and coordinate autonomously
- Flexible WIP limits for team scenarios (beyond the default 2-agent limit)
- Isolated context windows per team member with synthesized output
- **⚠️ Note (Opus 5 behavior — inverts the Opus 4.8 guidance):** Opus 4.8 *under*-reached for subagents and needed explicit "spawn N subagents" prompting. **Opus 5 delegates readily and needs a cap, not a nudge.** Delete any "delegate more" scaffolding written for 4.8 and bound the fan-out instead — see *Delegation Discipline* below. For genuinely large, decomposable tasks, **Dynamic Workflows** still applies, now defaulting to a **medium size guideline (aim for fewer than 15 agents)** in Claude Code.

## ✅ Strict Tool Use
- Tool definitions support `strict: true` for guaranteed schema conformance
- Ensures no type mismatches or missing fields in tool inputs
- Recommended for production agents where invalid tool parameters would cause failures

## ✅ Server-Side Tools
- `web_search_20260209` — web search with **dynamic filtering** (Claude filters results in-sandbox before they reach context). Supported on Opus 5 / 4.8 / 4.7 / 4.6 and Sonnet 5 / 4.6
- `web_fetch_20260209` — URL content fetching with the same dynamic filtering
- Do **not** separately declare `code_execution` alongside the `_20260209` variants — they run it under the hood, and a second execution environment confuses the model
- Older models fall back to the basic `web_search_20250305` / `web_fetch_20250910` variants
- Handle `pause_turn` for long-running server tool operations

## ✅ Claude Opus 5 Features (SDK-Level)

These apply when calling the Messages API directly (e.g. `claude-api` skill, programmatic SDK usage). The Claude Code harness handles them automatically. Opus 5 keeps Opus 4.8's request surface almost intact — **two breaking changes**, both about thinking.

### ⚠️ Breaking Change 1 — Thinking Is On by Default
A request that omits `thinking` now **thinks**. On Opus 4.8/4.7, omitting it meant no thinking.

```python
thinking = {"type": "adaptive"}          # explicit; identical to omitting it on Opus 5
output_config = {"effort": "high"}        # default; xhigh for coding/agentic
```

This is a **silent cost and truncation risk**, not just a behavior change: `max_tokens` caps thinking **plus** response text together. A call that ran thinking-off on 4.8 with a tightly-sized `max_tokens` can now truncate mid-answer. Audit every code path that never set `thinking` and either raise `max_tokens` or pass `thinking={"type":"disabled"}`.

### ⚠️ Breaking Change 2 — Disabling Thinking Is Capped at `high` Effort
`thinking={"type":"disabled"}` combined with `effort` of `xhigh` or `max` returns **HTTP 400**. It is accepted at `high` or below. Validation is **per request**, so a later call that raises effort while thinking is still disabled is rejected even if earlier calls in the same conversation succeeded.

Prefer `effort: "low"`/`"medium"` with thinking **on** over disabling it — Opus 5 performs unusually well at low effort, and disabled thinking carries two failure modes: tool calls occasionally emitted as plain text (the call silently never runs, no error) and `<thinking>` tags leaking into visible output.

### Effort Levels
Five levels: `low` / `medium` / `high` / `xhigh` / `max`; default `high`.

- **Start `xhigh` for coding and agentic work**, `high` for other intelligence-sensitive workloads
- **Then sweep downward** — `low` and `medium` punch far above their weight on Opus 5 and are the primary cost/latency lever. Effort defaults carried over from Opus 4.8 are usually not the right setting here
- At `xhigh`/`max`, set `max_tokens` ≥ 64K so the model has room to think and act across tool calls
- Reserve `max` for the hardest, latency-insensitive problems — it can over-think

### Task Budgets (Beta)
Advisory token countdown the model sees across a full agentic loop.
```python
output_config = {"effort": "xhigh", "task_budget": {"type": "tokens", "total": 128000}}
betas = ["task-budgets-2026-03-13"]
```
- Minimum 20K tokens; advisory — not a hard cap (`max_tokens` remains the ceiling)
- Use for cost-bounded long runs (pipeline skills, orchestrator loops)
- Do **not** set a task budget when quality matters more than speed

### NEW — Mid-Conversation Tool Changes (Beta)
Change a conversation's tool set between turns **without invalidating the prompt cache**. Previously `tools` was fixed for a conversation's lifetime and any edit re-billed the whole prefix.

```python
betas = ["mid-conversation-tool-changes-2026-07-01"]
# Tool must be declared up front with defer_loading, then surfaced:
{"role": "system", "content": [
    {"type": "tool_addition", "tool": {"type": "tool_reference", "name": "get_forecast"}},
]}
```
Directly relevant to the orchestrator: an agent can gain or lose capabilities mid-run (mode switch, a resource that became available, a permission to revoke) without paying a full cache rebuild.

### NEW — Automatic Refusal Fallbacks (Beta)
Opus 5 ships elevated cybersecurity safeguards; safety classifiers can decline a request with **HTTP 200** and `stop_reason: "refusal"`. **Check `stop_reason` before reading `content`** — code that indexes `content[0]` unconditionally breaks on a refusal.

```python
betas = ["server-side-fallback-2026-07-01"]
fallbacks = "default"   # routes by refusal category; cyber → Opus 4.8
```
Prefer `"default"` over pinning a model — it routes by refusal category and removes the migration you'd owe when a pinned fallback is deprecated. Benign security and life-sciences work occasionally trips the classifiers, so this matters for `cyber-sentinel` and `storage-security-specialist`.

### Lower Prompt-Cache Minimum — 512 Tokens
Halved from Opus 4.8's 1,024. Short agent system prompts that previously couldn't cache now create entries with **no code change** — worth re-checking any prompt written off as uncacheable.

### Fast Mode
`speed: "fast"` with beta `fast-mode-2026-02-01` for ~2.5× output tokens/sec at $10/$50 per Mtok. **Claude API only** (including Managed Agents) — not on Bedrock, Google Cloud, or Foundry. In Claude Code, `/fast` now applies to Opus 5 and Opus 4.8.

### Vision — Give It Tools, Not More Thinking
Stronger on chart, document, and diagram understanding and on UI/frontend visual replication. The highest-leverage change is **giving it crop/analyze/verify tools** so it can iteratively check its own output — markedly more cost-effective than raising thinking. High-resolution tier unchanged from 4.8: 2576px long edge, coordinates 1:1 with pixels. Re-validate any prompt-side workaround written for an older model's vision limits — several are now counterproductive.

### Unchanged from Opus 4.8
- **Sampling parameters removed** — `temperature`, `top_p`, `top_k` return HTTP 400 on any non-default value. Steer via prompting.
- **`budget_tokens` removed** — `thinking={"type":"enabled","budget_tokens":N}` returns HTTP 400. Use adaptive thinking + `effort`.
- **Assistant prefill removed** — last-assistant-turn prefills return HTTP 400. Use `output_config.format` (structured outputs) instead.
- **Thinking display** — `display` defaults to `"omitted"`; set `"summarized"` to stream reasoning. Raw chain of thought is never returned on Opus 5.
- **Tokenizer** — same as Opus 4.8; token counts roughly unchanged when migrating from 4.7/4.8.
- **Mid-conversation `role: "system"` messages** — no beta header; preserves prompt cache on long loops.
- **Pricing** — $5 in / $25 out per Mtok, 1M context at standard pricing, no long-context premium.

### Behavior Shifts (Steering Notes)

Opus 5 is a **drop-in upgrade at Opus 4.8's price**, but several defaults moved — and two reverse 4.8's direction outright.

| Shift | What to do |
|-------|-----------|
| **⚠️ Delegates to subagents *more* readily** (reverses 4.8) | Remove "delegate more" guidance; add an explicit cap. See *Delegation Discipline* below |
| **⚠️ Verifies its own work unprompted** (reverses "add a verification step") | **Delete** verification instructions and harness verification stages. "Double-check your answer" now causes over-*verification* with no capability gain — this inverts a standard prompting best practice |
| **Longer user-facing responses** | Add an explicit conciseness instruction. **`effort` does not reliably shorten visible output** — prompting is the lever |
| **Longer written deliverables** | Files written to disk (reports, Markdown, summaries) run long. Calibrate length explicitly for `documentation-specialist`, `book-author`, `proposal-architect` |
| **Task scope expansion** | Add a scope-discipline instruction: deliver what was asked, flag a better approach in a sentence, don't quietly widen or transform |
| **More self-correction narration** | Scope corrections to those that change the user's outcome; a follow-up question is not itself a signal of error |
| **Severity filters still depress recall** | Unchanged from 4.7/4.8: "only report high-severity" makes `code-reviewer` under-report. Report everything with confidence + severity, filter downstream |
| **Stronger agentic coding on *hard* tasks** | The gap over 4.8 is smaller on easy single-turn edits. Evaluate on the hard end: multi-file features, larger refactors, end-to-end work |
| **Real-time cybersecurity safeguards** | `cyber-sentinel` should reference the [Cyber Verification Program](https://claude.com/form/cyber-use-case) for authorized pentest work, and handle `stop_reason: "refusal"` |

### Delegation Discipline (Opus 5)

Opus 5 reaches for subagents freely, which multiplies cost and latency — each subagent re-establishes context, re-explores, reports back, and the coordinator then re-reads the report. Bound it explicitly:

- **Do** delegate genuinely independent, sizeable tracks (wide multi-file investigations, unrelated modules)
- **Do not** delegate work completable in a handful of tool calls, and **never** delegate verification — that belongs in the main agent loop
- Prefer one subagent over several; keep spawn counts low. A deterministic ceiling is the reliable lever
- Brief precisely the first time; commit to the delegation rather than re-deriving its findings
- Launch parallel agents in a **single message with multiple tool uses** so they run concurrently

### Dynamic Workflows
Claude plans a task, then spins up parallel verified subagents in a single session. As of Claude Code 2.1.219 this **defaults to a medium size guideline (fewer than 15 agents)**, configurable via the `workflowSizeGuideline` setting or *Dynamic workflow size* in `/config`. Suited to large decomposable tasks — migrations, repo-wide audits, broad refactors. Given Opus 5's delegation eagerness, the medium default is a feature, not a limit to fight.

## ✅ Claude Sonnet 5 Alignment (`sonnet` alias)

Sonnet 5 (released 2026-06-30) is the most agentic Sonnet to date and is now what the `sonnet` alias resolves to. The ~51 `sonnet` agents inherit it automatically — no frontmatter sweep needed (alias-based policy). What changed, and how to exploit it:

- **1M-token context window** — matches Opus 5. `sonnet` agents can hold a large codebase or many long documents in a single request; widen file-handling expectations accordingly (a `sonnet` framework specialist no longer needs heavy pre-chunking for big repos).
- **Near-Opus quality at lower cost** — close to the Opus tier on reasoning, tool use, coding, and knowledge work. Prefer `sonnet` as the default; reserve `opus` for orchestration, hardest reasoning, and long-horizon agentic loops. Opus 5 widens the gap on genuinely *hard* agentic coding, so the `opus` upgrade is now more clearly worth it for multi-file features and large refactors — but `sonnet` remains correct for the bulk of the roster.
- **Context awareness** — Sonnet 5 tracks its remaining context window during a run, managing long agentic loops and compaction more effectively. Complements the 80% compaction trigger in orchestration.
- **Adjustable effort levels** — same `low → medium → high → xhigh → max` scale and `high` default as Opus 5; the `effort:` frontmatter field applies identically to `sonnet` agents. Note the divergence: **Sonnet 5 runs adaptive thinking when `thinking` is omitted, same as Opus 5**, but does *not* support mid-conversation `role: "system"` messages (Opus 5 does).
- **Updated tokenizer** — ~30% more tokens for the same text vs. Sonnet 4.6; `max_tokens` / compaction-trigger widening applies to `sonnet` too.
- **Stronger safety defaults** — lower hallucination and sycophancy than its predecessor, better at refusing malicious requests and resisting prompt injection, with cyber safeguards on by default. Relevant to `cyber-sentinel`, `code-reviewer`, and any agent processing untrusted input.
- **Pricing** — introductory $2/$10 per Mtok through 2026-08-31, then standard $3/$15.

## Quality Metrics

- **74 Total Agents** - Complete coverage across all organizational functions
- **12 Strategic Divisions** - Logical grouping of related capabilities
- **Hierarchical Structure** - Clear command and coordination patterns
- **Comprehensive Coverage** - From strategy to implementation to operations
- **Automatic Documentation** - Self-maintaining project documentation and change tracking
- **Complexity-Based Reasoning** - Tailored thinking budgets aligned with Opus 5 effort levels
- **SDK Compliance Score** - 10/10 full alignment with Anthropic Claude Agent SDK best practices (Opus 5 + Sonnet 5)

## Surface Coverage

The roster ships as a plugin and runs on every surface that loads Claude Code plugins — **Claude Code (CLI, Desktop, IDE) and Claude Cowork run the full set**; plain chat runs skills, slash commands, and connectors but greys out agents and hooks.

Full matrix and Cowork-specific constraints: [orchestration.md](orchestration.md) → *Claude Cowork*.
