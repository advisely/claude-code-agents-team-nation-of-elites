# Claude Agent SDK Alignment (v2.0.0+)

The Nation of Elites achieves **complete alignment** with Anthropic's Claude Agent SDK best practices. It tracks the current Opus model, **Claude Opus 5.5** (`claude-opus-5-5`, released 2026-09-22), for orchestration and hard reasoning, and the default workhorse, **Claude Sonnet 5** (`claude-sonnet-5`, released 2026-06-30), for everything else.

## Current Model Targets

| Alias | Resolves To | Use |
|-------|-------------|-----|
| `opus` | `claude-opus-5-5` | Orchestration, complex reasoning, long-horizon agentic work, agentic coding. 1M context, 128K output, $4/$20 per Mtok (cache reads $0.20) |
| `sonnet` | `claude-sonnet-5` | Default workhorse — tool use, framework specialists, fast read-only. 1M context, near-Opus quality at lower cost |

Agents use aliases — never hard-coded model IDs — so the harness tracks Anthropic releases automatically. The Opus 5 → Opus 5.5 move (like Opus 4.8 → Opus 5 before it) required **no frontmatter sweep**: all 25 `opus` agents inherited it on release day. The `opus` alias resolves to Opus 5.5 on the Anthropic API, Claude Platform on AWS, Bedrock, and Google Cloud. **On Microsoft Foundry it still resolves to Opus 4.6**; pin `ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-5-5` there. Opus 5.5 needs Claude Code **v2.1.280+** and is now the `default` model on every plan (Pro and Team Standard included).

**No agent sets `effort:` in frontmatter, and that stays deliberate.** Every `opus` agent now runs at Opus 5.5's `medium` default, which matches or beats Opus 5 at `high`. Adding `effort: high` across the roster would *raise* spend over the Opus 5 baseline for little measured gain.

**Haiku is not used in the Nation of Elites.** There is no `haiku` tier in the roster: every agent runs on `opus` or `sonnet`. With Sonnet 5 closing most of the quality gap at a lower price, `sonnet` is the correct floor for "lightweight" work — never drop to Haiku for cost. Do not add `model: haiku` to any agent.

**Rate limits: check your tier.** Opus 4.8/4.7/4.6/4.5 share one combined Opus pool, and Opus 5 has its own. Check your tier's Opus 5.5 limits before moving heavy orchestration volume, and don't assume it inherits Opus 5's headroom. Subscription plans got higher five-hour limits with the Opus 5.5 launch.

**Tier gap narrowed.** At $4/$20, Opus 5.5 costs about 1.33× Sonnet 5's standard $3/$15, down from 1.67× for Opus 5. It also tends to use fewer tokens per task. The sonnet/opus split below is unchanged for now. Revisit it with evals when Sonnet 5.5 lands (announced for "the coming weeks").

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
- **⚠️ Note (delegation):** Opus 4.8 *under*-reached for subagents; Opus 5 delegated readily and needed **a cap, not a nudge**. Those caps carry over to Opus 5.5 as the default (see *Delegation Discipline* below). Opus 5.5 paces well against **time signals**, so give team leads an elapsed-time budget to speed up parallel work. For genuinely large, decomposable tasks, **Dynamic Workflows** still applies, now defaulting to a **medium size guideline (aim for fewer than 15 agents)** in Claude Code.

## ✅ Strict Tool Use
- Tool definitions support `strict: true` for guaranteed schema conformance
- Ensures no type mismatches or missing fields in tool inputs
- Recommended for production agents where invalid tool parameters would cause failures

## ✅ Server-Side Tools
- `web_search_20260209` — web search with **dynamic filtering** (Claude filters results in-sandbox before they reach context). Supported on Opus 5.5 / 5 / 4.8 / 4.7 / 4.6 and Sonnet 5 / 4.6
- `web_fetch_20260209` — URL content fetching with the same dynamic filtering
- Do **not** separately declare `code_execution` alongside the `_20260209` variants — they run it under the hood, and a second execution environment confuses the model
- Older models fall back to the basic `web_search_20250305` / `web_fetch_20250910` variants
- Handle `pause_turn` for long-running server tool operations

