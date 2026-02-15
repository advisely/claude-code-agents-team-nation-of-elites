# Claude Code CLI Project Configuration - Nation of Elites

## Project Overview

**Project Name:** Claude Code Agents - Team Nation of Elites  
**Author:** Yassine Boumiza ([boumiza.com](https://boumiza.com))
**Repository:** [claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites)

### Mission Statement

The "Nation of Elites" is a comprehensive multi-agent AI workforce that functions like a real-world IT company. This orchestrated system provides specialized expertise and structured workflows that mirror high-performing tech organizations, enabling projects to go from initial concept to production-ready deployment with systematic precision.

### Core Philosophy

A single generalist AI lacks the specialized expertise and structured workflow of a real-world company. Complex projects require a team of specialists—architects, managers, developers, testers, and security experts—all working in concert. The Nation of Elites solves this by providing a fully-realized virtual IT organization with defined roles, responsibilities, and coordination patterns.

## Modular Rules Architecture

> **Best Practice (Feb 2026):** Per Anthropic's latest guidance, rules are organized into modular files (50-100 lines each), loaded on-demand based on task context. This reduces context window usage and prevents hallucination.

### Rule Files Index

| Rule File | Domain | When Loaded |
|-----------|--------|-------------|
| [organization.md](docs/rules/organization.md) | Division structure, agent roster (63 agents, 10 divisions) | Always (project context) |
| [orchestration.md](docs/rules/orchestration.md) | Agent Teams, subagent coordination, context compaction, adaptive thinking | Orchestration & planning tasks |
| [thinking-policies.md](docs/rules/thinking-policies.md) | Reasoning budgets (100-800 tokens), guardrails per role | Agent execution |
| [sdk-compliance.md](docs/rules/sdk-compliance.md) | Claude Agent SDK alignment, Opus 4.6 features, server tools | SDK & API integration |
| [agent-selection.md](docs/rules/agent-selection.md) | Division selection guide, invocation patterns, workflows | Task delegation |
| [skills-integration.md](docs/rules/skills-integration.md) | Skills vs agents, progressive disclosure, agent-skill mapping | Skills usage |
| [standards.md](docs/rules/standards.md) | Agent format, documentation standards, strict tool use | Agent development |

### Memory Pattern (Structured)

Following Anthropic's three-category memory pattern:

| Category | Description | Example |
|----------|-------------|---------|
| **Identity & Voice** | Static project identity | Mission, org structure, author |
| **Facts & Canon** | Semi-static tech knowledge | Agent roster, skill mappings, SDK alignment |
| **Working Notes** | Rolling session context | Current plan, decisions, pending items |

CLAUDE.md serves as the **Identity & Voice** layer. Rule files serve as **Facts & Canon**. Project-specific `PLAN.md` and `CHANGELOG.md` serve as **Working Notes**.

## Organizational Structure

The Nation of Elites consists of **63 specialized agents** organized across **10 divisions**. See [organization.md](docs/rules/organization.md) for the full agent roster.

**Divisions at a glance:**

| Division | Agents | Focus |
|----------|--------|-------|
| 00_Executive_Wing | 2 | Leadership & strategic direction |
| 01_Strategy_and_Planning_Wing | 5 | Strategic planning & architecture |
| 02_Project_Management_Office | 1 | Agile delivery & process management |
| 03_Engineering_Division | 25 | Development & technical implementation |
| 04_Quality_Assurance_Battalion | 4 | Quality assurance & testing |
| 05_SecOps_and_Infrastructure | 9 | Security, operations & infrastructure |
| 06_AI_and_ML_Division | 5 | AI, ML & data engineering |
| 07_Orchestrators | 3 | System coordination & integration |
| 08_Mobile_Development_Wing | 3 | Native & cross-platform mobile |
| 09_Construction_Industry | 1 | Construction industry AI orchestration |

## Agent Skills Integration (v3.2)

**27 custom skills** + 9 official Anthropic skills using progressive disclosure (3-level loading). See [skills-integration.md](docs/rules/skills-integration.md) and [SKILLS.md](SKILLS.md) for details.

## Configuration and Setup

### Installation

#### 🚀 Recommended: Automated Deployment (Works Immediately)

```bash
# Clone repository
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git

# Navigate to directory
cd claude-code-agents-team-nation-of-elites

# Run automated deployment
bash scripts/deploy_agents.sh
```

This script:
- Copies agents to `~/.claude/agents/`
- Validates installation
- Ensures all 61 agents are ready to use

#### 🔌 Alternative: Plugin Installation

**For Claude Code v2.0+ with plugin system**:

```bash
# Step 1: Add the GitHub marketplace source
/marketplace add advisely/claude-code-agents-team-nation-of-elites

# Step 2: Install the plugin from marketplace
/plugin install nation-of-elites

# Step 3: Verify installation
/plugin list
# Should show: "nation-of-elites v2.0.0"
```

**Alternative**: Clone directly to plugins directory (bypasses marketplace):

```bash
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git ~/.claude/plugins/nation-of-elites
/plugin list  # Verify it appears
```

**Note**: The marketplace must be added **before** installing the plugin, otherwise `/plugin install` will fail with "Marketplace not found".

Plugin benefits:
- ✅ Integrated with plugin system
- ✅ Easy enable/disable per project
- ✅ Automatic updates (when marketplace is live)
- ✅ Reduced context overhead

#### 🔧 Manual Installation

```bash
# Clone the repository
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites

# Sanitize target to avoid conflicts with older configurations
rm -rf ~/.claude/agents ~/.claude/projects

# Deploy current agents set
mkdir -p ~/.claude
cp -r agents ~/.claude/agents

# Validate key files
test -f ~/.claude/agents/07_Orchestrators/Tech_Lead_Orchestrator.md && echo "Tech Lead Orchestrator present"
! grep -R "tech-lead-orchestrator-deprecated" ~/.claude/agents -n && echo "No deprecated orchestrator found"
```

#### 🤖 Automated Deployment Script

```bash
# From the repository root
bash scripts/deploy_agents.sh
```

The script will:
- Clone/pull the repo (if needed)
- Remove `~/.claude/agents` and `~/.claude/projects`
- Copy `agents/` into `~/.claude/agents`
- Validate presence of canonical orchestrator and absence of deprecated entries

**WSL2 note**: The Linux path `~/.claude` corresponds in Windows Explorer to `\\wsl.localhost\Ubuntu\home\<USER>\.claude`.

### Verification

```bash
# List installed plugins
/plugin list

# Check for Nation of Elites
# You should see "nation-of-elites v2.0.0" in the list
```

### Quick Start

```bash
# Strategic planning - spawns project-sponsor and program-manager
claude "Define objectives and create roadmap for a mobile payment app"

# Development coordination - spawns tech-lead-orchestrator
claude "Coordinate development of user authentication feature with React frontend and Django backend"

# Quality assurance - spawns qa-test-planner and automated-test-scripter
claude "Create comprehensive test strategy and implement automated tests"

# Infrastructure - spawns devops-engineer and cloud-architect
claude "Setup CI/CD pipeline and design cloud infrastructure for production deployment"

# Unreal Engine 5 - spawns unreal-engine-expert
claude "Build a multiplayer open-world game with Nanite environments, GAS ability system, and dedicated server replication"
```

See [agent-selection.md](docs/rules/agent-selection.md) for complete invocation patterns and advanced usage.

## Troubleshooting

1. **Agent Not Found** - Ensure agents are properly installed in `~/.claude/agents/`
2. **Unclear Context** - Provide clear context when delegating between agents
3. **Role Confusion** - Use the organizational structure to identify the right agent
4. **Complex Projects** - Start with executive agents and work down the hierarchy

## Support and Contribution

- **GitHub Repository**: [claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites)
- **Author**: Yassine Boumiza - [boumiza.com](https://boumiza.com) | [GitHub Profile](https://github.com/advisely/)
- **License**: MIT License with attribution request

### Contribution Guidelines

1. Fork the repository
2. Create feature branch (`git checkout -b feature/NewAgent`)
3. Follow agent format standards (see [standards.md](docs/rules/standards.md))
4. Add comprehensive testing
5. Submit pull request with clear description

---

**The Nation of Elites represents the future of AI-assisted development - a complete, coordinated workforce that brings enterprise-level capabilities to any project scale.**
