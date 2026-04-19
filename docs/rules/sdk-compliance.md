# Claude Agent SDK Alignment (v2.0.0+)

The Nation of Elites achieves **complete alignment** with Anthropic's Claude Agent SDK best practices and tracks the current flagship model, **Claude Opus 4.7** (`claude-opus-4-7`, released 2026-04-16).

## Current Model Targets

| Alias | Resolves To | Use |
|-------|-------------|-----|
| `opus` | `claude-opus-4-7` | Orchestration, complex reasoning, long-horizon agentic work |
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
- **Note (Opus 4.7 behavior):** the model spawns fewer subagents by default. Be explicit when fan-out is desired (e.g. "spawn N subagents to analyze modules A, B, C in parallel").

## ✅ Strict Tool Use
- Tool definitions support `strict: true` for guaranteed schema conformance
- Ensures no type mismatches or missing fields in tool inputs
- Recommended for production agents where invalid tool parameters would cause failures

## ✅ Server-Side Tools
- `web_search_20250305` - Web search executed on Anthropic's servers
- `web_fetch_20250305` - URL content fetching on Anthropic's servers
- Handle `pause_turn` for long-running server tool operations

## ✅ Claude Opus 4.7 Features (SDK-Level)

These apply when calling the Messages API directly (e.g. `claude-api` skill, programmatic SDK usage). The Claude Code harness handles them automatically.

### Adaptive Thinking (replaces extended-thinking budgets)
```python
thinking = {"type": "adaptive"}
output_config = {"effort": "high"}  # or "xhigh" (recommended default for coding)
```
**Breaking change:** `thinking={"type":"enabled","budget_tokens":N}` returns HTTP 400 on Opus 4.7. Adaptive thinking is off by default; set `"display":"summarized"` if you need thinking to stream to users.

### Effort Levels (Opus 4.7)
Five levels: `low` / `medium` / `high` / `xhigh` / `max`. Claude Code's default is `xhigh` (new level between `high` and `max`). Use `xhigh` for API design, schema migration, large codebase review. Reserve `max` for genuinely hard, isolated problems — it can over-think.

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
- **More literal instruction following** — agent prompts must state requirements explicitly; don't rely on implicit generalization
- **Fewer tool calls by default** — raise effort or prompt explicitly for more tool use
- **Fewer subagents by default** — explicit parallelization required
- **Response length calibrates to task complexity** — verbosity scaffolding often redundant
- **More direct, less validation-forward tone** — some `humanizer` patterns now baked in natively
- **Real-time cybersecurity safeguards** — `cyber-sentinel` should reference the [Cyber Verification Program](https://claude.com/form/cyber-use-case) for authorized pentest work

## Quality Metrics

- **74 Total Agents** - Complete coverage across all organizational functions
- **12 Strategic Divisions** - Logical grouping of related capabilities
- **Hierarchical Structure** - Clear command and coordination patterns
- **Comprehensive Coverage** - From strategy to implementation to operations
- **Automatic Documentation** - Self-maintaining project documentation and change tracking
- **Complexity-Based Reasoning** - Tailored thinking budgets aligned with Opus 4.7 effort levels
- **SDK Compliance Score** - 10/10 full alignment with Anthropic Claude Agent SDK best practices (Opus 4.7)
