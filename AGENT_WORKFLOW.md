# Agent Workflow & Delegation Chain

This document defines the proper workflow between agents to prevent overlaps, circular loops, and ensure efficient delegation.

## Hierarchy & Flow

```
Project Sponsor (Executive Decision)
    ↓
Program Manager (Portfolio Oversight)
    ↓
Product Manager (Product Vision) ←→ Business Analyst (Detailed Requirements)
    ↓
Tech Lead Orchestrator (Technical Coordination)
    ↓
Team Configurator (if unfamiliar codebase)
    ↓
Specialized Agents (Implementation)
    ↓
Code Reviewer (Quality Gate)
    ↓
Documentation Specialist (Final Documentation)
```

## Agent Responsibilities (No Overlaps)

### Executive Level
- **Project Sponsor**: Business vision, funding, go/no-go decisions
- **Program Manager**: Multi-project coordination, resource optimization

### Strategy Level
- **Product Manager**: Product vision, epic-level features, roadmap
- **Business Analyst**: Detailed requirements, acceptance criteria, edge cases
- **Solution Architect**: Technical architecture, system design
- **UX/UI Architect**: User experience, interface design

### Project Management
- **Project Manager/Scrum Master**: Sprint management, impediment removal, progress tracking

### Technical Coordination
- **Tech Lead Orchestrator**: Task delegation, technical workflow coordination
- **Team Configurator**: Tech stack detection, agent team setup (one-time per project)

### Implementation
- **Backend Developer**: Server-side implementation
- **Frontend Developer**: Client-side implementation
- **API Architect**: API design and specification
- **Framework Specialists**: Technology-specific implementation
  - **React Expert**: React.js applications and components
  - **Vue Expert**: Vue.js applications and components
  - **Django Expert**: Django framework backend development
  - **Laravel Expert**: Laravel framework backend development
  - **Rails Expert**: Ruby on Rails framework development
  - **Tailwind CSS Expert**: Utility-first CSS styling
  - **CATIA Design Expert**: 3D CAD modeling and EKL scripting
  - **Autodesk Cloud Construction Expert**: Construction management and BIM coordination

### Quality & Operations
- **QA Engineer**: Automated validation implementation
- **Code Reviewer**: Code quality, security review
- **Performance Optimizer**: Performance analysis and optimization
- **Cyber Sentinel**: Security analysis and hardening
- **Documentation Specialist**: Technical documentation

## Delegation Rules

### 1. No Circular Delegation
- Agents cannot delegate back to agents higher in the hierarchy
- Each agent can only delegate to agents at the same level or lower
- Maximum delegation depth: 3 levels

### 2. Parallel Execution Limits
- Maximum 2 agents can run in parallel
- Tech Lead Orchestrator enforces this limit

### 3. Automatic Triggers

#### Project Sponsor → Tech Lead Orchestrator
**MUST delegate when:**
- User requests feature implementation
- Technical work needs planning
- Development tasks need coordination

#### Tech Lead Orchestrator → Team Configurator
**MUST delegate when:**
- Unfamiliar codebase detected
- No CLAUDE.md configuration exists
- Tech stack is unclear

#### Product Manager → Business Analyst
**MUST delegate when:**
- Detailed requirements needed
- Acceptance criteria required
- Edge cases need analysis

#### Any Agent → Code Reviewer
**MUST delegate when:**
- Code implementation is complete
- Before merging to main branch
- Security review needed

## Workflow Examples

### New Feature Request
1. **Project Sponsor**: Defines business objectives
2. **Product Manager**: Creates product vision and epics
3. **Business Analyst**: Details requirements and acceptance criteria
4. **Tech Lead Orchestrator**: Plans technical implementation
5. **Team Configurator**: Sets up agent team (if needed)
6. **Specialized Agents**: Implement features
7. **Code Reviewer**: Reviews implementation
8. **Documentation Specialist**: Updates documentation

### Performance Issue
1. **Project Sponsor**: Identifies business impact
2. **Tech Lead Orchestrator**: Coordinates performance analysis
3. **Performance Optimizer**: Analyzes and optimizes
4. **Code Reviewer**: Reviews optimizations
5. **Documentation Specialist**: Documents changes

### New Project Setup
1. **Project Sponsor**: Defines project vision
2. **Program Manager**: Allocates resources
3. **Tech Lead Orchestrator**: Initiates technical planning
4. **Team Configurator**: Analyzes codebase and sets up team
5. **Solution Architect**: Defines architecture
6. **Implementation begins with specialized agents**

## Anti-Patterns to Avoid

### ❌ Circular Loops
- Tech Lead Orchestrator → Backend Developer → Tech Lead Orchestrator
- Product Manager → Business Analyst → Product Manager

### ❌ Role Overlap
- Product Manager doing detailed requirements (Business Analyst's job)
- Business Analyst creating product vision (Product Manager's job)
- Multiple agents doing tech stack analysis

### ❌ Infinite Delegation
- Agents delegating without doing any work themselves
- Delegation chains longer than 3 levels

## Success Metrics

- **No Missing Agents**: All delegations reference existing agents
- **Clear Handoffs**: Each agent knows exactly what to delegate and when
- **No Overlaps**: Each responsibility belongs to exactly one agent type
- **Efficient Flow**: Maximum 2 parallel agents, clear sequential steps
- **Complete Coverage**: Every task type has a designated agent

## Emergency Fallbacks

If a specialized agent is not available:
1. **Framework Specialist** → **Backend/Frontend Developer**
2. **Missing Agent** → **General Purpose** (with notification)
3. **Circular Loop Detected** → **Tech Lead Orchestrator** takes control

This workflow ensures efficient, non-overlapping agent coordination with clear delegation chains and no infinite loops.
