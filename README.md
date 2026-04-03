<div align="center">

# Claude Code Agents - Team Nation of Elites

<img src="banner_v2.jpeg" alt="Nation of Elites Banner" width="600"/>

**An orchestrated AI workforce that functions like a real-world company.**

Supercharge your work with a complete, role-based AI team that takes projects from concept to production — and from lead to revenue.

[![Agents](https://img.shields.io/badge/agents-74-blueviolet?style=for-the-badge&logo=robot&logoColor=white)](agents/)
[![Divisions](https://img.shields.io/badge/divisions-12-blue?style=for-the-badge&logo=sitemap&logoColor=white)](docs/rules/organization.md)
[![Skills](https://img.shields.io/badge/skills-31-green?style=for-the-badge&logo=bookopen&logoColor=white)](SKILLS.md)
[![SDK](https://img.shields.io/badge/SDK_compliance-10%2F10-brightgreen?style=for-the-badge&logo=checkmarx&logoColor=white)](docs/SDK_COMPLIANCE_REPORT.md)
[![License](https://img.shields.io/badge/license-MIT-orange?style=for-the-badge&logo=opensourceinitiative&logoColor=white)](LICENSE.md)
[![Version](https://img.shields.io/badge/version-3.8.0-red?style=for-the-badge&logo=semanticrelease&logoColor=white)](CHANGELOG.md)

*Created by [Yassine Boumiza](https://boumiza.com)*

[Quick Start](#-quick-start) | [Agent Roster](#-complete-agent-roster-by-department) | [Skills](#-agent-skills-system) | [Docs](#-documentation) | [Contributing](#-contributing)

</div>

---

## The Problem & The Solution

A single, generalist AI, no matter how powerful, lacks the specialized expertise and structured workflow of a real-world company. Complex projects require a team of specialists -- architects, managers, developers, testers, and security experts -- all working in concert.

**The "Nation of Elites" is the solution.** It's not just a collection of agents; it's a fully-realized, virtual IT organization. Each agent has a specific role, a clear mission, and defined responsibilities, mirroring the structure of a high-performing tech company.

---

## Platform Compatibility

Agents are platform-independent `.md` files -- they work identically on **Windows**, **Linux**, **macOS**, and **WSL2**.

| Interface | Supported | Config Path |
|:---|:---:|:---|
| Claude Code CLI (terminal) | Yes | `~/.claude/agents/` |
| VS Code + Claude Code extension | Yes | `~/.claude/agents/` |
| JetBrains + Claude Code extension | Yes | `~/.claude/agents/` |

---

## Quick Start

Get your AI workforce operational in under one minute.

### Prerequisites

| Platform | Requirement |
|:---|:---|
| **Windows** | [Git for Windows](https://git-scm.com/downloads/win) |
| **Linux / WSL2** | `git`, `rsync` |
| **macOS** | `git` (included with Xcode CLI tools) |

### Step 1: Install Claude Code

<details>
<summary><strong>Linux / macOS / WSL2</strong></summary>

```bash
# npm (if Node.js is installed)
npm install -g @anthropic-ai/claude-code

# Or use the official installer
curl -fsSL https://claude.ai/install.sh | sh
```

</details>

<details>
<summary><strong>Windows (native)</strong></summary>

```powershell
# PowerShell (recommended)
irm https://claude.ai/install.ps1 | iex

# Or via WinGet
winget install Anthropic.ClaudeCode
```

**Git for Windows is required.** If using a portable Git, set:

```powershell
$env:CLAUDE_CODE_GIT_BASH_PATH = "C:\Program Files\Git\bin\bash.exe"
```

</details>

Verify with `claude doctor`.

### Step 2: Deploy the Agents

#### Automated Deployment (Recommended)

<details>
<summary><strong>Linux / macOS / WSL2 (Bash)</strong></summary>

```bash
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites
bash scripts/deploy_agents.sh
```

**Done!** All 64 agents are now in `~/.claude/agents/` and ready to use.

**WSL2 note:** The path `~/.claude` appears in Windows Explorer as `\\wsl.localhost\Ubuntu\home\<USER>\.claude`.

</details>

<details>
<summary><strong>Windows (PowerShell)</strong></summary>

```powershell
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites
powershell -ExecutionPolicy Bypass -File scripts\deploy_agents.ps1
```

**Done!** All 64 agents are now in `%USERPROFILE%\.claude\agents\` and ready to use.

</details>

#### Plugin Installation (Alternative)

```bash
# Install as a Claude Code plugin
/plugin install nation-of-elites@claude-plugins-official

# Or clone directly to plugins directory
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git ~/.claude/plugins/nation-of-elites
```

#### Manual Installation

<details>
<summary><strong>Linux / macOS / WSL2</strong></summary>

```bash
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites
mkdir -p ~/.claude && cp -r agents ~/.claude/agents
```

</details>

<details>
<summary><strong>Windows (PowerShell)</strong></summary>

```powershell
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\agents" | Out-Null
Copy-Item -Recurse -Force agents\* "$env:USERPROFILE\.claude\agents\"
```

</details>

### Using the Agents

```bash
cd my-project

# Strategic planning - auto-spawns project-sponsor, program-manager, product-manager
claude "Initialize a new e-commerce project. Define goals, roadmap, and tech stack."

# Development - spawns chief-operations-orchestrator and specialists
claude "Build user authentication with React frontend and Django REST API backend"

# Code review - spawns code-reviewer with Semgrep SAST
claude "Review the payment integration code for security and best practices"

# Deployment - spawns devops-engineer and cloud-architect
claude "Setup production infrastructure with CI/CD pipeline on AWS"
```

---

## Complete Agent Roster by Department

<table>
<tr>
<td>

### Executive Office
| | Agent | Role |
|:---:|:---|:---|
| <img width="16" src="https://cdn.simpleicons.org/target/blueviolet"> | `project-sponsor` | Strategic vision, budget, ROI |
| <img width="16" src="https://cdn.simpleicons.org/trello/blueviolet"> | `program-manager` | Portfolio oversight, cross-project |

</td>
<td>

### Strategy & Planning
| | Agent | Role |
|:---:|:---|:---|
| <img width="16" src="https://cdn.simpleicons.org/blueprint/royalblue"> | `business-analyst` | Requirements, gap analysis |
| <img width="16" src="https://cdn.simpleicons.org/diagramsdotnet/royalblue"> | `functional-analyst` | Process modeling, specs |
| <img width="16" src="https://cdn.simpleicons.org/roadmapdotsh/royalblue"> | `product-manager` | Vision, roadmap, priorities |
| <img width="16" src="https://cdn.simpleicons.org/archlinux/royalblue"> | `solution-architect` | Tech architecture, stacks |
| <img width="16" src="https://cdn.simpleicons.org/figma/royalblue"> | `ux-ui-architect` | UX research, interfaces |

</td>
</tr>
</table>

<table>
<tr>
<td>

### Project Management
| | Agent | Role |
|:---:|:---|:---|
| <img width="16" src="https://cdn.simpleicons.org/jirasoftware/teal"> | `project-manager-scrum-master` | Agile delivery, sprints |

</td>
<td>

### Orchestration & Integration
| | Agent | Role |
|:---:|:---|:---|
| <img width="16" src="https://cdn.simpleicons.org/apachekafka/darkorange"> | `chief-operations-orchestrator` | Central coordinator |
| <img width="16" src="https://cdn.simpleicons.org/stackblitz/darkorange"> | `team-configurator` | Stack detection, setup |
| <img width="16" src="https://cdn.simpleicons.org/zapier/darkorange"> | `integration-specialist` | MCP, APIs, OAuth |

</td>
</tr>
</table>

<details>
<summary><strong>Engineering Division - Core Development (4 agents)</strong></summary>

| | Agent | Role | Model |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/swagger/green"> | `api-architect` | REST/GraphQL API design | opus |
| <img width="16" src="https://cdn.simpleicons.org/graphql/green"> | `graphql-architect` | Schemas, federation, subscriptions | opus |
| <img width="16" src="https://cdn.simpleicons.org/fastapi/green"> | `backend-developer` | Server-side APIs, business logic | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/css3/green"> | `frontend-developer` | UI frameworks, responsive design | sonnet |

</details>

<details>
<summary><strong>Engineering Division - Framework Specialists (19 agents)</strong></summary>

**Python & Web Frameworks**

| | Agent | Skills Preloaded | Model |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/django/green"> | `django-expert` | django-patterns | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/laravel/green"> | `laravel-expert` | laravel-patterns | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/rubyonrails/green"> | `rails-expert` | rails-patterns | sonnet |

**JavaScript & Frontend Frameworks**

| | Agent | Skills Preloaded | Model |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/react/green"> | `react-expert` | react-patterns | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/typescript/green"> | `react-typescript-expert` | react-patterns, typescript-patterns | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/vuedotjs/green"> | `vue-expert` | vue-patterns | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/nextdotjs/green"> | `nextjs-expert` | nextjs-patterns | sonnet |

**Backend Languages**

| | Agent | Skills Preloaded | Model |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/spring/green"> | `java-expert` | java-patterns | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/go/green"> | `go-expert` | go-patterns | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/rust/green"> | `rust-expert` | -- | sonnet |

**Data & Finance**

| | Agent | Skills Preloaded | Model |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/postgresql/green"> | `database-expert` | -- | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/bloomberg/green"> | `financial-systems-expert` | financial-trading-patterns | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/bitcoin/green"> | `crypto-api-developer` | crypto-defi-patterns | sonnet |

**UI & Styling**

| | Agent | Skills Preloaded | Model |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/tailwindcss/green"> | `tailwind-css-expert` | tailwind-patterns | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/antdesign/green"> | `antd-ui-developer` | antd-patterns | sonnet |

**CAD, BIM & Game Engines**

| | Agent | Skills Preloaded | Model |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/unrealengine/green"> | `unreal-engine-expert` | -- | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/dassaultsystemes/green"> | `catia-design-expert` | -- | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/autodesk/green"> | `autodesk-cloud-construction-expert` | -- | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/autodesk/green"> | `revit-bim-expert` | -- | sonnet |

</details>

<details>
<summary><strong>Engineering Division - Code Excellence Guild (8 agents)</strong></summary>

| | Agent | Role | Memory |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/codereview/green"> | `code-reviewer` | Security-aware PR reviews | project |
| <img width="16" src="https://cdn.simpleicons.org/files/green"> | `code-archaeologist` | Legacy codebase analysis | project |
| <img width="16" src="https://cdn.simpleicons.org/readthedocs/green"> | `documentation-specialist` | READMEs, API docs, guides | -- |
| <img width="16" src="https://cdn.simpleicons.org/speedtest/green"> | `performance-optimizer` | Bottleneck diagnosis | -- |
| <img width="16" src="https://cdn.simpleicons.org/w3c/green"> | `accessibility-specialist` | WCAG 2.1 AA/AAA | -- |
| <img width="16" src="https://cdn.simpleicons.org/visualstudiocode/green"> | `noe-general-purpose` | Versatile multi-language | -- |
| <img width="16" src="https://cdn.simpleicons.org/gnometerminal/green"> | `noe-statusline-setup` | Terminal/shell config | -- |
| <img width="16" src="https://cdn.simpleicons.org/windowsterminal/green"> | `output-style-setup` | CLI output, ANSI colors | -- |

</details>

<details>
<summary><strong>Quality Assurance Battalion (4 agents)</strong></summary>

| | Agent | Role | Skills |
|:---:|:---|:---|:---|
| <img width="16" src="https://cdn.simpleicons.org/testinglibrary/crimson"> | `qa-test-planner` | Test strategy, case design | -- |
| <img width="16" src="https://cdn.simpleicons.org/pytest/crimson"> | `qa-engineer` | Automated suites, CI/CD | pytest, semgrep, pipeline-quality |
| <img width="16" src="https://cdn.simpleicons.org/selenium/crimson"> | `automated-test-scripter` | Test framework implementation | pytest, semgrep |
| <img width="16" src="https://cdn.simpleicons.org/percy/crimson"> | `visual-regression-specialist` | UI consistency, visual defects | -- |

</details>

<details>
<summary><strong>Security Operations (2 agents)</strong></summary>

| | Agent | Role | Memory |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/snyk/orange"> | `cyber-sentinel` | Vulnerability scanning, audits | project |
| <img width="16" src="https://cdn.simpleicons.org/bitwarden/orange"> | `storage-security-specialist` | Data protection, encryption | -- |

</details>

<details>
<summary><strong>Infrastructure & Platform (7 agents)</strong></summary>

| | Agent | Role | Skills |
|:---:|:---|:---|:---|
| <img width="16" src="https://cdn.simpleicons.org/githubactions/orange"> | `devops-engineer` | CI/CD, automation | github-actions, k8s, semgrep, pipelines |
| <img width="16" src="https://cdn.simpleicons.org/amazonaws/orange"> | `cloud-architect` | Cloud infra, IaC | terraform-patterns |
| <img width="16" src="https://cdn.simpleicons.org/linux/orange"> | `infrastructure-specialist` | Servers, networking | -- |
| <img width="16" src="https://cdn.simpleicons.org/backstage/orange"> | `platform-engineer` | Developer platforms, DevEx | -- |
| <img width="16" src="https://cdn.simpleicons.org/pagerduty/orange"> | `sre-specialist` | SLO/SLI, incident mgmt | -- |
| <img width="16" src="https://cdn.simpleicons.org/grafana/orange"> | `observability-engineer` | Metrics, logs, traces | -- |
| <img width="16" src="https://cdn.simpleicons.org/apachekafka/orange"> | `message-queue-specialist` | Kafka, RabbitMQ, events | -- |

</details>

<details>
<summary><strong>AI & Machine Learning Division (5 agents)</strong></summary>

| | Agent | Role | Model |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/openai/purple"> | `ai-strategist` | AI opportunities, vision | opus |
| <img width="16" src="https://cdn.simpleicons.org/jupyter/purple"> | `data-scientist` | EDA, modeling, ML prototyping | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/apacheairflow/purple"> | `data-engineer` | ETL pipelines, data platforms | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/mlflow/purple"> | `ml-engineer` | MLOps, model productionization | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/datadog/purple"> | `aiops-specialist` | ML model lifecycle, ops health | sonnet |

</details>

<details>
<summary><strong>Mobile Development Wing (3 agents)</strong></summary>

| | Agent | Role | Model |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/android/teal"> | `mobile-architect` | Cross-platform strategy | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/apple/teal"> | `ios-developer` | Swift/SwiftUI, App Store | sonnet |
| <img width="16" src="https://cdn.simpleicons.org/android/teal"> | `android-developer` | Kotlin/Compose, Play Store | sonnet |

</details>

<details>
<summary><strong>Construction Industry Division (1 agent)</strong></summary>

| | Agent | Role | Model |
|:---:|:---|:---|:---:|
| <img width="16" src="https://cdn.simpleicons.org/autodesk/sienna"> | `construction-ai-orchestrator` | IMPARARIA AI-Stimate/Takeoff/Coordinate | sonnet |

</details>

---

## Organization at a Glance

```
agents/
  00_Executive_Wing/           (2)   Strategic vision & portfolio management
  01_Strategy_and_Planning/    (5)   Architecture, requirements, UX design
  02_Project_Management/       (1)   Agile delivery & sprint management
  03_Engineering_Division/    (31)   Core dev + 19 framework specialists + 8 code excellence
  04_Quality_Assurance/        (4)   Testing strategy, automation, visual regression
  05_SecOps_and_Infrastructure/(9)   Security, DevOps, cloud, SRE, observability
  06_AI_and_ML_Division/       (5)   Data science, ML engineering, AIOps
  07_Orchestrators/            (3)   Coordination, team config, MCP integration
  08_Mobile_Development/       (3)   iOS, Android, cross-platform architecture
  09_Construction_Industry/    (1)   Construction AI (IMPARARIA methodology)
                              ----
                               64 agents total
```

---

## Key Capabilities

### Claude Agent SDK Features

| Feature | Description |
|:---|:---|
| **Subagent Coordination** | Parallel processing with isolated context windows |
| **Agent Teams** (experimental) | Multi-agent parallel work with shared task lists (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) |
| **Context Compaction** | Automatic summarization at 80% usage (47% token reduction) |
| **Persistent Memory** | 7 agents retain project knowledge across sessions via `memory: project` |
| **Skills Preloading** | 18 specialists preload matching skills at startup via `skills:` frontmatter |
| **Permission Modes** | 16 code-writing agents use `permissionMode: acceptEdits` for frictionless flow |
| **MCP Integration** | External services (Slack, GitHub, Jira, Figma, Sentry) via Model Context Protocol |
| **Worktree Isolation** | Subagents work in isolated git worktrees for parallel development |
| **Official Plugins** | Auto-detection and setup of Anthropic official plugins (GitHub, Slack, Jira, etc.) |
| **Semgrep SAST** | Automated security scanning via CLI and MCP plugin integration |
| **Universal Pipelines** | Stack-adaptive quality gates and full build pipelines |

### Thinking Policies & Budgets

| Complexity | Tokens | Agents |
|:---|:---:|:---|
| High | 600-800 | Solution, UX/UI, API, Cloud Architects |
| Medium | 400-600 | Business/Functional Analysts, QA Planner, AI Strategist |
| Medium-Low | 200-300 | Framework Specialists, DevOps, Security |
| Low | 100-200 | Backend/Frontend Devs, QA Engineer, Performance |
| Orchestration | <=300 | Tech Lead, Team Configurator |

### Official Plugin Integrations

The deploy script auto-detects and offers to configure these official Anthropic plugins:

| Plugin | Category | Best For |
|:---|:---|:---|
| **GitHub** | Development | code-reviewer, devops-engineer |
| **Slack** | Communication | chief-operations-orchestrator, program-manager |
| **Jira** | Project Management | project-manager-scrum-master, product-manager |
| **Linear** | Project Management | product-manager |
| **Figma** | Design | ux-ui-architect, frontend-developer |
| **Sentry** | Monitoring | sre-specialist, observability-engineer |
| **Vercel** | Deployment | nextjs-expert, devops-engineer |
| **Firebase** | Backend | mobile-architect, backend-developer |
| **Supabase** | Database | database-expert, backend-developer |
| **Notion** | Documentation | documentation-specialist, business-analyst |
| **Confluence** | Documentation | functional-analyst |
| **Asana** | Project Management | program-manager |

---

## Agent Skills System

**31 custom skills** + 9 official Anthropic skills with progressive 3-level loading.

### How Skills Work

| Aspect | Agents | Skills |
|:---|:---|:---|
| **What** | Team members (64 specialists) | Training manuals & toolkits |
| **Where** | `~/.claude/agents/` | `~/.claude/skills/` |
| **Loading** | Task-based spawning | Progressive disclosure |

### Skills Library

<details>
<summary><strong>Official Anthropic Skills (9)</strong></summary>

| Skill | Purpose |
|:---|:---|
| pdf | PDF manipulation, forms, extraction |
| docx | Word document creation/editing |
| pptx | PowerPoint presentations |
| xlsx | Excel with formulas and charts |
| mcp-builder | MCP server development |
| webapp-testing | Playwright UI testing |
| skill-creator | Interactive skill development |
| artifacts-builder | React/Tailwind components |
| canvas-design | Visual art creation |

</details>

<details>
<summary><strong>Framework Patterns (8 skills)</strong></summary>

| Skill | Framework | Preloaded By |
|:---|:---|:---|
| django-patterns | Django ORM, DRF, auth | django-expert |
| react-patterns | React hooks, performance | react-expert, react-typescript-expert |
| vue-patterns | Vue 3 Composition API, Pinia | vue-expert |
| nextjs-patterns | Next.js 14 App Router, RSC | nextjs-expert |
| rails-patterns | Ruby on Rails, ActiveRecord | rails-expert |
| java-patterns | Spring Boot, JPA, microservices | java-expert |
| go-patterns | Concurrency, interfaces | go-expert |
| laravel-patterns | Eloquent, API resources | laravel-expert |

</details>

<details>
<summary><strong>Security & DevOps (7 skills)</strong></summary>

| Skill | Purpose | Preloaded By |
|:---|:---|:---|
| security-audit | OWASP Top 10 checklist | cyber-sentinel |
| semgrep-sast | SAST scanning + MCP plugin | cyber-sentinel, code-reviewer, qa-engineer |
| pipeline-quality | Universal quality gate | code-reviewer, qa-engineer, devops-engineer |
| pipeline-full-build | Universal build pipeline | devops-engineer |
| github-actions | CI/CD templates | devops-engineer |
| kubernetes-deployment | K8s patterns, autoscaling | devops-engineer |
| terraform-patterns | IaC modules, state mgmt | cloud-architect |

</details>

<details>
<summary><strong>More Skills (9)</strong></summary>

| Skill | Category |
|:---|:---|
| tailwind-patterns | UI/Styling |
| antd-patterns | UI/Styling |
| financial-trading-patterns | Specialized Domain |
| crypto-defi-patterns | Specialized Domain |
| pytest-patterns | Testing |
| silent-failure-audit | Quality Assurance |
| feature-workflow | Workflow Automation |
| quick-fix | Workflow Automation |
| pr-ready | Workflow Automation |

</details>

<details>
<summary><strong>Core Language Patterns (7 skills)</strong></summary>

| Skill | Focus |
|:---|:---|
| nodejs-patterns | Async, streams, worker threads |
| python-patterns | Type hints, async, dataclasses |
| fastapi-patterns | DI, async DB, auth |
| express-patterns | Middleware, error handling |
| typescript-patterns | Advanced types, generics |
| vite-patterns | Build config, plugins |
| zustand-patterns | State management, slices |

</details>

For detailed skills documentation, see **[SKILLS.md](SKILLS.md)**.

---

## Documentation

| Document | Purpose |
|:---|:---|
| [README.md](README.md) | Quick start and overview (this file) |
| [CLAUDE.md](CLAUDE.md) | Project configuration and rule index |
| [SKILLS.md](SKILLS.md) | Agent Skills system documentation |
| [CHANGELOG.md](CHANGELOG.md) | Version history and release notes |
| [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) | Upgrading from v1.x to v2.0+ |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Community contribution guidelines |
| [docs/SDK_COMPLIANCE_REPORT.md](docs/SDK_COMPLIANCE_REPORT.md) | 10/10 SDK compliance certification |
| [docs/CONTEXT_ENGINEERING.md](docs/CONTEXT_ENGINEERING.md) | Context management best practices |
| [docs/rules/](docs/rules/) | Modular rule files (7 files) |

---

## Upgrading

<details>
<summary><strong>From any previous version</strong></summary>

```bash
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites
bash scripts/deploy_agents.sh     # Linux/macOS/WSL2
# or
powershell -ExecutionPolicy Bypass -File scripts\deploy_agents.ps1  # Windows
```

All 64 agents support both natural language invocation (v2+) and explicit agent mentions (v1 legacy). No breaking changes.

</details>

---

## Contributing

Contributions are welcome! See **[CONTRIBUTING.md](CONTRIBUTING.md)** for guidelines.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingNewAgent`)
3. Follow the [Agent Development Guidelines](CONTRIBUTING.md#agent-development-guidelines)
4. Commit with [conventional commits](CONTRIBUTING.md#commit-messages)
5. Open a Pull Request

---

## Credits & References

| | Resource |
|:---|:---|
| **Author** | [Yassine Boumiza](https://boumiza.com) -- [GitHub](https://github.com/advisely/) |
| **Repository** | [advisely/claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites) |
| **Anthropic Docs** | [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) |
| **Agent Skills** | [Equipping Agents for the Real World](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) |
| **Agent SDK** | [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk) |
| **Plugins** | [Claude Code Plugins Announcement](https://www.anthropic.com/news/claude-code-plugins) |
| **Agent Teams** | [Building a C Compiler with Agent Teams](https://www.anthropic.com/engineering/building-c-compiler) |
| **Construction AI** | [IMPARARIA](https://impararia.com) -- Progressive Deployment Methodology |

---

## License

Distributed under the **MIT License**. See [LICENSE.md](LICENSE.md) for details.

If you find this project useful:

- Star the repository
- Share with your team
- [Discuss](https://github.com/advisely/claude-code-agents-team-nation-of-elites/discussions) / [Report Issues](https://github.com/advisely/claude-code-agents-team-nation-of-elites/issues)

---

<div align="center">

**Nation of Elites v3.7.0** -- 64 Agents | 10 Divisions | 31 Skills | Official Plugin Integrations | Agent Teams | Semgrep SAST | Universal Pipelines

*[Yassine Boumiza](https://boumiza.com)*

</div>
