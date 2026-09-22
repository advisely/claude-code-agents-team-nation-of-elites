# Standards Compliance & Agent Format

## Claude Code CLI Alignment

This multi-agent system follows these key principles:

- **Agent Metadata** - All agents include proper name, description, and tools configuration
- **Context Awareness** - Agents understand their role within the larger system
- **Delegation Patterns** - Clear handoff mechanisms between specialized agents
- **Tool Integration** - Proper use of Claude Code CLI tools (Read, Grep, Glob, Bash, Write, Edit)

## Compliant Agent Structure (Mar 2026 Official Spec)

```yaml
---
# Required fields
name: agent-name-kebab-case
description: Action verb + domain + when to use. Claude uses this for auto-delegation.

# Tool access (optional - inherits all if omitted)
tools: Read, Grep, Glob, Bash, Write, Edit
# disallowedTools: Write, Edit  # Alternative: blocklist pattern

# Model selection (optional - default: inherit)
model: sonnet  # alias — resolves to current generation. opus → claude-opus-5-5, sonnet → claude-sonnet-5. (Haiku is not used — see note below.)

# Permission mode (optional - default: default)
permissionMode: acceptEdits  # default | acceptEdits | dontAsk | plan

# Persistent memory (optional)
memory: project  # user (cross-project) | project (git-tracked) | local (git-ignored)

# Skills preloading (optional)
skills: [skill-name-1, skill-name-2]

# Advanced (optional)
maxTurns: 20             # Cap agentic turns for cost control
background: false        # Run as background task
isolation: worktree      # Git worktree isolation for parallel dev
effort: medium           # low | medium | high | xhigh | max — Opus 5.5 default: medium; Sonnet 5 default: high

# MCP servers scoped to this agent (optional)
mcpServers:
  my-server:
    command: "node"
    args: ["server.js"]

# Lifecycle hooks (optional)
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/lint.sh"
  PreToolUse:
    - matcher: "Bash"
      if: "command contains 'rm -rf'"
      hooks:
        - type: command
          command: "echo 'Blocked destructive command' >&2; exit 2"
---

# Agent Title
Mission, Workflow, Output Format, Heuristics, Thinking Policy, Delegation Cues
```

### Field Priority Guidelines

| Field | When to Add |
|-------|-------------|
| `memory: project` | Agents that benefit from cross-session learning (reviewers, analysts, orchestrators) |
| `skills: [...]` | Framework specialists with matching skills |
| `permissionMode: acceptEdits` | Code-writing agents (developers, experts) |
| `permissionMode: plan` | Read-only research/analysis agents |
| `model: sonnet` | Default for specialists, developers, and fast read-only work (resolves to `claude-sonnet-5` — 1M context, near-Opus quality) |
| `model: opus` | Orchestrators, strategy architects, BD/Content (resolves to `claude-opus-5-5`) |
| `model: haiku` | **Never.** Haiku is not used in this roster — use `sonnet` as the floor for lightweight work. |
| `maxTurns: N` | Agents with potentially unbounded loops (cost control) |
| `isolation: worktree` | Agents doing parallel implementation work |
| `mcpServers: {...}` | Agents needing scoped MCP server access |
| `effort: <level>` | Usually **omit**. `opus` agents then run at Opus 5.5's `medium`, which matches or beats Opus 5 at `high`. Set it only on measured evidence: `low` for routine or latency-sensitive agents, `xhigh`/`max` only where evals show a gain (Opus 5.5 thinks more per turn than Opus 5 at the same level) |

## Automatic Documentation Updates

Key agents automatically maintain project documentation without manual intervention:
- **Backend/Frontend Developers**: Update CLAUDE.md, PLAN.md, CHANGELOG.md after implementation
- **Code Reviewer**: Updates quality status, security findings, and review completion
- **DevOps Engineer**: Updates CI/CD configuration, infrastructure status, and deployment milestones
- **Chief Operations Orchestrator**: Updates team assignments, decisions, and orchestration phases

