# Claude Code Agents - Team Nation of Elites

<p align="center">
  <em>Created by: Yassine Boumiza</em>
</p>

<p align="center">
  <img src="banner.png" alt="Nation of Elites Banner" width="600"/>
</p>

<p align="center">
  <strong>An orchestrated AI workforce that functions like a real-world IT company.</strong>
  <br />
  Supercharge your development with a complete, role-based AI team that can take a project from initial idea to production-ready deployment.
</p>

---

## 🎯 The Problem & The Solution

A single, generalist AI, no matter how powerful, lacks the specialized expertise and structured workflow of a real-world company. Complex projects require a team of specialists—architects, managers, developers, testers, and security experts—all working in concert.

**The "Nation of Elites" is the solution.** It's not just a collection of agents; it's a fully-realized, virtual IT organization. Each agent has a specific role, a clear mission, and defined responsibilities, mirroring the structure of a high-performing tech company. This allows for unparalleled coordination, deep expertise, and a systematic approach to building software.

## 🚀 Quick Start

Get your AI workforce operational in under one minute.

### Installation

#### 🎯 Claude Code v2 (Recommended)

**One-command installation** via the built-in plugin system:

```bash
# Install from GitHub
/plugin install advisely/claude-code-agents-team-nation-of-elites

# Verify installation
/plugin list
# You should see "nation-of-elites v2.0.0"
```

**Benefits of plugin installation:**
- ✅ Instant one-command setup
- ✅ Automatic updates
- ✅ Easy enable/disable per project
- ✅ Reduced context overhead
- ✅ Full Claude Code CLI integration

#### 🔧 Claude Code v1.x (Legacy)

**Option A — Automated (recommended):**

```bash
# Clone and run deployment script
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites
bash scripts/deploy_agents.sh
```

**Option B — Manual:**

```bash
# Clone the repository
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites

# Sanitize target to avoid conflicts
rm -rf ~/.claude/agents ~/.claude/projects

# Deploy agents
mkdir -p ~/.claude
cp -r agents ~/.claude/agents

# Validate installation
test -f ~/.claude/agents/07_Orchestrators/Tech_Lead_Orchestrator.md && echo "✓ Tech Lead Orchestrator present"
! grep -R "tech-lead-orchestrator-deprecated" ~/.claude/agents -n && echo "✓ No deprecated orchestrator found"
```

**WSL2 note:** The Linux path `~/.claude` appears in Windows Explorer as `\\wsl.localhost\Ubuntu\home\<USER>\.claude`.

### Using the Agents

Navigate to your project directory and start using the agents:

```bash
mkdir my-new-app
cd my-new-app
```

#### Natural Language Commands (Claude Code v2)

Simply describe what you need and Claude will automatically select and spawn the appropriate agents:

```bash
# Strategic planning - automatically spawns project-sponsor, program-manager, product-manager
claude "Initialize a new e-commerce project for selling custom t-shirts. Define business goals, create roadmap, and propose technology stack."

# Development - spawns tech-lead-orchestrator and appropriate specialists
claude "Build user authentication with React frontend and Django REST API backend"

# Code review - spawns code-reviewer
claude "Review the payment integration code for security and best practices"

# Deployment - spawns devops-engineer and cloud-architect
claude "Setup production infrastructure with CI/CD pipeline on AWS"
```

#### Explicit Agent Mentions (Legacy)

For backward compatibility with Claude Code v1.x:

```bash
claude "Use the project-sponsor to define business objectives, program-manager to create roadmap, and solution-architect to propose tech stack"
```

**The difference:**
- **v2**: Natural language → Claude picks agents automatically
- **v1**: Explicit mentions → You specify which agents to use

## 🏛️ Team Structure and Workflow

