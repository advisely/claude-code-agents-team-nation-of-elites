# Claude Code CLI Project Configuration - Nation of Elites

## Project Overview

**Project Name:** Claude Code Agents - Team Nation of Elites  
**Author:** Yassine Boumiza  
**Repository:** [claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites)

### Mission Statement

The "Nation of Elites" is a comprehensive multi-agent AI workforce that functions like a real-world IT company. This orchestrated system provides specialized expertise and structured workflows that mirror high-performing tech organizations, enabling projects to go from initial concept to production-ready deployment with systematic precision.

### Core Philosophy

A single generalist AI lacks the specialized expertise and structured workflow of a real-world company. Complex projects require a team of specialists—architects, managers, developers, testers, and security experts—all working in concert. The Nation of Elites solves this by providing a fully-realized virtual IT organization with defined roles, responsibilities, and coordination patterns.

## Organizational Structure

The Nation of Elites consists of **45 specialized agents** organized across **7 strategic divisions**:

### 00_Executive_Wing (2 agents)
**Leadership and Strategic Direction**
- `program-manager` - Program-level coordination and portfolio management
- `project-sponsor` - Business vision, funding, and strategic oversight

### 01_Strategy_and_Planning_Wing (5 agents)
**Strategic Planning and Architecture**
- `business-analyst` - Requirements analysis and business process optimization
- `functional-analyst` - Process modeling, functional specifications, and system behavior analysis
- `product-manager` - Product vision, roadmap, and feature prioritization
- `solution-architect` - High-level technical architecture and technology stack decisions
- `ux-ui-architect` - User experience design and interface architecture

### 02_Project_Management_Office (1 agent)
**Project Execution and Process Management**
- `project-manager-scrum-master` - Agile delivery, sprint management, and impediment removal

### 03_Engineering_Division (21 agents)
**Development and Technical Implementation**

#### Core Development Team (3 agents)
- `api-architect` - API design, documentation, and integration patterns
- `backend-developer` - Server-side development and database design
- `frontend-developer` - Client-side development and user interface implementation

#### Framework Specialists (14 agents)
- `django-expert` - Python Django framework specialization
- `laravel-expert` - PHP Laravel framework specialization
- `rails-expert` - Ruby on Rails framework specialization
- `react-expert` - React.js framework specialization
- `react-typescript-expert` - React with TypeScript specialization and type-safe development
- `vue-expert` - Vue.js framework specialization
- `nextjs-expert` - Next.js framework specialization
- `java-expert` - Java programming language and Spring Framework specialization
- `database-expert` - Database architecture, optimization, and data modeling specialization
- `tailwind-css-expert` - Utility-first CSS framework specialization
- `go-expert` - Go programming language and high-performance systems
- `financial-systems-expert` - Trading algorithms and fintech applications
- `crypto-api-developer` - Cryptocurrency, blockchain, and DeFi protocol development
- `autodesk-cloud-construction-expert` - Autodesk Construction Cloud and BIM coordination
- `catia-design-expert` - CATIA design system integration and CAD workflows
- `antd-ui-developer` - Ant Design React UI framework specialization and enterprise component development

#### Code Excellence Guild (6 agents)
- `code-reviewer` - Code quality assurance and best practices enforcement
- `documentation-specialist` - Technical documentation and knowledge management
- `performance-optimizer` - Performance analysis and optimization
- `code-archaeologist` - Legacy code analysis and modernization
- `general-purpose` - Versatile programming assistance across multiple languages and frameworks
- `statusline-setup` - Terminal statusline configuration and shell prompt customization
- `output-style-setup` - CLI output formatting, terminal colors, and text styling

### 04_Quality_Assurance_Battalion (4 agents)
**Quality Assurance and Testing**
- `automated-test-scripter` - Test automation and continuous testing
- `qa-engineer` - Automated validation implementation
- `qa-test-planner` - Test strategy and quality assurance planning
- `visual-regression-specialist` - UI/UX testing and visual consistency

### 05_SecOps_and_Infrastructure_Division (6 agents)
**Security, Operations, and Infrastructure**
- `cloud-architect` - Cloud platform design and multi-cloud strategies
- `cyber-sentinel` - Security analysis and threat protection
- `devops-engineer` - CI/CD pipelines and deployment automation
- `infrastructure-specialist` - Infrastructure management and system operations
- `message-queue-specialist` - Event-driven architecture and message queuing systems
- `storage-security-specialist` - Storage security, data encryption, access controls, and compliance