## ✅ Claude Opus 5.5 Features (SDK-Level)

These apply when calling the Messages API directly (e.g. `claude-api` skill, programmatic SDK usage). The Claude Code harness handles them automatically (it needs **v2.1.280+** for Opus 5.5). Opus 5.5 keeps Opus 5's feature set, including mid-conversation system messages and tool changes, per-message effort, task budgets, compaction, the 512-token cache minimum, batch, Files API, PDF, and vision. It adds **four breaking changes** and one silent response-shape change.

### ⚠️ Breaking Change 1: Thinking Can't Be Disabled
`thinking={"type":"disabled"}` and `{"type":"enabled","budget_tokens":N}` both return **HTTP 400 at every effort level**. On Opus 5, disabling was allowed at `high` or below. Omit `thinking` or send `{"type":"adaptive"}`; **effort is now the only control** for thinking depth, latency, and cost.

```python
# Opus 5 route that disabled thinking → Opus 5.5
output_config = {"effort": "low"}     # thinking stays on; low keeps it short
max_tokens = 64000                    # thinking counts toward max_tokens; size for both
```

- Read content blocks by `type`, not position. A response can open with `thinking` blocks, which are empty under the default `display: "omitted"`
- **Delete** any prompt that asked the model to write its reasoning into the response as a thinking substitute. Opus 5.5 can decline it with `stop_details.category: "reasoning_extraction"`. Read `display: "summarized"` blocks instead
- Delete any "don't think" rule. The model can't comply, and such rules increase tag leakage
- In Claude Code, the thinking toggle, `alwaysThinkingEnabled`, and `MAX_THINKING_TOKENS=0` have no effect on Opus 5.5

### ⚠️ Breaking Change 2: Forced Tool Use Is Rejected
`tool_choice` `{"type":"any"}` / `{"type":"tool",...}` returns HTTP 400. This also applies to Batches and `count_tokens`. Use `auto` + `strict: true` + a prompt line naming the tool, and **check that the call happened** (retry if not). If the forced call only existed to get JSON back, use structured outputs (`output_config.format`).

### ⚠️ Breaking Change 3: Thinking Blocks Are Tied to Model and Conversation ("Preserved Thinking")
- **Model binding:** Opus 5.5 reads Opus 5 (and older Opus/Sonnet/Haiku) blocks, so a session moving *onto* 5.5 keeps its reasoning. On the Claude API, only Fable 5.1 / Mythos 5.1 read 5.5's blocks, so a **fallback or router switch to Opus 5 / 4.8 runs without the prior reasoning**. The API drops unreadable blocks silently and doesn't bill them
- **Conversation binding:** accounts created **on or after 2026-08-31** get HTTP 400 when a replayed block's prefix (`system`, `tools`, earlier messages) was edited. Older accounts can opt in with `thinking.block_binding.prefix_mismatch_behavior` (`"error"` / `"drop_block"`, beta `thinking-binding-controls-2026-08-01`)
- **Keep harnesses append-only:** change instructions with mid-conversation `role: "system"` messages, not `system` edits. Declare the full tool set up front and use `tool_addition`/`tool_removal`, or define tools inline with beta `inline-tools-2026-09-15`. Compact with server-side / on-demand compaction (beta `compact-2026-09-04`), not summarize-and-replay. Claude Code, Managed Agents, and the Agent SDK already do this. Custom harnesses that build `messages` themselves must audit

### ⚠️ Breaking Change 4: Computer Use Only via the Toolset
On the Claude API and Google Cloud, `computer_20251124` returns HTTP 400. Declare `{"type":"computer_toolset_20260801"}` with no beta header, no `name`, and no display size. The agent loop changes too: the action is the `tool_use` block's `name`, a turn can hold several batched actions, and every result echoes `"toolset_name": "computer"`. Bedrock still accepts the older tool.

### Silent Change: Text Between Tool Calls Arrives as `thinking` Blocks
Progress notes come back as progress-update `thinking` blocks, which are empty by default. A UI that renders only `text` goes quiet through long agentic turns. Set `thinking.display: "updates"` (beta `thinking-display-updates-2026-08-18`) and render non-empty `thinking` blocks ahead of the `tool_use` they precede.