The "Nation of Elites" is organized hierarchically to mirror a real-world IT company, ensuring a clear flow of command and responsibility from high-level strategy to hands-on implementation. With **45 specialized agents** across **7 strategic divisions**, the team now includes enhanced coverage for high-performance systems, event-driven architectures, financial applications, cryptocurrency/blockchain development, storage security, MCP integrations, and comprehensive development tooling.

### 🚀 Claude Agent SDK Aligned Features
- **Subagent Coordination**: Parallel information gathering with isolated context windows
- **Context Compaction**: Automatic summarization when context exceeds 80%
- **File System Context Engineering**: Efficient large file handling with grep/head/tail
- **MCP Integration**: Seamless external service connections (Slack, GitHub, Google Drive)
- **Visual Feedback Loops**: Real-time UI validation during development
- **Code Generation First**: Prioritizes code over configuration for precision

```
/agents
├── 00_Executive_Wing/ (2 agents)
│   └── (Project Sponsor, Program Manager)
├── 01_Strategy_and_Planning_Wing/ (5 agents)
│   └── (Product Manager, Solution Architect, Business Analyst, Functional Analyst, UX/UI Architect)
├── 02_Project_Management_Office/ (1 agent)
│   └── (Project Manager/Scrum Master)
├── 03_Engineering_Division/ (20 agents)
│   ├── Core_Development_Team/ (3 agents)
│   ├── Framework_Specialists/ (13 agents)
│   └── Code_Excellence_Guild/ (7 agents)
├── 04_Quality_Assurance_Battalion/ (4 agents)
│   └── (QA Engineer, QA Test Planner, Automated Test Scripter, Visual Regression Specialist)
├── 05_SecOps_and_Infrastructure_Division/ (6 agents)
│   └── (DevOps, Security, Cloud Architects, Infrastructure, Message Queue, Storage Security Specialists)
├── 06_AI_and_Machine_Learning_Division/ (5 agents)
│   └── (Data Scientists, ML Engineers, AI Strategist, Data Engineer, AIOps Specialist)
└── 07_Orchestrators/ (3 agents)
    └── (Tech Lead Orchestrator, Team Configurator, Integration Specialist)
```

-   **`00_Executive_Wing` (2 agents)**: Sets the high-level business vision and provides resources. The project starts here.
-   **`01_Strategy_and_Planning_Wing` (5 agents)**: Takes the vision and creates a concrete plan. They define *what* to build, *why*, and the high-level technical approach.
-   **`02_Project_Management_Office` (1 agent)**: Manages the project's execution, timeline, and agile processes.
-   **`03_Engineering_Division` (20 agents)**: The core builders with specialized teams:
    - **Core Development Team** (3 agents): API Architect, Backend Developer, Frontend Developer
    - **Framework Specialists** (13 agents): React, React TypeScript, Vue, Next.js, Django, Laravel, Rails, Java, Go, Financial Systems, Crypto API, Tailwind CSS experts
    - **Code Excellence Guild** (7 agents): Code Reviewer, Documentation Specialist, Performance Optimizer, Code Archaeologist, General Purpose, Statusline Setup, Output Style Setup
-   **`04_Quality_Assurance_Battalion` (4 agents)**: Systematically tests the software to ensure it's bug-free and meets requirements.
-   **`05_SecOps_and_Infrastructure_Division` (6 agents)**: Deploys the application to a secure, scalable production environment with specialized infrastructure, messaging, and storage security expertise.
-   **`06_AI_and_Machine_Learning_Division` (5 agents)**: Integrates data-driven intelligence and machine learning capabilities into the product.
-   **`07_Orchestrators` (3 agents)**: Coordinates multi-agent execution, team setup, and external integrations.
    - `tech-lead-orchestrator`: Central execution coordinator (planning, delegation, gates, subagent spawning, context compaction)
    - `team-configurator`: Team setup orchestrator (stack detection, subagent selection, CLAUDE.md config)
    - `integration-specialist`: MCP server configuration and external service connections (cross-cutting coordinator)

