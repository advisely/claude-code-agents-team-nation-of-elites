# Agent Selection & Usage Guidelines

## Platform Support

Agents are platform-independent `.md` files and work on **Windows**, **Linux**, **macOS**, and **WSL2**. They are used by both the Claude Code CLI and IDE extensions (VS Code, JetBrains) from the same `~/.claude/agents/` directory.

| Platform | Deploy Command |
|----------|---------------|
| Linux / macOS / WSL2 | `bash scripts/deploy_agents.sh` |
| Windows (PowerShell) | `powershell -ExecutionPolicy Bypass -File scripts\deploy_agents.ps1` |

## Project Initiation Workflow

1. **Executive Kickoff** - Start with `project-sponsor` to define business objectives
2. **Strategic Planning** - Use `program-manager` and `product-manager` for roadmap creation
3. **Technical Architecture** - Engage `solution-architect` for technology stack decisions
4. **Implementation Planning** - Activate `project-manager-scrum-master` for execution planning
5. **Development Execution** - Deploy appropriate specialists based on technology choices

## When to Use Each Division

### Executive Wing
- Setting business vision and objectives
- Program-level coordination across multiple projects
- Resource allocation and strategic decision making

### Strategy & Planning Wing
- Requirements gathering and analysis
- Product roadmap development
- Technical architecture design
- User experience planning

### Project Management Office
- Sprint planning and agile process facilitation
- Progress tracking and impediment removal
- Stakeholder communication and reporting

### Engineering Division
- **Core Development**: API design, backend/frontend implementation
- **Framework Specialists**: Technology-specific implementations
- **Code Excellence**: Code review, documentation, performance optimization

### Quality Assurance Battalion
- Test strategy and planning
- Automated testing implementation
- Visual and UI consistency validation

### SecOps & Infrastructure Division
- Cloud architecture and deployment
- Security analysis and implementation
- CI/CD pipeline development
- Infrastructure management

### AI & ML Division
- Data processing and analysis
- Machine learning model development
- AI strategy and implementation
- Intelligent automation

## Agent Invocation

**Claude Code v2 (Recommended)**
```
# Natural language - Claude selects the right agent
"Design the system architecture for a microservices e-commerce platform"
# Claude spawns solution-architect via Task tool
```

**Claude Code v1 (Legacy)**
```
# Explicit agent mention (still supported)
"Use @agent-solution-architect to design the system architecture"
```

## New Features (Feb 2026)

### Persistent Agent Memory
Agents with `memory: project` build institutional knowledge across sessions:
- **code-reviewer** - Remembers code patterns, style conventions, recurring issues
- **cyber-sentinel** - Remembers vulnerabilities found, security patterns, scan history
- **tech-lead-orchestrator** - Remembers decisions, team assignments, project context
- **functional-analyst** - Remembers FSD, acceptance criteria, domain glossary
- **code-archaeologist** - Remembers codebase structure and previous findings
- **integration-specialist** - Remembers integration configs and MCP server patterns
- **catia-design-expert** - Remembers design patterns and MCP connector configurations

### Skills Preloading
Framework specialists preload matching skills for faster, more consistent results:
- `django-expert` preloads `django-patterns`
- `react-expert` preloads `react-patterns`
- `cyber-sentinel` preloads `security-audit`
- `devops-engineer` preloads `github-actions`, `kubernetes-deployment`
- See each agent's `skills:` field for full mapping

### Permission Modes
- Code-writing agents use `permissionMode: acceptEdits` for frictionless development
- Read-only analysts could use `permissionMode: plan` for safe exploration

## Coordination Guidelines
- Respect the hierarchical structure for major decisions
- Use lateral coordination for peer-to-peer collaboration
- Maintain documentation trails for all decisions
- Provide clear context when delegating between agents