### 06_AI_and_Machine_Learning_Division (5 agents)
**AI, ML, and Data Engineering**
- `aiops-specialist` - AI-driven operations and intelligent automation
- `ai-strategist` - AI strategy and implementation planning
- `data-engineer` - Data pipeline and infrastructure development
- `data-scientist` - Data analysis and machine learning modeling
- `ml-engineer` - ML model deployment and production systems

### 07_Orchestrators (3 agents)
**System Coordination and Integration**
- `tech-lead-orchestrator` - Central execution coordinator with subagent spawning and context compaction
- `team-configurator` - Tech stack detection and agent team configuration
- `integration-specialist` - MCP server setup, external API connections, OAuth flows (cross-cutting coordination)

## Agent Interaction Patterns

### Hierarchical Command Flow

The Nation of Elites follows a structured command hierarchy that mirrors real-world IT organizations:

```
Executive Wing → Strategy & Planning → Project Management → Implementation Teams
     ↓                    ↓                    ↓                    ↓
Business Vision → Technical Strategy → Process Management → Specialized Execution
```

### Delegation Patterns

Each agent includes specific delegation cues for seamless handoffs:

1. **Upward Escalation** - Complex decisions escalate to appropriate leadership
2. **Lateral Coordination** - Peer-to-peer collaboration for cross-functional work
3. **Downward Delegation** - Leadership distributes work to specialized teams
4. **Expert Consultation** - Specialists consulted for domain-specific guidance

### Communication Protocols

- **Task Tool (v2)** - Claude automatically spawns agents via the Task tool based on user intent
- **Legacy Pattern (v1)** - `@agent-[name]` explicit invocation (backward compatible)
- **Context Handoffs** - Structured information transfer between agents
- **Status Reporting** - Regular progress updates through the hierarchy
- **Documentation Trails** - Comprehensive documentation of decisions and implementations

## Usage Guidelines

### Project Initiation Workflow

1. **Executive Kickoff** - Start with `project-sponsor` to define business objectives
2. **Strategic Planning** - Use `program-manager` and `product-manager` for roadmap creation
3. **Technical Architecture** - Engage `solution-architect` for technology stack decisions
4. **Implementation Planning** - Activate `project-manager-scrum-master` for execution planning
5. **Development Execution** - Deploy appropriate specialists based on technology choices

### Agent Selection Guidelines

#### When to Use Executive Wing
- Setting business vision and objectives
- Program-level coordination across multiple projects
- Resource allocation and strategic decision making

#### When to Use Strategy & Planning Wing
- Requirements gathering and analysis
- Product roadmap development
- Technical architecture design
- User experience planning

#### 🧠 Thinking Policies & Budgets

The orchestrator enforces explicit, budgeted internal reasoning across roles. Agents use an internal scratchpad only when triggered and surface concise rationale summaries (no raw chain-of-thought) in outputs.

### Reasoning Complexity Levels

#### **High Complexity (600–800 tokens)**
- **Solution Architect**: System design, technology stack decisions, architectural patterns
- **UX/UI Architect**: User experience flows, interface design systems, accessibility compliance
- **API Architect**: API design patterns, integration strategies, versioning approaches
- **Cloud Architect**: Multi-cloud strategies, scalability planning, disaster recovery

#### **Medium Complexity (400–600 tokens)**
- **Business Analyst**: Requirements analysis, stakeholder alignment, process optimization
- **Functional Analyst**: Process modeling, functional specifications, system behavior analysis
- **QA Test Planner**: Test strategy, coverage planning, risk-based testing approaches
- **AI Strategist**: AI implementation planning, model selection, ethical considerations

#### **Medium-Low Complexity (200–300 tokens)**
- **Framework Specialists**: React/Vue/Next.js/Go/Django/Laravel/Financial Systems/Crypto API experts
- **DevOps Engineer**: Pipeline design, deployment strategies, tool selection tradeoffs
- **Cyber Sentinel**: Security analysis, threat modeling, compliance requirements
- **Infrastructure Specialist**: Infrastructure design, monitoring setup, performance tuning
- **Message Queue Specialist**: Event-driven architecture, messaging patterns, queue optimization

