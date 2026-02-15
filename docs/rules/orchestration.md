# Orchestration Patterns & Agent Interaction

## Hierarchical Command Flow

```
Executive Wing → Strategy & Planning → Project Management → Implementation Teams
     ↓                    ↓                    ↓                    ↓
Business Vision → Technical Strategy → Process Management → Specialized Execution
```

## Delegation Patterns

1. **Upward Escalation** - Complex decisions escalate to appropriate leadership
2. **Lateral Coordination** - Peer-to-peer collaboration for cross-functional work
3. **Downward Delegation** - Leadership distributes work to specialized teams
4. **Expert Consultation** - Specialists consulted for domain-specific guidance

## Communication Protocols

- **Task Tool (v2)** - Claude automatically spawns agents via the Task tool based on user intent
- **Legacy Pattern (v1)** - `@agent-[name]` explicit invocation (backward compatible)
- **Context Handoffs** - Structured information transfer between agents
- **Status Reporting** - Regular progress updates through the hierarchy
- **Documentation Trails** - Comprehensive documentation of decisions and implementations

## Agent Teams (Opus 4.6)

Opus 4.6 introduces **Agent Teams** — agents that work in parallel and coordinate autonomously. This extends beyond simple subagent spawning.

### When to Use Agent Teams
- **Codebase-wide reviews**: Multiple reviewers analyzing different modules simultaneously
- **Multi-stack projects**: Frontend, backend, and infrastructure agents working in parallel
- **Large-scale refactoring**: Parallel analysis and modification across multiple components
- **Comprehensive audits**: Security, performance, and accessibility checks running concurrently

### Agent Teams vs Subagents

| Aspect | Subagents | Agent Teams |
|--------|-----------|-------------|
| **Scope** | Single search/analysis task | Full multi-step workflows |
| **Lifecycle** | Ephemeral (Created → Execute → Report → Terminate) | Sustained coordination |
| **WIP Limit** | Max 2 in parallel | Flexible based on task decomposition |
| **Coordination** | Report back to orchestrator | Coordinate autonomously with each other |
| **Use Case** | Information gathering, file processing | Complex parallel development |

### Configuration
- Orchestrator may relax the default WIP limit (2 agents) for Agent Teams scenarios
- Each team member gets an isolated context window
- Results are synthesized by the orchestrator into integrated output

## Subagent Coordination

### Nature of Subagents
Subagents are **temporary, task-specific spawns** that exist only for the duration of a specific task. Think of them as ephemeral worker processes: Created → Execute → Report → Terminate.

**Naming Convention**: Use descriptive, task-specific names:
- ✅ `subagent-search-logs-morning`, `subagent-analyze-frontend`
- ❌ `subagent-1`, `subagent-general` (too generic)

## Context Compaction Strategy

- **Trigger**: When context usage > 80%
- **Method**: Summarize into decisions, status, blockers, next steps
- **Preserve**: Critical technical details, API contracts, security findings
- **Discard**: Verbose explanations, duplicate information, resolved issues
- **API Feature (Beta)**: Anthropic offers server-side context compaction that can supplement manual compaction

## Adaptive Thinking (Opus 4.6)

Opus 4.6 dynamically decides when and how much reasoning is required:
- **Effort Levels**: Low → Medium → High → Maximum
- Simple tasks get fast responses; complex tasks get deeper reasoning
- Orchestrator can set effort levels per agent based on task complexity
