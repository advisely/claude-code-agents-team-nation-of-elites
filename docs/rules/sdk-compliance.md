# Claude Agent SDK Alignment (v2.0.0+)

The Nation of Elites achieves **complete alignment** with Anthropic's Claude Agent SDK best practices and tracks the current flagship model, **Claude Opus 4.8** (`claude-opus-4-8`, released 2026-05-28).

## Current Model Targets

| Alias | Resolves To | Use |
|-------|-------------|-----|
| `opus` | `claude-opus-4-8` | Orchestration, complex reasoning, long-horizon agentic work |
| `sonnet` | Current Sonnet generation | Fast read-only, framework specialists |
| `haiku` | Current Haiku generation | Lightweight support tasks |

Agents use aliases — never hard-coded model IDs — so the harness tracks Anthropic releases automatically.

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
- **Note (Opus 4.8 behavior):** the model still spawns fewer subagents by default, so be explicit when fan-out is desired (e.g. "spawn N subagents to analyze modules A, B, C in parallel"). For large, decomposable tasks, **Dynamic Workflows** (research preview) lets Claude plan a task and spin up hundreds of parallel subagents in one session, with each output verified before it is reported back.

## ✅ Strict Tool Use
- Tool definitions support `strict: true` for guaranteed schema conformance
- Ensures no type mismatches or missing fields in tool inputs
- Recommended for production agents where invalid tool parameters would cause failures

## ✅ Server-Side Tools
- `web_search_20250305` - Web search executed on Anthropic's servers
- `web_fetch_20250305` - URL content fetching on Anthropic's servers
- Handle `pause_turn` for long-running server tool operations

## ✅ Claude Opus 4.8 Features (SDK-Level)

These apply when calling the Messages API directly (e.g. `claude-api` skill, programmatic SDK usage). The Claude Code harness handles them automatically. Opus 4.8 builds on 4.7 with **no breaking API changes** — code already running on 4.7 needs no changes.

### Adaptive Thinking (replaces extended-thinking budgets)
```python
thinking = {"type": "adaptive"}
output_config = {"effort": "high"}  # default; raise to "xhigh" for harder tasks
```
**Breaking change (unchanged from 4.7):** `thinking={"type":"enabled","budget_tokens":N}` returns HTTP 400 on Opus 4.8. Adaptive thinking is off by default; set `"display":"summarized"` if you need thinking to stream to users. On 4.8 the model decides per turn whether to think, so there are fewer wasted thinking tokens at the same effort level.

### Effort Levels (Opus 4.8)
Five levels: `low` / `medium` / `high` / `xhigh` / `max`. The default is now **`high` on all surfaces** (Claude API + Claude Code) — a change from 4.7, where Claude Code defaulted to `xhigh`. `xhigh` (between `high` and `max`) is still available and recommended for API design, schema migration, and large codebase review, but is no longer the default. Reserve `max` for genuinely hard, isolated problems — it can over-think. Effort calibration is more reliable per level on 4.8.

### Task Budgets (Beta)
Advisory token countdown the model sees across a full agentic loop.
```python
output_config = {"effort": "xhigh", "task_budget": {"type": "tokens", "total": 128000}}
betas = ["task-budgets-2026-03-13"]
```
- Minimum 20K tokens; advisory — not a hard cap (`max_tokens` remains the ceiling)
- Use for cost-bounded long runs (pipeline skills, orchestrator loops)
- Do **not** set a task budget when quality matters more than speed

### File-System Memory
Opus 4.7 is materially better at reading/writing scratchpads and notes files. Agents that use `memory: project` or maintain `PLAN.md` / `CHANGELOG.md` benefit without changes. A managed scratchpad is also available via the client-side memory tool.

### High-Resolution Vision
Max image resolution raised to 2576px / 3.75MP (from 1568px / 1.15MP); coordinates are 1:1 with pixels. Relevant for `ux-ui-architect`, `visual-regression-specialist`, screenshot / document workflows.

### Sampling Parameters Removed
`temperature`, `top_p`, `top_k` return HTTP 400 on any non-default value. Remove from SDK calls; steer behavior via prompting.

### Tokenizer Changes
New tokenizer produces 1.0–1.35× more tokens for identical inputs vs Opus 4.6. Widen `max_tokens` and compaction triggers accordingly. Pricing is unchanged ($5 in / $25 out per M tokens); 1M context available at standard pricing with no long-context premium.

### Behavior Shifts (Steering Notes)
- **Sharper judgment & honesty** — Opus 4.8 is ~4× less likely to let flaws in its own code pass unremarked, and flags uncertainty instead of over-claiming. Benchmarks: agentic coding 64.3% → 69.2%; multidisciplinary reasoning with tools 54.7% → 57.9%.
- **Better tool triggering** — 4.8 is less likely to skip a tool call the task required (a 4.7 pain point), so you rarely need to raise effort just to get tool use
- **Better long-horizon coding** — improved long-context handling, fewer compactions, and better compaction recovery on long agentic traces
- **More literal instruction following** — agent prompts must state requirements explicitly; don't rely on implicit generalization
- **Fewer subagents by default** — explicit parallelization required (or use Dynamic Workflows for large fan-out)
- **Response length calibrates to task complexity** — verbosity scaffolding often redundant
- **More direct, less validation-forward tone** — some `humanizer` patterns now baked in natively
- **Real-time cybersecurity safeguards** — `cyber-sentinel` should reference the [Cyber Verification Program](https://claude.com/form/cyber-use-case) for authorized pentest work

### Dynamic Workflows (Research Preview)
A Claude Code research-preview capability: Claude plans a task, then spins up **hundreds of parallel subagents in a single session**, with each subagent's output verified before being reported back. Suited to very large, decomposable tasks — large-scale migrations, repo-wide audits, broad multi-file refactors. The Chief Operations Orchestrator and the `pipeline-quality` / `pipeline-full-build` skills are natural beneficiaries.

### Mid-Conversation System Messages
Opus 4.8 accepts `role: "system"` messages immediately after a user turn (no beta header required). This appends updated instructions later in a long-running conversation without restating the full system prompt, preserving prompt-cache hits on earlier turns and reducing input cost on agentic loops.

### Refusal Stop Details
The `stop_details` object on refusal responses (present since 4.7) is now publicly documented. It describes the **category** of refusal alongside the `refusal` stop reason, making it easier to route a declined request to the right next step.

### Fast Mode (Research Preview)
Set `speed: "fast"` on the Claude API for up to **2.5× higher output tokens/sec** from the same model, at premium pricing ($10 in / $50 out per M tokens). Research preview at launch.

### Lower Prompt-Cache Minimum
The minimum cacheable prompt length on Opus 4.8 is **1,024 tokens** (lower than 4.7), so short prompts that couldn't cache before can now create cache entries with no code changes.

## Quality Metrics

- **74 Total Agents** - Complete coverage across all organizational functions
- **12 Strategic Divisions** - Logical grouping of related capabilities
- **Hierarchical Structure** - Clear command and coordination patterns
- **Comprehensive Coverage** - From strategy to implementation to operations
- **Automatic Documentation** - Self-maintaining project documentation and change tracking
- **Complexity-Based Reasoning** - Tailored thinking budgets aligned with Opus 4.8 effort levels
- **SDK Compliance Score** - 10/10 full alignment with Anthropic Claude Agent SDK best practices (Opus 4.8)