#### **Low Complexity (100–200 tokens)**
- **Backend Developer**: Data access patterns, edge case handling, implementation details
- **Frontend Developer**: Component composition, state strategy, performance vs UX tradeoffs
- **QA Engineer**: Test case design, automation strategy, validation approaches
- **Performance Optimizer**: Optimization techniques, profiling analysis, bottleneck identification

#### **Orchestration (≤300 tokens)**
- **Tech Lead Orchestrator**: Multi-agent planning, priority conflicts, delegation decisions
- **Team Configurator**: Stack detection, agent selection, configuration setup

Guardrails (enforced by orchestrator):
- Trigger thinking only for complex tradeoffs/uncertainty. Stop at budget.
- Output concise rationale sections only (bullets). No raw chain-of-thought.
- After two passes, if uncertainty remains → request clarification or delegate to the appropriate role.

#### When to Use Project Management Office
- Sprint planning and agile process facilitation
- Progress tracking and impediment removal
- Stakeholder communication and reporting

#### When to Use Engineering Division
- **Core Development**: API design, backend/frontend implementation
- **Framework Specialists**: Technology-specific implementations
- **Code Excellence**: Code review, documentation, performance optimization
- **Tech Leadership**: Development team coordination

#### When to Use Quality Assurance Battalion
- Test strategy and planning
- Automated testing implementation
- Visual and UI consistency validation

#### When to Use SecOps & Infrastructure Division
- Cloud architecture and deployment
- Security analysis and implementation
- CI/CD pipeline development
- Infrastructure management

#### When to Use AI & ML Division
- Data processing and analysis
- Machine learning model development
- AI strategy and implementation
- Intelligent automation

### Best Practices

#### Agent Invocation

**Claude Code v2 (Recommended)**
```
# Natural language - Claude selects the right agent
"Design the system architecture for a microservices e-commerce platform"
# Claude spawns solution-architect via Task tool

# With specific requirements
"Implement the payment API backend using the specifications from the architecture doc"
# Claude spawns backend-developer via Task tool
```

**Claude Code v1 (Legacy)**
```
# Explicit agent mention (still supported)
"Use @agent-solution-architect to design the system architecture"

# With Context
"Let me hand this off to @agent-backend-developer with the API specifications"
```

#### Project Workflow
1. Always start with business objectives (`project-sponsor`)
2. Progress through strategic planning before implementation
3. Maintain clear documentation throughout the process
4. Use appropriate specialists for technology-specific work
5. Ensure quality gates through QA battalion
6. Include security and infrastructure considerations early

#### Coordination Guidelines
- Respect the hierarchical structure for major decisions
- Use lateral coordination for peer-to-peer collaboration
- Maintain documentation trails for all decisions
- Provide clear context when delegating between agents

## Standards Compliance

### Claude Code CLI Alignment

This multi-agent system is designed to work seamlessly with Anthropic's Claude Code CLI, following these key principles:

- **Agent Metadata** - All agents include proper name, description, and tools configuration
- **Context Awareness** - Agents understand their role within the larger system
- **Delegation Patterns** - Clear handoff mechanisms between specialized agents
- **Tool Integration** - Proper use of Claude Code CLI tools (LS, Read, Grep, Glob, Bash, Write)

### Agent Format Standards

#### Compliant Agent Structure
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

### Enhanced Features

#### **Automatic Documentation Updates**
Key agents automatically maintain project documentation:
- **Backend/Frontend Developers**: Update CLAUDE.md, PLAN.md, CHANGELOG.md after implementation
- **Code Reviewer**: Updates quality status, security findings, and review completion
- **DevOps Engineer**: Updates CI/CD configuration, infrastructure status, and deployment milestones
- **Tech Lead Orchestrator**: Updates team assignments, decisions, and orchestration phases

#### **Standardized Documentation Files**
- **CLAUDE.md**: Project configuration, team assignments, implementation status, architecture decisions
- **PLAN.md**: Current plan-of-record, milestones, task status, dependencies, risk mitigation
- **CHANGELOG.md**: Chronological record of features, changes, fixes, and major decisions

