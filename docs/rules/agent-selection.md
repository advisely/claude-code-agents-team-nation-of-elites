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

## Coordination Guidelines
- Respect the hierarchical structure for major decisions
- Use lateral coordination for peer-to-peer collaboration
- Maintain documentation trails for all decisions
- Provide clear context when delegating between agents