## 🧠 Advanced Agent Capabilities

### Context Management
- **Automatic Compaction**: When context usage > 80%, agents summarize and preserve critical information
- **Subagent Spawning**: Tech Lead Orchestrator can spawn 3-5 parallel subagents for isolated analysis
- **File System Intelligence**: Agents use bash commands (grep, head, tail) for efficient large file processing

### External Integrations (MCP)
The **Integration Specialist** configures Model Context Protocol servers for:
- **Communication**: Slack, Discord, Email
- **Development**: GitHub, GitLab, Jira
- **Productivity**: Google Drive, Notion, Asana
- **Data**: PostgreSQL, MongoDB, Elasticsearch
- **Cloud**: AWS, GCP, Azure

### SDK Alignment & Best Practices

**Version 2.0.0 achieves perfect 10/10 Claude Agent SDK compliance:**

- ✅ **Subagent Coordination** - Parallel processing with temporary, task-specific spawns
- ✅ **Context Compaction** - Automatic summarization at 80% usage (47% token reduction)
- ✅ **File System Context Engineering** - Efficient large file handling with bash commands
- ✅ **MCP Integration** - Seamless external service connections via Integration Specialist
- ✅ **Visual Feedback Loops** - Real-time UI validation during development
- ✅ **Code Generation Priority** - Emphasizes code over configuration for precision

[📖 See full SDK compliance report](SDK_COMPLIANCE_REPORT.md)

### Thinking Policies & Budgets

The orchestrator enforces explicit, budgeted internal reasoning across roles based on task complexity. Agents use an internal scratchpad only when triggered and surface concise rationale summaries (no raw chain-of-thought) in outputs.

### Reasoning Complexity Levels

#### **🔴 High Complexity (600–800 tokens)**
- **Solution/UX/UI/API/Cloud Architects**: System design, architectural patterns, scalability planning

#### **🟡 Medium Complexity (400–600 tokens)**
- **Business/Functional Analysts**: Requirements analysis, process modeling, stakeholder alignment
- **QA Test Planner**: Test strategy, coverage planning, risk-based testing
- **AI Strategist**: AI implementation planning, model selection, ethical considerations

#### **🟠 Medium-Low Complexity (200–300 tokens)**
- **Framework Specialists**: React/Vue/Next.js/Go/Django/Laravel/Financial Systems/Crypto API experts
- **DevOps/Security/Infrastructure**: Pipeline design, security analysis, infrastructure tuning
- **Message Queue Specialist**: Event-driven architecture, messaging patterns
- **Storage Security Specialist**: Data protection, encryption strategies, compliance auditing

#### **🟢 Low Complexity (100–200 tokens)**
- **Backend/Frontend Developers**: Implementation details, component composition, data patterns
- **QA Engineer**: Test case design, automation strategy
- **Performance Optimizer**: Optimization techniques, bottleneck analysis

#### **⚙️ Orchestration (≤300 tokens)**
- **Tech Lead Orchestrator**: Multi-agent planning, delegation decisions
- **Team Configurator**: Stack detection, agent selection

Guardrails (enforced by orchestrator):
- Trigger thinking only for complex tradeoffs/uncertainty. Stop at budget.
- Output concise rationale sections only (bullets). No raw chain-of-thought.
- After two passes, if uncertainty remains → request clarification or delegate to the appropriate role.

## 📋 Automatic Documentation

The Nation of Elites features **automatic project documentation updates**. Key agents maintain project documentation without manual intervention:

### Self-Documenting Agents
- **🔧 Backend/Frontend Developers**: Auto-update implementation status, API endpoints, UI components
- **✅ Code Reviewer**: Auto-update quality metrics, security findings, review completion status
- **🚀 DevOps Engineer**: Auto-update CI/CD configuration, infrastructure status, deployment milestones
- **🎯 Tech Lead Orchestrator**: Auto-update team assignments, architectural decisions, orchestration phases