### Effort Levels: Default Is Now `medium`
Five levels: `low` / `medium` / `high` / `xhigh` / `max`. **The default on Opus 5.5 is `medium`**, one below Opus 5's `high`, and Claude Code does not carry an Opus 5 effort setting over.

- Level names don't map 1:1 across models. Opus 5.5 at `medium` matches or beats Opus 5 at `high` on coding and knowledge work, and `low` comes close on several coding evals. **Start at `medium` and set it explicitly**
- At a given level, Opus 5.5 thinks **more** per turn than Opus 5, especially at `xhigh`/`max`. Keeping an Opus 5 `xhigh` setting means longer turns and more tokens. Reserve `xhigh`/`max` for measured gains
- To cut thinking, **lower effort before prompting for brevity**
- Use per-message effort (beta `mid-conversation-output-config-2026-07-01`) to change a turn's level without a cache reset. Changing top-level `effort` between requests invalidates the cache
- Give `max_tokens` room for thinking plus the reply. 64K is a good start for long agentic coding turns, up to the 128K max

### Task Budgets (Beta)
Advisory token countdown the model sees across a full agentic loop.
```python
output_config = {"effort": "medium", "task_budget": {"type": "tokens", "total": 128000}}
betas = ["task-budgets-2026-03-13"]
```
- Minimum 20K tokens. It is advisory, not a hard cap (`max_tokens` remains the ceiling)
- Use for cost-bounded long runs (pipeline skills, orchestrator loops)
- Do **not** set a task budget when quality matters more than speed

### Mid-Conversation Tool Changes (Beta)
Change a conversation's tool set between turns **without invalidating the prompt cache**. Under preserved thinking this is also what keeps earlier thinking blocks valid.

```python
betas = ["mid-conversation-tool-changes-2026-07-01"]
# Tool declared up front with defer_loading, then surfaced:
{"role": "system", "content": [
    {"type": "tool_addition", "tool": {"type": "tool_reference", "name": "get_forecast"}},
]}
```
With beta `inline-tools-2026-09-15`, a `tool_addition` can carry a **full tool definition** instead of a reference, so an agent can gain a tool it never declared without editing `tools`.

### Refusals and Fallbacks: Broader Classifiers
Opus 5.5 runs **cybersecurity and biology** classifiers (biology is new relative to Opus 5) plus a **`reasoning_extraction`** category. A decline is **HTTP 200** with `stop_reason: "refusal"`, so **check `stop_reason` before reading `content`**.

