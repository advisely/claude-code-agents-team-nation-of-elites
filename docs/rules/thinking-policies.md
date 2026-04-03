# Thinking Policies & Budgets

The orchestrator enforces explicit, budgeted internal reasoning across roles. Agents use an internal scratchpad only when triggered and surface concise rationale summaries (no raw chain-of-thought) in outputs.

## Reasoning Complexity Levels

### High Complexity (600–800 tokens)
- **Solution Architect**: System design, technology stack decisions, architectural patterns
- **UX/UI Architect**: User experience flows, interface design systems, accessibility compliance
- **API Architect**: API design patterns, integration strategies, versioning approaches
- **Cloud Architect**: Multi-cloud strategies, scalability planning, disaster recovery

### Medium Complexity (400–600 tokens)
- **Business Analyst**: Requirements analysis, stakeholder alignment, process optimization
- **Functional Analyst**: Process modeling, functional specifications, system behavior analysis
- **QA Test Planner**: Test strategy, coverage planning, risk-based testing approaches
- **AI Strategist**: AI implementation planning, model selection, ethical considerations

### Medium-Low Complexity (200–300 tokens)
- **Framework Specialists**: React/Vue/Next.js/Go/Django/Laravel/Financial Systems/Crypto API/Revit BIM experts
- **DevOps Engineer**: Pipeline design, deployment strategies, tool selection tradeoffs
- **Cyber Sentinel**: Security analysis, threat modeling, compliance requirements
- **Infrastructure Specialist**: Infrastructure design, monitoring setup, performance tuning
- **Message Queue Specialist**: Event-driven architecture, messaging patterns, queue optimization

### Low Complexity (100–200 tokens)
- **Backend Developer**: Data access patterns, edge case handling, implementation details
- **Frontend Developer**: Component composition, state strategy, performance vs UX tradeoffs
- **QA Engineer**: Test case design, automation strategy, validation approaches
- **Performance Optimizer**: Optimization techniques, profiling analysis, bottleneck identification

### Orchestration (≤300 tokens)
- **Chief Operations Orchestrator**: Multi-agent planning, priority conflicts, delegation decisions
- **Team Configurator**: Stack detection, agent selection, configuration setup

## Guardrails (enforced by orchestrator)

- Trigger thinking only for complex tradeoffs/uncertainty. Stop at budget.
- Output concise rationale sections only (bullets). No raw chain-of-thought.
- After two passes, if uncertainty remains → request clarification or delegate to the appropriate role.