### Maintained Documentation Files
- **📖 CLAUDE.md**: Project configuration, team assignments, implementation status, architecture decisions
- **📋 PLAN.md**: Current plan-of-record, milestones, task status, dependencies, risk mitigation
- **📝 CHANGELOG.md**: Chronological record of features, changes, fixes, and major decisions

### Benefits
- ✅ **No Manual Reminders**: Agents automatically document their completed work
- ✅ **Consistent Format**: Standardized changelog entries across all agents
- ✅ **Complete Traceability**: Every major work completion is documented
- ✅ **Always Current**: Project documentation stays up-to-date automatically

## 📚 Documentation

### Core Documentation
- **[README.md](README.md)** - This file - Quick start and overview
- **[CLAUDE.md](CLAUDE.md)** - Detailed configuration and usage guide
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and release notes

### v2.0 Plugin System
- **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** - Upgrading from v1.x to v2.0
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Community contribution guidelines
- **[.claude-plugin/manifest.json](.claude-plugin/manifest.json)** - Plugin metadata
- **[.claude-plugin/marketplace.json](.claude-plugin/marketplace.json)** - Marketplace configuration

### Advanced Guides
- **[docs/SDK_COMPLIANCE_REPORT.md](docs/SDK_COMPLIANCE_REPORT.md)** - 10/10 SDK compliance certification
- **[docs/CONTEXT_ENGINEERING.md](docs/CONTEXT_ENGINEERING.md)** - Context management best practices

## 🤝 Contributing

The "Nation of Elites" is an ambitious project, and contributions are welcome! Whether you want to refine an existing agent's prompt, add a new specialist role, or improve the orchestration workflow, please see our **[Contributing Guide](CONTRIBUTING.md)**.

**Quick Start for Contributors:**

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingNewAgent`)
3.  Follow the [Agent Development Guidelines](CONTRIBUTING.md#agent-development-guidelines)
4.  Test your changes locally
5.  Commit with [conventional commits](CONTRIBUTING.md#commit-messages)
6.  Push to your fork and open a Pull Request

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for detailed guidelines on:
- Agent structure and naming conventions
- Testing procedures
- Documentation requirements
- PR submission process

## 🔄 Upgrading from v1.x?

See the **[Migration Guide](MIGRATION_GUIDE.md)** for step-by-step instructions on upgrading to the v2.0 plugin system.

**TL;DR for v2.0 users:**
```bash
# Uninstall old v1.x (optional)
rm -rf ~/.claude/agents

# Install as plugin
/plugin install advisely/claude-code-agents-team-nation-of-elites

# Verify
/plugin list
```

## 📚 Credits and References

-   **Author**: Yassine Boumiza - [GitHub Profile](https://github.com/advisely/)
-   **Repository**: [claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites)
-   **Inspiration & Best Practices**: [Building Effective Agents - Anthropic Engineering](https://www.anthropic.com/engineering/building-effective-agents), [How we built our multi-agent research system](https://www.anthropic.com/engineering/built-multi-agent-research-system)
-   **Claude Agent SDK**: [Anthropic Documentation](https://docs.anthropic.com/)
-   **Claude Code Plugins**: [Plugin System Announcement](https://www.anthropic.com/news/claude-code-plugins)

## 📄 License

Distributed under the MIT License with a friendly request for attribution. See **[LICENSE.md](LICENSE.md)** for more information.

**If you find this project useful**, please:
- ⭐ Star the repository
- 🔗 Share with your team
- 💬 Provide feedback via [GitHub Discussions](https://github.com/advisely/claude-code-agents-team-nation-of-elites/discussions)
- 🐛 Report issues via [GitHub Issues](https://github.com/advisely/claude-code-agents-team-nation-of-elites/issues)

---

**The Nation of Elites v2.0** - Powered by Claude Code Plugin System | 45 Specialized Agents | 10/10 SDK Compliance