### Quality Metrics

- **45 Total Agents** - Complete coverage across all organizational functions
- **7 Strategic Divisions** - Logical grouping of related capabilities
- **Hierarchical Structure** - Clear command and coordination patterns
- **Comprehensive Coverage** - From strategy to implementation to operations
- **Automatic Documentation** - Self-maintaining project documentation and change tracking
- **Complexity-Based Reasoning** - Tailored thinking budgets based on task complexity
- **Enhanced Specialization** - TypeScript React, Java/Spring, database architecture, construction/BIM, Ant Design UI, and development tooling expertise
- **SDK Compliance Score** - 10/10 full alignment with Anthropic Claude Agent SDK best practices

### Claude Agent SDK Alignment (v2.0.0)

The Nation of Elites achieves **complete alignment** with Anthropic's Claude Agent SDK best practices:

#### ✅ Subagent Coordination
- Tech Lead Orchestrator spawns 3-5 temporary, task-specific subagents for parallel information gathering
- Isolated context windows for efficient parallel processing
- Clear lifecycle: Created → Execute → Report → Terminate
- Descriptive naming convention for clarity (e.g., `subagent-search-logs-morning`)

#### ✅ Context Compaction
- Automatic summarization triggers at 80% context usage
- Information hierarchy: Critical → Important → Archivable
- Preserves API contracts, security findings, and active blockers
- Example: 170K tokens → 90K tokens (47% reduction) while maintaining quality

#### ✅ File System Context Engineering
- Comprehensive guide: `CONTEXT_ENGINEERING.md`
- Efficient large file handling with bash commands (grep, head, tail)
- Hot/warm/cold file organization strategies
- Subagent patterns for parallel file processing

#### ✅ MCP Integration
- Integration Specialist (07_Orchestrators) manages Model Context Protocol servers
- Supports 15+ external services: Slack, GitHub, Google Drive, Jira, databases, cloud platforms
- OAuth flow handling and secure authentication management
- Standardized tool/resource access through MCP protocol

#### ✅ Visual Feedback Loops
- Visual Regression Specialist provides development-time feedback
- Screenshot-based validation at key development checkpoints
- Multi-viewport testing with parallel subagents
- Real-time UI validation during component creation and style changes

#### ✅ Code Generation Priority
- Backend Developer emphasizes code over configuration
- Generate vs Configure philosophy for precision and reusability
- Automation as code, rules as code, infrastructure as code
- Testable, composable, infinitely reusable outputs

**Certification**: Perfect 10/10 SDK compliance score - [See SDK_COMPLIANCE_REPORT.md](SDK_COMPLIANCE_REPORT.md)

### Agent Skills Integration (v3.0)

The Nation of Elites v3.0 introduces **Agent Skills** - procedural knowledge packages that extend agent capabilities through progressive disclosure, executable code, and modular expertise.

#### Skills vs Agents: Complementary Systems

| Aspect | Agents | Skills |
|--------|--------|--------|
| **Role** | Team members (orchestrators & specialists) | Training manuals & toolkits |
| **Location** | `~/.claude/agents/` | `~/.claude/skills/` |
| **Purpose** | Who performs work | What knowledge they access |
| **Loading** | Task-based spawning | Progressive disclosure (3 levels) |
| **Format** | Markdown with YAML frontmatter | `SKILL.md` with bundled resources |
| **Execution** | Coordinate & delegate | Provide procedures & executable code |

**Key Principle**: Agents USE skills. A Backend Developer (agent) might invoke the `django-patterns` skill (knowledge) or `xlsx` skill (tool).

#### Progressive Disclosure Architecture

Skills minimize context usage through three-level loading:

1. **Level 1: Metadata** (Always loaded)
   - Skill name and description in system prompt
   - Claude decides relevance without loading full content

2. **Level 2: Core Instructions** (Loaded when relevant)
   - Full `SKILL.md` with procedures and guidance
   - Loaded only when Claude identifies task match

3. **Level 3: Additional Resources** (On-demand)
   - Referenced files, scripts, templates
   - Loaded only when specific sub-context needed

**Example**: PDF skill loads metadata always, full instructions when user mentions PDFs, form-filling procedures only when filling forms.

#### Available Skills

