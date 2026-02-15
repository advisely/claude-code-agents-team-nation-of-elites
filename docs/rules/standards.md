# Standards Compliance & Agent Format

## Claude Code CLI Alignment

This multi-agent system is designed to work seamlessly with Anthropic's Claude Code CLI, following these key principles:

- **Agent Metadata** - All agents include proper name, description, and tools configuration
- **Context Awareness** - Agents understand their role within the larger system
- **Delegation Patterns** - Clear handoff mechanisms between specialized agents
- **Tool Integration** - Proper use of Claude Code CLI tools (LS, Read, Grep, Glob, Bash)

## Compliant Agent Structure

```yaml
---
name: agent-name
description: |
  Clear description with usage examples
tools: LS, Read, Grep, Glob, Bash
---

# Agent Title
Mission, Workflow, Output Format, Heuristics, Delegation Cues
```

## Automatic Documentation Updates

Key agents automatically maintain project documentation:
- **Backend/Frontend Developers**: Update CLAUDE.md, PLAN.md, CHANGELOG.md after implementation
- **Code Reviewer**: Updates quality status, security findings, and review completion
- **DevOps Engineer**: Updates CI/CD configuration, infrastructure status, and deployment milestones
- **Tech Lead Orchestrator**: Updates team assignments, decisions, and orchestration phases

## Standardized Documentation Files

- **CLAUDE.md**: Project configuration, team assignments, implementation status, architecture decisions
- **PLAN.md**: Current plan-of-record, milestones, task status, dependencies, risk mitigation
- **CHANGELOG.md**: Chronological record of features, changes, fixes, and major decisions

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
