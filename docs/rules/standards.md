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
model: sonnet  # sonnet (fast read-only / general) | opus (orchestration)

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
effort: high             # Override session effort level (low/medium/high/maximum)

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
| `model: sonnet` | Fast read-only exploration agents |
| `model: opus` | Only orchestrators and executive agents (max 3-4) |
| `maxTurns: N` | Agents with potentially unbounded loops (cost control) |
| `isolation: worktree` | Agents doing parallel implementation work |
| `mcpServers: {...}` | Agents needing scoped MCP server access |
| `effort: high` | Override reasoning depth per-agent |

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

## Strict Tool Use (Opus 4.6+)

For production agents, add `strict: true` to tool definitions:
```json
{
  "name": "tool_name",
  "strict": true,
  "input_schema": { ... }
}
```
This guarantees schema conformance — no type mismatches or missing fields.