**Official Anthropic Skills:**
- **pdf** - PDF manipulation, form filling, extraction, merging
- **docx** - Word document creation, editing, formatting
- **pptx** - PowerPoint presentation generation and styling
- **xlsx** - Excel operations with formulas, charts, data validation
- **mcp-builder** - MCP server development guidance and templates
- **webapp-testing** - Playwright-based UI testing automation
- **skill-creator** - Interactive skill development assistant
- **artifacts-builder** - Complex HTML artifacts with React/Tailwind
- **canvas-design** - Visual art creation in PNG/PDF formats

**Custom Nation of Elites Skills:**
- **django-patterns** - Django best practices, ORM optimization, REST API patterns
- **react-patterns** - React architecture, hooks patterns, performance optimization
- **security-audit** - OWASP Top 10 checklist, security hardening procedures
- **github-actions** - CI/CD pipeline templates and deployment workflows

#### Skills and Code Execution

Skills can include executable Python/JavaScript code for deterministic operations:

- **Why**: Token generation for sorting/calculations is expensive vs. running code
- **How**: Skills bundle scripts that Claude executes via Code Execution Tool
- **Benefits**: Deterministic reliability, efficiency, repeatability

**Example**: PDF skill includes Python script to extract form fields without loading PDF or script into context.

#### Which Agents Use Which Skills

**Engineering Division:**
- `backend-developer`, `django-expert`, `laravel-expert` → Framework pattern skills
- `frontend-developer`, `react-expert`, `vue-expert` → UI framework skills
- `documentation-specialist` → pdf, docx, pptx skills

**Quality Assurance Battalion:**
- `qa-engineer`, `automated-test-scripter` → webapp-testing skill
- `visual-regression-specialist` → canvas-design, artifacts-builder skills

**SecOps & Infrastructure:**
- `devops-engineer` → github-actions, kubernetes-deployment skills
- `cyber-sentinel` → security-audit, owasp-checklist skills

**Orchestrators:**
- `integration-specialist` → mcp-builder skill for external integrations
- `tech-lead-orchestrator` → skill-creator for new capability development

#### Security Considerations

Skills provide executable code and procedural guidance:

- **Risk**: Malicious skills could introduce vulnerabilities or exfiltrate data
- **Mitigation**: Only install skills from trusted sources
- **Best Practice**: Audit skill contents before installation
  - Read `SKILL.md` for instructions
  - Review bundled scripts for dependencies and network calls
  - Verify no untrusted external connections

**Trusted Sources:**
- Official Anthropic skills repository: `github.com/anthropics/skills`
- Nation of Elites custom skills: Included in this repository
- Community skills: Audit thoroughly before use

#### Installation

Skills are automatically installed by the deployment script:

```bash
bash scripts/deploy_agents.sh
# Installs agents (~/.claude/agents) + skills (~/.claude/skills)
```

Manual installation:

```bash
# Clone Anthropic's official skills
git clone https://github.com/anthropics/skills.git /tmp/skills

# Install specific skills
cp -r /tmp/skills/document-skills/pdf ~/.claude/skills/
cp -r /tmp/skills/mcp-builder ~/.claude/skills/

# Install Nation of Elites custom skills (included in repo)
cp -r skills/* ~/.claude/skills/
```

For detailed skills documentation, see [SKILLS.md](SKILLS.md).

## Configuration and Setup

### Installation

#### 🚀 Recommended: Automated Deployment (Works Immediately)

**The most reliable installation method** - works for all Claude Code versions:

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
- Ensures all 45 agents are ready to use

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

**Step-by-step manual setup**:

```bash
# Clone the repository
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git

# Navigate to project directory
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

**WSL2 note**: The Linux path `~/.claude` corresponds in Windows Explorer to `\\wsl.localhost\Ubuntu\home\<USER>\.claude`. You can verify post-deploy there if preferred.

### Verification

After installation, verify the plugin is loaded:

```bash
# List installed plugins
/plugin list

# Check for Nation of Elites
# You should see "nation-of-elites v2.0.0" in the list
```

### Project Initialization

```bash
# Create new project directory
mkdir my-new-project
cd my-new-project

