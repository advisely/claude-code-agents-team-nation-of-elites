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
model: sonnet  # alias — resolves to current generation. opus → claude-opus-5, sonnet → claude-sonnet-5. (Haiku is not used — see note below.)

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
effort: high             # Opus 5 levels: low | medium | high (default) | xhigh | max

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
| `model: opus` | Orchestrators, strategy architects, BD/Content (resolves to `claude-opus-5`) |
| `model: haiku` | **Never.** Haiku is not used in this roster — use `sonnet` as the floor for lightweight work. |
| `maxTurns: N` | Agents with potentially unbounded loops (cost control) |
| `isolation: worktree` | Agents doing parallel implementation work |
| `mcpServers: {...}` | Agents needing scoped MCP server access |
| `effort: high` | Default effort on Opus 5 (all surfaces); raise to `xhigh` for agentic coding and hard design/architecture. Sweep *down* to `medium`/`low` where evals hold — Opus 5 stays strong at low effort |

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

## Claude Opus 5 Migration Notes (SDK Users Only)

The Claude Code harness handles these automatically. Only apply when calling the Messages API directly. Opus 5 keeps Opus 4.8's request surface with **two breaking changes**, both about thinking:

- **⚠️ Breaking:** thinking is now **on by default** — omitting `thinking` runs adaptive (Opus 4.8 ran without thinking). `max_tokens` caps thinking *plus* response text, so a budget sized for a thinking-off 4.8 call can truncate mid-answer. Raise `max_tokens` or pass `thinking={"type":"disabled"}`.
- **⚠️ Breaking:** `thinking={"type":"disabled"}` with `effort` of `xhigh`/`max` returns HTTP 400 (accepted at `high` or below). Validated **per request** — audit every call site, not just the first.
- **New:** mid-conversation **tool changes** via beta `mid-conversation-tool-changes-2026-07-01` — add/remove tools between turns without invalidating the prompt cache.
- **New:** automatic refusal fallbacks — beta `server-side-fallback-2026-07-01` with `fallbacks="default"`. Check `stop_reason` before reading `content`; a refusal returns HTTP 200.
- **New:** prompt-cache minimum lowered to **512 tokens** (from 1,024) — short prompts now cache with no code change.
- **Unchanged from 4.8:** `budget_tokens` returns HTTP 400 (use adaptive + `effort`); non-default `temperature`/`top_p`/`top_k` return HTTP 400; assistant prefill returns HTTP 400 (use `output_config.format`); `thinking.display` defaults to `"omitted"` — set `"summarized"` to stream reasoning; same tokenizer, so token counts are roughly unchanged when coming from 4.7/4.8.

### Prompt-Authoring Notes for Agent Files

Two Opus 5 behaviors change what belongs in an agent's Markdown body:

- **Do not instruct agents to verify their own work.** Opus 5 does it unprompted; "add a final verification step" or "double-check before responding" now produces over-verification with no capability gain. Delete such lines rather than rewording them.
- **Do not instruct agents to delegate more.** Opus 5 reaches for subagents freely. Where an agent fans out, state a **ceiling** instead (see [orchestration.md](orchestration.md) → *Delegation Discipline*).

Conciseness, deliverable length, and scope discipline are the instructions worth *adding* — Opus 5 runs long on all three by default.
