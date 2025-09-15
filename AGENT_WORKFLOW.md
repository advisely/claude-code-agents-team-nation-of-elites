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
  - **Next.js Expert**: Next.js framework with SSR/SSG
  - **Django Expert**: Django framework backend development
  - **Laravel Expert**: Laravel framework backend development
  - **Rails Expert**: Ruby on Rails framework development
  - **Go Expert**: High-performance systems and concurrent programming
  - **Financial Systems Expert**: Trading algorithms and fintech applications
  - **Crypto API Developer**: Cryptocurrency, blockchain, and DeFi protocol development
  - **Tailwind CSS Expert**: Utility-first CSS styling
  - **CATIA Design Expert**: 3D CAD modeling and EKL scripting
  - **Autodesk Cloud Construction Expert**: Construction management and BIM coordination

### Quality & Operations
- **QA Engineer**: Automated validation implementation
- **Code Reviewer**: Code quality, security review
- **Performance Optimizer**: Performance analysis and optimization
- **Cyber Sentinel**: Security analysis and hardening
- **Documentation Specialist**: Technical documentation
- **Message Queue Specialist**: Event-driven architecture and messaging systems

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

## Thinking Policies & Enforcement

The Tech Lead Orchestrator enforces explicit, budgeted internal reasoning across all roles. Agents use an internal scratchpad only when triggered and surface concise rationale summaries (no raw chain-of-thought) in outputs.

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
- **Framework Specialists**: React/Vue/Next.js/Go/Django/Laravel experts, technology-specific decisions
- **DevOps Engineer**: Pipeline design, deployment strategies, tool selection tradeoffs
- **Cyber Sentinel**: Security analysis, threat modeling, compliance requirements
- **Infrastructure Specialist**: Infrastructure design, monitoring setup, performance tuning
- **Message Queue Specialist**: Event-driven architecture, messaging patterns, queue optimization
- **Financial Systems Expert**: Trading algorithms, compliance requirements, risk management
- **Crypto API Developer**: DeFi protocol integrations, smart contract interactions, blockchain security

#### **Low Complexity (100–200 tokens)**
- **Backend Developer**: Data access patterns, edge case handling, implementation details
- **Frontend Developer**: Component composition, state strategy, performance vs UX tradeoffs
- **QA Engineer**: Test case design, automation strategy, validation approaches
- **Performance Optimizer**: Optimization techniques, profiling analysis, bottleneck identification

#### **Orchestration (≤300 tokens)**
- **Tech Lead Orchestrator**: Multi-agent planning, priority conflicts, delegation decisions
- **Team Configurator**: Stack detection, agent selection, configuration setup

Guardrails (enforced):
- Trigger thinking only for complex tradeoffs/uncertainty. Stop at role budget.
- Output concise rationale sections only (bullets). No raw chain-of-thought.
- After two passes, if uncertainty remains → request clarification or delegate to an appropriate role.

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

## Automatic Documentation Updates

Key agents automatically update project documentation after completing their work:

### Documentation-Updating Agents
- **Backend Developer**: Updates CLAUDE.md (backend components, APIs, database), PLAN.md (task status), CHANGELOG.md (backend features)
- **Frontend Developer**: Updates CLAUDE.md (UI components, features, state), PLAN.md (frontend tasks), CHANGELOG.md (UI changes)
- **Code Reviewer**: Updates CLAUDE.md (quality status, security findings), PLAN.md (review results), CHANGELOG.md (review completion)
- **DevOps Engineer**: Updates CLAUDE.md (CI/CD config, infrastructure), PLAN.md (deployment milestones), CHANGELOG.md (pipeline implementation)
- **Tech Lead Orchestrator**: Updates CLAUDE.md (team assignments, decisions), PLAN.md (plan-of-record), CHANGELOG.md (orchestration phases)

### Documentation Files Maintained
- **CLAUDE.md**: Project configuration, team assignments, implementation status, architecture decisions
- **PLAN.md**: Current plan-of-record, milestones, task status, dependencies, risk mitigation
- **CHANGELOG.md**: Chronological record of features, changes, fixes, and major decisions

### Standardized Entry Formats
Each agent follows consistent changelog entry formats:
```markdown
## [Date] - [Agent Type] [Phase]
### Added
- [New features/components]
### Changed
- [Modifications/updates]
### [Category-specific sections]
- [Agent-specific details]
```

This workflow ensures efficient, non-overlapping agent coordination with clear delegation chains, automatic documentation, and no infinite loops.