Standard documentation files: `CLAUDE.md` (project config), `PLAN.md` (plan-of-record), `CHANGELOG.md` (version history).

## Modular Rule Files (Best Practice)

Per Anthropic's latest guidance, rule files should be:
- **50-100 lines each**, focused on a single domain
- **Loaded on-demand** based on task context (not all at once)
- **Version controlled** alongside agent definitions
- This prevents context bloat and reduces hallucination risk

## Strict Tool Use

For production agents, add `strict: true` to tool definitions:
```json
{
  "name": "tool_name",
  "strict": true,
  "input_schema": { ... }
}
```
This guarantees schema conformance — no type mismatches or missing fields.

## Claude Opus 5.5 Migration Notes (SDK Users Only)

The Claude Code harness handles these automatically. Only apply them when calling the Messages API directly. Coming from Opus 4.8 or older, apply the Opus 5 changes first (thinking on by default, `budget_tokens`/sampling/prefill removed). Then, for Opus 5.5:

- **⚠️ Breaking:** thinking **can't be disabled**. `thinking={"type":"disabled"}` and `budget_tokens` return HTTP 400 at every effort level. Remove them, pick an `effort` (start `low` for routes that ran thinking-off), size `max_tokens` for thinking plus reply, and read blocks by `type`.
- **⚠️ Breaking:** forced `tool_choice` (`any` / `tool`) returns HTTP 400, including on Batches and `count_tokens`. Use `auto` + `strict: true` + a prompt line naming the tool, and check the call happened. Or use structured outputs.
- **⚠️ Breaking:** **preserved thinking**. Blocks are bound to the model and to an unchanged prefix. Accounts created on/after 2026-08-31 get HTTP 400 on edited history. Keep harnesses append-only (mid-conversation system messages, `tool_addition`, server-side compaction). A fallback to Opus 5/4.8 runs without 5.5's reasoning.
- **⚠️ Breaking:** computer use needs `computer_toolset_20260801` on the Claude API / Google Cloud (`computer_20251124` returns 400).
- **Silent:** text between tool calls arrives as `thinking` blocks (empty by default). Set `display: "updates"` (beta `thinking-display-updates-2026-08-18`) if a UI shows progress.
- **Default effort is `medium`** (Opus 5: `high`). Set it explicitly.
- **Refusals:** new `bio` and `reasoning_extraction` categories. Check `stop_reason` first, and ship `fallbacks="default"` (beta `server-side-fallback-2026-07-01`).
- **Pricing:** $4/$20 per Mtok, cache reads $0.20, fast mode $8/$40 (Claude API only).
- **Unchanged from Opus 5:** mid-conversation system messages and tool changes, per-message effort, task budgets, 512-token cache minimum, tokenizer, 1M/128K, `display` default `"omitted"`.

### Prompt-Authoring Notes for Agent Files

What belongs in an agent's Markdown body under Opus 5.5:

- **Do not instruct agents to verify their own work** (carried over from Opus 5). The model self-verifies, and "add a final verification step" or "double-check before responding" produced over-verification. Re-test before re-adding any.
- **Do not instruct agents to delegate more.** Where an agent fans out, state a **ceiling** instead (see [orchestration.md](orchestration.md) → *Delegation Discipline*).
- **Never ask an agent to write out its internal reasoning.** Opus 5.5 can decline that as `reasoning_extraction`. The standard *Thinking Policy* wording ("internal scratchpad… surface only concise rationale bullets… no raw chain-of-thought") is compliant. Keep it that way.
- **Drop "think carefully / step by step" lines.** Effort decides thinking depth. Such lines add latency without a clear quality gain.
- **Name concrete anti-patterns rather than vague ones.** Opus 5.5 responds best to specific lists ("no cream backgrounds, no pill buttons") over general ones ("avoid a generic look").
- **Agents working across connected apps** (CRM, email, docs) should explore relevant sources before acting.

Conciseness, deliverable length, and scope discipline are still worth *adding*. Opus 5.5 reports more clearly than Opus 5, so re-test how much of that steering an agent still needs.