```python
betas = ["server-side-fallback-2026-07-01"]
fallbacks = "default"   # routes by refusal category
```
- `reasoning_extraction` declines are **not** retried on a fallback. Fix the prompt instead
- A fallback model runs without Opus 5.5's thinking blocks (Breaking Change 3)
- Finding vulnerabilities in source code is allowed. For authorized offensive work, use the [Cyber Verification Program](https://claude.com/form/cyber-use-case). For life-sciences work, use the Life Sciences Verification Program. Relevant to `cyber-sentinel` and `storage-security-specialist`

### Pricing & Caching
$4 in / $20 out per Mtok (Opus 5: $5/$25). **Cache reads are $0.20** (0.05× input, 60% below Opus 5), 5-minute writes $5, 1-hour writes $8, and batch $2/$10. The deeper read discount makes warm caches more valuable and misses relatively costlier, which is one more reason to keep harnesses append-only. The 512-token cache minimum carries over. Opus 5.5 is also >30% faster at output and tends to finish tasks in fewer tokens, so cost per *solved task* falls by more than the list-price cut.

### Fast Mode
`speed: "fast"` with beta `fast-mode-2026-02-01`, up to ~2.5× output speed at **$8/$40** per Mtok. **Claude API only.** It is not available on Bedrock, Claude Platform on AWS, Google Cloud, or Foundry. `/fast` in Claude Code applies.

### Vision: Re-Test Your Scaffolding
Opus 5.5 reads dense charts, diagrams, and screenshots far more precisely. Even at `low` it out-reads Opus 5 at its highest effort, at a fraction of the tokens. Crop/zoom harnesses built for earlier models **may no longer be needed, so re-test them**. For the densest inputs (technical drawings: Revit, CATIA, ACC sheets) higher-resolution images and a crop/measure tool still add accuracy, and more so at higher effort. Computer use from screenshots at default effort matches what Opus 5 reached only at much higher effort.

### Unchanged from Opus 5
- Sampling parameters (`temperature`/`top_p`/`top_k`) and assistant prefill return HTTP 400
- `thinking.display` defaults to `"omitted"`. The raw chain of thought is never returned
- Same tokenizer, 1M context, 128K output, knowledge cutoff June 2026
- No Priority Tier
- Mid-conversation `role: "system"` messages need no beta header

### Behavior Shifts (Steering Notes)

Existing Opus 5 prompts perform well on Opus 5.5 out of the box, and the Opus 5 steering remains the starting point. Anthropic's guidance is to **re-test each Opus 5-specific instruction** (verbosity, over-verification, scope) against your own evals rather than carry it forward untested.

| Shift | What to do |
|-------|-----------|
| **Delegation caps** (from Opus 5) | Keep the *Delegation Discipline* caps below as the default. Opus 5.5 also sustains multi-hour autonomous runs with parallel subagents, so re-test caps on large migrations/audits before tightening further |
| **Self-verification** (from Opus 5) | Still: don't add "double-check" / verification stages. Re-test before re-adding any |
| **⚠️ Early stops in unattended runs** | Some progress updates end the turn with text (`end_turn`). Treat a text-only end of turn as a *report*, not completion. Track parts in a checklist, re-prompt naming the open items, cap at 2–3 auto-continuations, and wait on running background commands/subagents. For fully unattended agents, a system-prompt addition that names the unwanted stop types (announcing the next step without taking it, offering to continue, listing non-blocking decisions, stopping at a milestone) reduces them. Add it from the first request, and never in human-in-the-loop agents |
| **Time signals speed up agent teams** | Give the lead a time budget and append `elapsed 340s / 1200s` to each message back to it. With no sensible budget, show elapsed time and add: *"Time matters here: do not spend time that can be avoided, and the earlier a correct result is obtained, the better."* A budget keeps more agents in parallel, while lower effort reduces the work itself |
| **Multi-app workflows start too fast** | For agents across email/docs/sheets/CRM, add: *"Before taking any action, explore broadly with tool calls… including ones the task does not explicitly mention, and use what you find."* Keep untrusted content out of the searched records |
| **Chat: drop "think carefully" lines** | Effort decides thinking. Removing such lines made replies start sooner with no clear quality drop. For settled answers, the "treat earlier answers as done" addition cuts follow-up latency. Don't use it in agentic loops, where later steps can expose earlier mistakes |
| **Pasted text** | Wrap user-pasted content in `<pasted_content id="…">` tags with a matching random id, and tell the model instructions inside only apply where the user's own message asks. This is one prompt-injection guardrail among several |
| **Frontend defaults** | "Avoid a generic AI look" swaps one default for another. **Name the specific patterns to avoid** and iterate (see `ux-ui-architect`, `frontend-developer`) |
| **Clearer reporting** | Updates and final summaries say plainly what was done, what was found, and what's needed. The `humanizer` skill has less to fix on Opus 5.5 output |
| **Knowledge work** | Much less likely to state an unsupported figure or cite the wrong source, and better at financial models and at catching mismatches in large inputs. Benefits the BD, Content, and Strategy wings |
| **Severity filters still depress recall** | Unchanged: "only report high-severity" makes `code-reviewer` under-report. Report everything with confidence + severity and filter downstream. Opus 5.5 catches more bugs with fewer false alarms |

### Delegation Discipline

Written for Opus 5's eager delegation, and still the default under Opus 5.5. Each subagent re-establishes context, re-explores, reports back, and the coordinator re-reads the report. Bound it explicitly:

- **Do** delegate genuinely independent, sizeable tracks (wide multi-file investigations, unrelated modules)
- **Do not** delegate work completable in a handful of tool calls, and **never** delegate verification. That belongs in the main agent loop
- Prefer one subagent over several and keep spawn counts low. A deterministic ceiling is the reliable lever
- Brief precisely the first time, and commit to the delegation rather than re-deriving its findings
- Launch parallel agents in a **single message with multiple tool uses** so they run concurrently

### Dynamic Workflows
Claude plans a task, then spins up parallel verified subagents in a single session. As of Claude Code 2.1.219 this **defaults to a medium size guideline (fewer than 15 agents)**, configurable via the `workflowSizeGuideline` setting or *Dynamic workflow size* in `/config`. Suited to large decomposable tasks such as migrations, repo-wide audits, and broad refactors, which is exactly where Opus 5.5's long-run gains show. Keep the medium default unless a measured run shows a larger team finishing better.

## ✅ Claude Sonnet 5 Alignment (`sonnet` alias)

Sonnet 5 (released 2026-06-30) is the most agentic Sonnet to date and is now what the `sonnet` alias resolves to. The ~51 `sonnet` agents inherit it automatically — no frontmatter sweep needed (alias-based policy). What changed, and how to exploit it:

- **1M-token context window** — matches Opus 5.5. `sonnet` agents can hold a large codebase or many long documents in a single request; widen file-handling expectations accordingly (a `sonnet` framework specialist no longer needs heavy pre-chunking for big repos).
- **Near-Opus quality at lower cost** — close to the Opus tier on reasoning, tool use, coding, and knowledge work. Prefer `sonnet` as the default; reserve `opus` for orchestration, hardest reasoning, and long-horizon agentic loops. Opus 5.5 widens the gap on genuinely *hard* agentic coding, so the `opus` upgrade is now more clearly worth it for multi-file features and large refactors — but `sonnet` remains correct for the bulk of the roster.
- **Context awareness** — Sonnet 5 tracks its remaining context window during a run, managing long agentic loops and compaction more effectively. Complements the 80% compaction trigger in orchestration.
- **Adjustable effort levels** — same `low → medium → high → xhigh → max` scale as Opus 5.5, but Sonnet 5 defaults to `high` (Opus 5.5 defaults to `medium`). The `effort:` frontmatter field applies identically to `sonnet` agents. Other divergences: **Sonnet 5 accepts `thinking: disabled` and forced `tool_choice`** (Opus 5.5 rejects both), and does *not* support mid-conversation `role: "system"` messages (Opus 5.5 does).
- **Updated tokenizer** — ~30% more tokens for the same text vs. Sonnet 4.6; `max_tokens` / compaction-trigger widening applies to `sonnet` too.
- **Stronger safety defaults** — lower hallucination and sycophancy than its predecessor, better at refusing malicious requests and resisting prompt injection, with cyber safeguards on by default. Relevant to `cyber-sentinel`, `code-reviewer`, and any agent processing untrusted input.
- **Pricing** — introductory $2/$10 per Mtok through 2026-08-31, then standard $3/$15.

## Quality Metrics

- **74 Total Agents** - Complete coverage across all organizational functions
- **12 Strategic Divisions** - Logical grouping of related capabilities
- **Hierarchical Structure** - Clear command and coordination patterns
- **Comprehensive Coverage** - From strategy to implementation to operations
- **Automatic Documentation** - Self-maintaining project documentation and change tracking
- **Complexity-Based Reasoning** - Tailored thinking budgets aligned with Opus 5.5 effort levels
- **SDK Compliance Score** - 10/10 full alignment with Anthropic Claude Agent SDK best practices (Opus 5.5 + Sonnet 5)

## Surface Coverage

The roster ships as a plugin and runs on every surface that loads Claude Code plugins — **Claude Code (CLI, Desktop, IDE) and Claude Cowork run the full set**; plain chat runs skills, slash commands, and connectors but greys out agents and hooks.

Full matrix and Cowork-specific constraints: [orchestration.md](orchestration.md) → *Claude Cowork*.
