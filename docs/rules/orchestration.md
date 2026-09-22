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

## Adaptive Thinking (Claude Opus 5.5)

Opus 5.5 dynamically decides when and how much reasoning is required, and **thinking is always on**. `thinking: disabled` and `budget_tokens` both return HTTP 400 at every effort level. In Claude Code, the thinking toggle, `alwaysThinkingEnabled`, and `MAX_THINKING_TOKENS=0` do nothing on Opus 5.5.

- **Effort is the only control**: `low` → `medium` → `high` → `xhigh` → `max`. The **default is `medium`**, one level below Opus 5's `high`. Claude Code does not carry an Opus 5 effort setting over, and starts Opus 5.5 at `medium` until it gets its own `modelSettings` entry
- **Level names don't map 1:1.** Opus 5.5 at `medium` matches or beats Opus 5 at `high` on coding and knowledge work, and `low` comes close on several coding evals. Start at `medium` and move only on measured evidence
- **At a given level it thinks more per turn than Opus 5**, most of all at `xhigh`/`max`. Reserve those for measured gains, and give `max_tokens` room (64K+) for long agentic turns
- **To cut thinking, lower effort first.** It is more reliable than "think less" instructions
- Orchestrator can set effort levels per agent based on task complexity (see `effort:` frontmatter field). No roster agent sets one today, which is deliberate: `medium` is the right baseline

## Task Budgets (Beta)

For long-running agentic loops where cost must be bounded, set a task budget via the beta header `task-budgets-2026-03-13`. This gives the model a visible countdown across thinking, tool calls, tool results, and final output — advisory, not a hard cap (`max_tokens` remains the ceiling). Minimum 20K tokens. Natural fit for `pipeline-quality`, `pipeline-full-build-cloud`/`pipeline-full-build-desktop`, and orchestrator-driven loops. Skip when quality matters more than speed.

## Recurring Tasks (`/loop`)

`/loop` is a Claude Code **session-level scheduler**: give it a prompt and a cadence, and it re-fires that prompt on every tick as if you had typed it, against the current project context. It is a different axis from Agent Teams and Dynamic Workflows — those parallelize work *within* one task; `/loop` repeats one task *across time*.