# Initialize with Nation of Elites - Claude will automatically invoke the appropriate agent
claude "I need to define business objectives for this e-commerce project"
# Claude will spawn the project-sponsor agent via the Task tool
```

### Agent Invocation Patterns

#### Claude Code v2 (Automatic Agent Selection)

In Claude Code v2, you describe your need and Claude automatically selects and spawns the appropriate agent using the Task tool:

```bash
# Strategic planning - spawns project-sponsor and program-manager
claude "Define objectives and create roadmap for a mobile payment app"

# Development coordination - spawns tech-lead-orchestrator
claude "Coordinate development of user authentication feature with React frontend and Django backend"

# Quality assurance - spawns qa-test-planner and automated-test-scripter
claude "Create comprehensive test strategy and implement automated tests"

# Deployment - spawns devops-engineer and cloud-architect
claude "Setup CI/CD pipeline and design cloud infrastructure for production deployment"
```

#### Legacy Pattern (Claude Code v1.x)

For backward compatibility, explicit agent mentions still work:

```bash
# Explicit agent invocation (legacy)
claude "Use the project-sponsor agent to define business objectives"
```

### Quick Start Commands

```bash
# Complete project setup - Claude spawns multiple agents in sequence
claude "Initialize a new SaaS project: define business vision, create product roadmap, and propose technology stack"

# Development workflow - spawns project-manager and tech-lead-orchestrator
claude "Plan sprint and coordinate development team for the next iteration"

# Code review and quality - spawns code-reviewer
claude "Review the authentication module code for security and best practices"

# Infrastructure setup - spawns devops-engineer and cloud-architect
claude "Design and implement production infrastructure with auto-scaling and monitoring"
```

## Advanced Usage

### Multi-Project Coordination

For enterprise-level coordination across multiple projects:

```bash
# Spawns program-manager for portfolio coordination
claude "Coordinate our portfolio of 3 microservices projects and optimize resource allocation across teams"
```

### Specialized Technology Implementation

Claude automatically selects framework-specific experts:

```bash
# React + Django stack - spawns react-expert and django-expert
claude "Build a real-time dashboard with React frontend and Django REST API backend"

# Laravel + Vue.js stack - spawns laravel-expert and vue-expert
claude "Develop an admin panel using Laravel for API and Vue.js for the interface"

# TypeScript React - spawns react-typescript-expert
claude "Create a type-safe React application with TypeScript for enterprise use"

# Java Spring - spawns java-expert
claude "Design a microservices architecture using Java Spring Boot"
```

### AI-Enhanced Projects

For projects requiring AI/ML capabilities:

```bash
# Spawns ai-strategist, data-engineer, and ml-engineer
claude "Build a recommendation engine: define AI strategy, create data pipeline, and deploy ML models"

# Spawns data-scientist and ml-engineer
claude "Develop and deploy a customer churn prediction model with real-time scoring"
```

### Specialized Domains

```bash
# Cryptocurrency/Blockchain - spawns crypto-api-developer
claude "Integrate Ethereum wallet functionality and implement DeFi token swapping"

# Financial Systems - spawns financial-systems-expert
claude "Build an algorithmic trading system with risk management"

# Construction/BIM - spawns autodesk-cloud-construction-expert
claude "Setup Autodesk Construction Cloud integration for project coordination"

# Storage Security - spawns storage-security-specialist
claude "Implement encryption at rest and access controls for S3 buckets with compliance auditing"
```

## Troubleshooting

### Common Issues

1. **Agent Not Found** - Ensure agents are properly installed in `~/.claude/agents/`
2. **Unclear Context** - Provide clear context when delegating between agents
3. **Role Confusion** - Use the organizational structure to identify the right agent
4. **Complex Projects** - Start with executive agents and work down the hierarchy

### Support and Contribution

- **GitHub Repository**: [claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites)
- **Author**: Yassine Boumiza - [GitHub Profile](https://github.com/advisely/)
- **License**: MIT License with attribution request

### Contribution Guidelines

1. Fork the repository
2. Create feature branch (`git checkout -b feature/NewAgent`)
3. Follow agent format standards
4. Add comprehensive testing
5. Submit pull request with clear description

---

**The Nation of Elites represents the future of AI-assisted development - a complete, coordinated workforce that brings enterprise-level capabilities to any project scale.**
