# Agent Selection & Usage Guidelines

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

### Content & Localization Wing
- Book writing, editing, and publishing
- Ghostwriting and narrative content
- Document translation and localization
- Terminology management and glossary maintenance

### Business Development Wing
- Lead generation and prospecting
- Opportunity pipeline management
- Proposal and RFP creation
- Client lifecycle and retention
- Market research and competitive intelligence
- Social media strategy and paid advertising

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

## v3.4+ Features

### Persistent Agent Memory
Agents with `memory: project` build institutional knowledge across sessions:
- `code-reviewer` - Code patterns, style conventions, recurring issues
- `cyber-sentinel` - Vulnerabilities found, security patterns, scan history
- `chief-operations-orchestrator` - Decisions, team assignments, project context
- `functional-analyst` - FSD, acceptance criteria, domain glossary
- `code-archaeologist` - Codebase structure and previous findings
- `integration-specialist` - Integration configs and MCP server patterns
- `catia-design-expert` - Design patterns and MCP connector configurations
- `revit-bim-expert` - Revit API patterns, family standards, MCP connector configurations
- `translation-localization-specialist` - Terminology glossaries, translation preferences, style guides
- `business-development-manager` - Pipeline state, deal history, partner relationships
- `lead-generation-specialist` - Outreach patterns, response rates, qualification criteria
- `proposal-architect` - Proposal templates, win rates, common requirements
- `client-success-manager` - Client health, interaction history, satisfaction trends
- `social-media-strategist` - Content performance, audience insights, campaign history

### Skills Preloading
Framework specialists preload matching skills at startup via `skills:` frontmatter:
- `django-expert` → `django-patterns`
- `react-expert` → `react-patterns`
- `cyber-sentinel` → `security-audit`
- `devops-engineer` → `github-actions`, `kubernetes-deployment`
- See each agent's frontmatter for the full mapping

### Permission Modes
- Code-writing agents: `permissionMode: acceptEdits` for frictionless development
- Read-only analysts: `permissionMode: plan` for safe exploration

## Coordination Guidelines
- Respect the hierarchical structure for major decisions
- Use lateral coordination for peer-to-peer collaboration
- Maintain documentation trails for all decisions
- Provide clear context when delegating between agents