**Syntax & behavior**
- `/loop 5m <prompt-or-slash-command>` — run every 5 minutes (interval may lead or trail; e.g. `<prompt> every 2h`).
- `/loop <prompt>` with **no interval** — Claude **self-paces**, deciding when to run again based on what it's watching.
- **Session-scoped** — the loop lives in the current conversation and stops when you start a new one.
- **Auto-expiry** — recurring tasks run up to 7 days, fire one final time, then delete themselves (a safety bound so a forgotten loop can't burn credits indefinitely).

**When to reach for `/loop` vs. alternatives**
| Need | Use |
|------|-----|
| Repeat one task on a cadence within a live session | `/loop` |
| Run something on a cron schedule across sessions / when you're away | `/schedule` (cloud routines) |
| Parallelize independent subtasks of one job | Subagents / Agent Teams |
| Fan out a large decomposable task once | Dynamic Workflows |

**Orchestrator guidance**
- The Chief Operations Orchestrator can hand a monitoring brief to `/loop` (e.g. *"every 15m, check SLO burn and page sre-specialist if error budget < 20%"*) instead of holding an agent open.
- Keep loop prompts **idempotent and bounded** — each tick should do one check + one conditional action, not open-ended work, so cost stays predictable across the 7-day window.
- Pair with **Task Budgets** when a loop drives heavy agentic work per tick.
- **Don't mistake a report for completion.** On Opus 5.5, some progress updates end the turn with text. A tick that ends with open checklist items and no stated blocker should be re-prompted with those items by name, capped at 2–3 continuations, so a stuck tick surfaces instead of looping.

**Agents whose work is inherently recurring** (each carries a `Recurring Work (/loop)` note):

| Agent | Division | Example loop |
|-------|----------|--------------|
| `aiops-specialist` | 06 AI/ML | Poll model drift / inference health; alert on threshold breach |
| `sre-specialist` | 05 SecOps | Watch SLO burn rate, error budgets, open incidents |
| `observability-engineer` | 05 SecOps | Re-check dashboards / alert rules; surface anomalies |
| `devops-engineer` | 05 SecOps | Watch a deploy or CI run to green, then report |
| `client-success-manager` | 11 BD | Re-score account health on a cadence; flag churn risk |
| `business-development-manager` | 11 BD | Refresh pipeline forecast; flag stalled deals |
| `lead-generation-specialist` | 11 BD | Advance nurture sequences; re-score new leads |
| `market-intelligence-analyst` | 11 BD | Monitor competitor moves / market news |
| `social-media-strategist` | 11 BD | Run content-calendar cadence; check campaign metrics |

## Opus 5.5 Steering Notes

Existing Opus 5 prompts perform well on Opus 5.5, so the Opus 5 steering below stays the starting point. Anthropic's guidance is to **re-test each Opus 5-specific instruction** (verbosity, verification, scope) on your own tasks rather than carry it forward untested. New Opus 5.5 items are marked 🆕.

- **Delegation caps (from Opus 5)** — Opus 4.8 under-reached; Opus 5 needed a **cap, not a nudge**. Keep the caps in *Delegation Discipline* below. Opus 5.5 also sustains multi-hour audits and migrations with parallel subagents, so test before tightening further
- **Self-verification (from Opus 5)** — instructions like "add a final verification step" or "double-check your answer" caused over-verification. Keep them out, and re-test before re-adding any
- **Conciseness, deliverable length, scope** — still worth stating explicitly. Opus 5.5's reports are notably clearer (what it did, found, needs), so re-test how much length steering is still required
- 🆕 **Unattended early stops** — some progress updates end the turn with text (`end_turn`). Harnesses (`/loop`, Agent Teams, pipeline skills) should treat a text-only end of turn as a *report*: keep the task in a checklist, re-prompt with the open items by name, cap at 2–3 auto-continuations, and wait for background commands/subagents to return. For fully unattended agents, a system-prompt addition that names the unwanted stops (next step announced but not taken, offers to continue, non-blocking decision lists, "good place to report") reduces them. Add it from the first request only, and keep confirmation for destructive actions
- 🆕 **Time signals for agent teams** — give the lead a time budget and append `elapsed 340s / 1200s` to each message back to it. Teams finish sooner at comparable quality. Set the budget above your target, since it is advisory. With no sensible budget, show elapsed time plus: *"Time matters here: do not spend time that can be avoided, and the earlier a correct result is obtained, the better."*
- 🆕 **Explore before acting in multi-app work** — Opus 5.5 gets to work quickly. BD/PMO agents working across email, docs, sheets, and CRM should open every source that could bear on the task first, including unnamed ones. The BD-wing agents carry this as an *Explore Before Acting* heuristic
- 🆕 **Progress updates live in `thinking` blocks** — SDK clients need `display: "updates"` to see them. Ask in the system prompt for the cadence you want: a one-line intent up front and a short recap at the end
- 🆕 **Frontend defaults** — name the specific styles to avoid instead of "no generic look". `ux-ui-architect` and `frontend-developer` carry this
- 🆕 **Refusal categories widened** — biology joins cyber, plus `reasoning_extraction`. Never ask an agent to print its internal reasoning. The roster's "concise rationale bullets, no raw chain-of-thought" policy already complies. Route benign declines via automatic fallbacks rather than retrying blind
- **More literal instruction following** — state requirements explicitly, and don't rely on implicit generalization from one example to another

### Delegation Discipline

Each subagent re-establishes context, re-explores, reports back, and the coordinator re-reads the report. That overhead compounds because Opus 5 and 5.5 delegate freely. Bound it:

- **Delegate** genuinely independent, sizeable tracks — wide multi-file investigations, unrelated modules
- **Don't delegate** work completable in a handful of tool calls, and **never delegate verification** — that belongs in the main agent loop
- Prefer one subagent over several; if the task fits one, use one. A deterministic ceiling is the reliable lever
- Brief precisely the first time; commit to the delegation instead of re-deriving its findings
- Launch parallel agents in a **single message with multiple tool uses** so they actually run concurrently

## Claude Code Harness Changes (2.1.181 – 2.1.280)

The harness itself changed substantially alongside the model. These affect how the roster runs, independent of any agent file:

| Change | Impact on the roster |
|--------|---------------------|
| **Subagents run in the background by default** | The orchestrator keeps working while they run and is notified on completion. The 2-agent WIP limit is now about *attention*, not blocking |
| **Nested subagents to depth 3** (was 1) | A spawned specialist can itself delegate. Configurable via `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` — combined with eager delegation, this is the setting to lower if fan-out runs away |
| **Per-session subagent cap: 200** | `CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION` |
| **Concurrent subagent cap: 20** | `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` — the practical ceiling for orchestrator fan-out |
| **`/subtask`** | Spawns an in-session subagent (took over the old `/fork` subagent behavior) |
| **`/fork`** | Now copies the conversation into a new **background session** |
| **`/code-review` runs as a background subagent** | Review work no longer fills the main conversation — complements `pipeline-quality`'s review pass (steps 10-11) |
| **`claude agents` view + `Notification` hook** | Fires on `agent_needs_input` / `agent_completed`. Background agents can commit, push, and open a draft PR when finished |
| **Subagents inherit session thinking config** | Effort/thinking set once at session level now propagates |
| **Sandbox settings** | `sandbox.network.strictAllowlist`, `sandbox.filesystem.disabled`, `sandbox.credentials`, `sandbox.allowAppleEvents` — relevant to `cyber-sentinel` and `devops-engineer` |
| **Permission mode rename** | "default" → **"Manual"** across CLI, VS Code, and JetBrains. The `permissionMode: default` frontmatter value is unchanged |
| **Opus 5.5 is the default model (2.1.280)** | On every plan, Pro and Team Standard included. `opus` resolves to Opus 5.5 except on Microsoft Foundry (still Opus 4.6; set `ANTHROPIC_DEFAULT_OPUS_MODEL`). Effort starts at `medium` and is not carried over from Opus 5 |
| **Thinking can't be turned off on Opus 5.5** | The session toggle, `alwaysThinkingEnabled`, and `MAX_THINKING_TOKENS=0` have no effect. Control depth with the session effort level or `effort:` frontmatter instead |
| **Skill frontmatter tolerance** | `display-name`, `default-enabled`, `fallback`, `metadata.*` accept kebab-case, snake_case, **and** camelCase; a malformed `SKILL.md` now loads with empty metadata instead of failing outright |

## Dynamic Workflows

Claude plans a task, then spins up parallel subagents in a single session, with each subagent's output verified before it is reported back. This scales the orchestrator pattern beyond the 2-agent WIP limit for large, decomposable tasks — repo-wide audits, large-scale migrations, broad multi-file refactors.

**Size guideline (2.1.219):** workflows now default to **medium — aim for fewer than 15 agents**. Change it via the `workflowSizeGuideline` settings key or *Dynamic workflow size* in `/config`. Given eager delegation on Opus 5 and 5.5, treat the medium default as the right starting point rather than a limit to raise reflexively. Opus 5.5's long-run strength shows on exactly these tasks, and a time budget in the brief tends to speed them up more than a bigger team does.

The Chief Operations Orchestrator and the `pipeline-quality` / `pipeline-full-build-cloud` / `pipeline-full-build-desktop` skills are natural beneficiaries. Decompose explicitly, keep subagent tasks independent, and rely on the built-in verification of returned outputs — **do not add your own verification stage on top**. The model already self-verifies.

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

## Claude Cowork (Research Preview)

**Claude Cowork** is Anthropic's agentic surface for non-technical work — built on the Claude Code engine but aimed at project managers, operations leads, and department heads rather than developers. It launched as a macOS desktop app in January 2026 and expanded to **web and mobile for Max subscribers** in July 2026, running in an isolated cloud environment so work continues after you close your laptop and resumes from any surface.

**Why this matters here: Cowork loads plugins, and plugins carry agents.** Nation of Elites installs into Cowork the same way it installs into Claude Code — the marketplace entry and `plugin.json` are unchanged.

### Component support by surface

| Component | Claude Code (CLI/Desktop/IDE) | Cowork | Claude Desktop & web chat |
|-----------|------|--------|---------------------------|
| Skills | ✅ | ✅ | ✅ |
| Slash commands | ✅ | ✅ | ✅ |
| MCP connectors | ✅ | ✅ (via Anthropic's cloud) | ✅ |
| **Sub-agents** | ✅ | ✅ | ❌ greyed out |
| **Hooks** | ✅ | ✅ | ❌ greyed out |

Sub-agents and hooks are the two components that **run only in Cowork and Claude Code**, never in plain chat. The full 74-agent roster is therefore available in Cowork and inert in chat — where the 33 skills and slash commands still work.

### Installing into Cowork

*Customize → Plugins → Personal plugins → **+** → Add marketplace*, then point at this repo's git URL. Anthropic-curated marketplaces (Knowledge Work, Financial Services, Legal) can be added the same way. Custom plugin files can also be uploaded directly on Desktop and in Cowork.

### Cowork-specific constraints

- **Connectors egress through Anthropic's cloud, not your local network.** A custom MCP connector must be reachable from Anthropic's public IP ranges — an internal-only service that works from the CLI will not work in Cowork
- **Plugins are saved locally per machine.** Org-wide sharing and private marketplaces are announced but not yet shipped; treat per-seat install as the current distribution model
- **Enterprise admin controls** may restrict available plugins or disable local MCP servers entirely
- Cowork ships **built-in** `pdf`, `docx`, `pptx`, `xlsx`, and `canvas-design` skills that load automatically. Do not duplicate them — the Content & Localization and Business Development wings should lean on these for file production and reserve custom skills for judgment (e.g. `humanizer`)
- Cowork parallelizes across sub-agents natively; the roster's fan-out patterns apply, subject to the same delegation cap above

### Which wings benefit most

Cowork's audience maps onto the non-engineering divisions: **11_Business_Development** (proposals, pipeline, market intel, social), **10_Content_and_Localization** (books, publishing, translation), **02_Project_Management_Office**, and **01_Strategy_and_Planning**. These agents do knowledge work over files and documents — exactly Cowork's "work around work" use case, which Anthropic reports as ~33% business process and operations.

## Official Plugin Integrations

The deploy script auto-detects and offers to configure these official Anthropic plugins from the `claude-plugins-official` marketplace:

| Plugin | Best For Agents | Category |
|--------|----------------|----------|
| GitHub | code-reviewer, devops-engineer, chief-operations-orchestrator | Development |
| Slack | chief-operations-orchestrator, program-manager | Communication |
| Atlassian (Jira) | project-manager-scrum-master, product-manager | Project Management |
| Figma | ux-ui-architect, frontend-developer | Design |
| Sentry | sre-specialist, observability-engineer | Monitoring |
| Vercel | nextjs-expert, devops-engineer | Deployment |
| Firebase | mobile-architect, backend-developer | Backend |
| Supabase | database-expert, backend-developer | Database |
| Notion | documentation-specialist, business-analyst | Documentation |
| Linear | product-manager, project-manager-scrum-master | Project Management |
| Atlassian (Confluence) | functional-analyst, documentation-specialist | Documentation |
| Asana | program-manager | Project Management |
| Slack | client-success-manager, business-development-manager | Communication |
| Notion | proposal-architect, client-success-manager | Documentation |
| Linear | business-development-manager | Pipeline Tracking |

Use `/plugin install <name>@claude-plugins-official` or the deploy script's interactive plugin setup. The `claude-plugins-official` marketplace is available by default — no `marketplace add` needed. Jira and Confluence both ship in the single `atlassian` plugin (`/plugin install atlassian@claude-plugins-official`).
