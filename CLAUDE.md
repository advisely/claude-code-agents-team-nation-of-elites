# Claude Code CLI Project Configuration - Nation of Elites

**Project:** Claude Code Agents - Team Nation of Elites
**Author:** Yassine Boumiza ([boumiza.com](https://boumiza.com))
**Repo:** [advisely/claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites)

## Mission

A multi-agent AI workforce that functions like a real-world company: 74 specialized agents across 12 divisions, taking projects from concept to production — and from lead to revenue — with systematic precision.

## Memory Layers

| Layer | File | Purpose |
|-------|------|---------|
| Identity & Voice | `CLAUDE.md` (this file) | Project identity, rule index — keep it a pointer file |
| Facts & Canon | `docs/rules/*.md` | Agent roster, SDK rules, skill maps, release process |
| Working Notes | `PLAN.md`, `CHANGELOG.md` | Current plan, decisions, session context |

## Rule Files (load on-demand)

| File | Domain | When Loaded |
|------|--------|-------------|
| [organization.md](docs/rules/organization.md) | 74 agents, 12 divisions, full roster | Always (project context) |
| [orchestration.md](docs/rules/orchestration.md) | Delegation, Agent Teams, `/loop`, Cowork, official plugins, Opus/Sonnet 5.5 steering | Orchestration & planning |
| [thinking-policies.md](docs/rules/thinking-policies.md) | Reasoning budgets, effort defaults | Agent execution |
| [sdk-compliance.md](docs/rules/sdk-compliance.md) | Model aliases, tier split, breaking changes, server tools, provider pinning | SDK & API integration |
| [agent-selection.md](docs/rules/agent-selection.md) | Division guide, invocation patterns | Task delegation |
| [skills-integration.md](docs/rules/skills-integration.md) | Skills vs agents, agent-skill map | Skills usage |
| [standards.md](docs/rules/standards.md) | Agent frontmatter spec, doc standards, tool use | Agent development |
| [release-process.md](docs/rules/release-process.md) | Release checklist, deploy verification, lessons learned | Releasing & deploying |

## Organizational Structure

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

## Model & Tier Policy

- **Aliases only** in frontmatter: `opus` → `claude-opus-5-5`, `sonnet` → `claude-sonnet-5-5` (Claude Code ≥ v2.1.284). Roster: **21 `opus` / 53 `sonnet`**. Never `haiku`.
- **`opus`** for orchestration, architecture, security, code review, executive/strategy judgment; **`sonnet`** for well-scoped execution and templated deliverables. Opus 5.5 costs 2× Sonnet 5.5 per token.
- **No `effort:` frontmatter** without measured evidence — both tiers default to `medium` in Claude Code; thinking can't be turned off on either.
- **Third-party providers don't move aliases** — pin `ANTHROPIC_DEFAULT_SONNET_MODEL` (and `ANTHROPIC_DEFAULT_OPUS_MODEL` on Foundry). The deploy scripts warn when unpinned.
- **Never ask an agent to print its reasoning** (`reasoning_extraction` refusals).

Details, breaking changes, and re-test criteria: [sdk-compliance.md](docs/rules/sdk-compliance.md). Steering: [orchestration.md](docs/rules/orchestration.md).

## Skills & Plugins

**33 custom skills** + 9 official Anthropic skills with 3-level progressive disclosure; specialists preload skills via `skills:` frontmatter. `pipeline-quality` is the single pre-merge gate; `pipeline-full-build-cloud` / `-desktop` are standalone release chains. See [SKILLS.md](SKILLS.md) and [skills-integration.md](docs/rules/skills-integration.md); official plugin integrations are in [orchestration.md](docs/rules/orchestration.md).

## Surfaces

Runs in Claude Code (CLI / Desktop / IDE) and Claude Cowork. Skills (33) and slash commands also work in plain chat; agents and hooks need Claude Code or Cowork. See [orchestration.md](docs/rules/orchestration.md) → *Claude Cowork*.

## Setup & Release

Install and usage: [README.md](README.md). Deploy locally with `bash scripts/deploy_agents.sh` (WSL/Linux/macOS) or `scripts/deploy_agents.ps1` (Windows). Release checklist and lessons learned: [release-process.md](docs/rules/release-process.md).
