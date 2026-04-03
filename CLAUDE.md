# Claude Code CLI Project Configuration - Nation of Elites

**Project:** Claude Code Agents - Team Nation of Elites
**Author:** Yassine Boumiza ([boumiza.com](https://boumiza.com))
**Repo:** [advisely/claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites)

## Mission

A multi-agent AI workforce that functions like a real-world company: 74 specialized agents across 12 divisions, taking projects from concept to production — and from lead to revenue — with systematic precision.

## Memory Layers

| Layer | File | Purpose |
|-------|------|---------|
| Identity & Voice | `CLAUDE.md` (this file) | Project identity, rule index |
| Facts & Canon | `docs/rules/*.md` | Agent roster, SDK rules, skill maps |
| Working Notes | `PLAN.md`, `CHANGELOG.md` | Current plan, decisions, session context |

## Rule Files (load on-demand)

| File | Domain | When Loaded |
|------|--------|-------------|
| [organization.md](docs/rules/organization.md) | 74 agents, 12 divisions, full roster | Always (project context) |
| [orchestration.md](docs/rules/orchestration.md) | Delegation, Agent Teams, context compaction | Orchestration & planning |
| [thinking-policies.md](docs/rules/thinking-policies.md) | Reasoning budgets (100–800 tokens) | Agent execution |
| [sdk-compliance.md](docs/rules/sdk-compliance.md) | Opus 4.6 features, server tools, strict mode | SDK & API integration |
| [agent-selection.md](docs/rules/agent-selection.md) | Division guide, invocation patterns, v3.7 features | Task delegation |
| [skills-integration.md](docs/rules/skills-integration.md) | Skills vs agents, progressive disclosure, agent-skill map | Skills usage |
| [standards.md](docs/rules/standards.md) | Agent frontmatter spec, doc standards, tool use | Agent development |

## Organizational Structure

**74 agents across 12 divisions** — see [organization.md](docs/rules/organization.md) for the full roster.

| Division | Agents | Focus |
|----------|--------|-------|
| 00_Executive_Wing | 2 | Leadership & strategic direction |
| 01_Strategy_and_Planning_Wing | 5 | Strategic planning & architecture |
| 02_Project_Management_Office | 1 | Agile delivery & process management |
| 03_Engineering_Division | 31 | Development & technical implementation |
| 04_Quality_Assurance_Battalion | 4 | Quality assurance & testing |
| 05_SecOps_and_Infrastructure | 9 | Security, operations & infrastructure |
| 06_AI_and_ML_Division | 5 | AI, ML & data engineering |
| 07_Orchestrators | 3 | System coordination & integration |
| 08_Mobile_Development_Wing | 3 | Native & cross-platform mobile |
| 09_Construction_Industry | 1 | Construction industry AI orchestration |
| 10_Content_and_Localization | 4 | Publishing, books & multilingual localization |
| 11_Business_Development | 6 | BD pipeline, proposals, market strategy & social media |

## Skills System

**31 custom skills** + 9 official Anthropic skills with progressive disclosure (3-level loading). Framework specialists preload matching skills via `skills:` frontmatter. See [skills-integration.md](docs/rules/skills-integration.md) and [SKILLS.md](SKILLS.md).

`silent-failure-audit` skill loads automatically on `code-reviewer`, `cyber-sentinel`, `qa-engineer`, and `automated-test-scripter` — no per-project config needed.

`semgrep-sast` skill integrates with the Semgrep MCP plugin for automated SAST scanning. Preloaded on `cyber-sentinel`, `code-reviewer`, `qa-engineer`, `automated-test-scripter`, and `devops-engineer`.

`pipeline-quality` and `pipeline-full-build` skills provide universal, stack-adaptive quality gates and full build pipelines (desktop + cloud variants). Preloaded on `code-reviewer`, `qa-engineer`, and `devops-engineer`.

## Official Plugin Integrations (v3.7.0)

Deploy scripts auto-detect and offer to configure official Anthropic plugins: GitHub, Slack, Jira, Linear, Figma, Sentry, Vercel, Firebase, Supabase, Notion, Confluence, Asana. See [orchestration.md](docs/rules/orchestration.md) for agent-plugin mapping.

## Agent Teams (Experimental)

Enable with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Parallel multi-agent coordination with shared task lists, direct inter-agent messaging, and hooks (`TeammateIdle`, `TaskCreated`, `TaskCompleted`). See [orchestration.md](docs/rules/orchestration.md).

## New Subagent Features (v3.7.0)

- `maxTurns`: Cap agentic turns per subagent for cost control
- `isolation: worktree`: Git worktree isolation for parallel development
- MCP Elicitation: Servers can request user input mid-workflow
- Hook `if` field (v2.1.85+): Permission-rule syntax for fine-grained filtering
- LSP servers in plugins: `.lsp.json` for language server protocol integrations

## Setup & Usage

See [README.md](README.md) for installation, deployment, quick-start examples, and troubleshooting.
