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

## Agent Teams (Experimental)

Agent Teams enable parallel multi-agent coordination with shared task lists and direct inter-agent messaging.

**Enable:** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

### When to Use Agent Teams
- **Codebase-wide reviews**: Multiple reviewers analyzing different modules simultaneously
- **Multi-stack projects**: Frontend, backend, and infrastructure agents working in parallel
- **Large-scale refactoring**: Parallel analysis and modification across multiple components
- **Comprehensive audits**: Security, performance, and accessibility checks running concurrently
- **Competing hypotheses**: Test different debugging theories in parallel

### Agent Teams vs Subagents

| Aspect | Subagents | Agent Teams |
|--------|-----------|-------------|
| **Context** | Own window; results return to parent | Own window; fully independent |
| **Communication** | Report back to orchestrator only | Message each other directly |
| **Coordination** | Main agent manages all work | Shared task list with self-coordination |
| **Cost** | Lower (focused tasks) | Higher (linear scale with team size) |
| **Lifecycle** | Ephemeral (Created → Execute → Report → Terminate) | Sustained coordination |
| **Best for** | Quick focused tasks, info gathering | Complex parallel development |
| **Session resume** | Full support | Not supported (known limitation) |

### Configuration
- Orchestrator may relax the default WIP limit (2 agents) for Agent Teams scenarios
- Each team member gets an isolated context window
- Results are synthesized by the orchestrator into integrated output
- Start with 3-5 teammates; 5-6 tasks per teammate balances productivity vs cost
- Display modes: in-process (default) or split-panes (tmux/iTerm2 required)

### Hooks for Agent Teams
- `TeammateIdle` - Fired when a teammate has no tasks; useful for quality gates
- `TaskCreated` / `TaskCompleted` - Track task lifecycle for audit logging

### Known Limitations
- No session resumption with in-process teammates (`/resume` and `/rewind` don't restore them)
- One team per session (must clean up before starting new one)
- No nested teams (teammates can't spawn their own teams)
- Lead is fixed (can't promote teammate or transfer leadership)

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

## Subagent Advanced Features

### maxTurns
Limit the number of agentic turns a subagent can take before stopping. Use for cost control and preventing runaway agents:
```yaml
maxTurns: 20  # Cap at 20 tool-use turns
```

### Worktree Isolation
Subagents can work in isolated git worktrees for parallel development:
```yaml
isolation: worktree  # Creates temporary git worktree
```
Worktrees are auto-cleaned if the agent makes no changes; if changes are made, the worktree path and branch are returned.

### MCP Elicitation
MCP servers can now request user input during tool calls. Claude Code pauses the workflow to gather information, then resumes. Hook events: `Elicitation`, `ElicitationResult`.

### Hook `if` Field (v2.1.85+)
Fine-grained hook filtering using permission-rule syntax:
```json
{
  "event": "PreToolUse",
  "matcher": "Edit|Write",
  "if": "path matches 'src/core/**'",
  "type": "command",
  "command": "echo 'Editing core module'"
}
```

### LSP Servers in Plugins
Plugins now support `.lsp.json` for Language Server Protocol integrations, providing enhanced code intelligence (completions, diagnostics, go-to-definition) scoped to specific plugins.

## Official Plugin Integrations

The deploy script auto-detects and offers to configure these official Anthropic plugins from the `claude-plugins-official` marketplace:

| Plugin | Best For Agents | Category |
|--------|----------------|----------|
| GitHub | code-reviewer, devops-engineer, tech-lead-orchestrator | Development |
| Slack | tech-lead-orchestrator, program-manager | Communication |
| Jira | project-manager-scrum-master, product-manager | Project Management |
| Figma | ux-ui-architect, frontend-developer | Design |
| Sentry | sre-specialist, observability-engineer | Monitoring |
| Vercel | nextjs-expert, devops-engineer | Deployment |
| Firebase | mobile-architect, backend-developer | Backend |
| Supabase | database-expert, backend-developer | Database |
| Notion | documentation-specialist, business-analyst | Documentation |
| Linear | product-manager, project-manager-scrum-master | Project Management |
| Confluence | functional-analyst, documentation-specialist | Documentation |
| Asana | program-manager | Project Management |

Use `/plugin install <name>@claude-plugins-official` or the deploy script's interactive plugin setup.
