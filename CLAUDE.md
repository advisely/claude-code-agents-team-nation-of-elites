# Claude Code CLI Project Configuration - Nation of Elites

**Project:** Claude Code Agents - Team Nation of Elites
**Author:** Yassine Boumiza ([boumiza.com](https://boumiza.com))
**Repo:** [advisely/claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites)

## Mission

A multi-agent AI workforce that functions like a real-world IT company: 64 specialized agents across 10 divisions, taking projects from concept to production with systematic precision.

## Memory Layers

| Layer | File | Purpose |
|-------|------|---------|
| Identity & Voice | `CLAUDE.md` (this file) | Project identity, rule index |
| Facts & Canon | `docs/rules/*.md` | Agent roster, SDK rules, skill maps |
| Working Notes | `PLAN.md`, `CHANGELOG.md` | Current plan, decisions, session context |

## Rule Files (load on-demand)

| File | Domain | When Loaded |
|------|--------|-------------|
| [organization.md](docs/rules/organization.md) | 64 agents, 10 divisions, full roster | Always (project context) |
| [orchestration.md](docs/rules/orchestration.md) | Delegation, Agent Teams, context compaction | Orchestration & planning |
| [thinking-policies.md](docs/rules/thinking-policies.md) | Reasoning budgets (100–800 tokens) | Agent execution |
| [sdk-compliance.md](docs/rules/sdk-compliance.md) | Opus 4.6 features, server tools, strict mode | SDK & API integration |
| [agent-selection.md](docs/rules/agent-selection.md) | Division guide, invocation patterns, v3.4 features | Task delegation |
| [skills-integration.md](docs/rules/skills-integration.md) | Skills vs agents, progressive disclosure, agent-skill map | Skills usage |
| [standards.md](docs/rules/standards.md) | Agent frontmatter spec, doc standards, tool use | Agent development |

## Organizational Structure

**64 agents across 10 divisions** — see [organization.md](docs/rules/organization.md) for the full roster.

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

## Skills System

**28 custom skills** + 9 official Anthropic skills with progressive disclosure (3-level loading). Framework specialists preload matching skills via `skills:` frontmatter. See [skills-integration.md](docs/rules/skills-integration.md) and [SKILLS.md](SKILLS.md).

`silent-failure-audit` skill loads automatically on `code-reviewer`, `cyber-sentinel`, `qa-engineer`, and `automated-test-scripter` — no per-project config needed.

## Setup & Usage

See [README.md](README.md) for installation, deployment, quick-start examples, and troubleshooting.
