# Thinking Policies & Budgets

The orchestrator enforces explicit, budgeted internal reasoning across roles. Agents use an internal scratchpad only when triggered and surface concise rationale summaries (no raw chain-of-thought) in outputs.

**Claude Opus 5.5 alignment:** the token budgets below are scratchpad sizes, not SDK `thinking.budget_tokens` (removed since Opus 4.7, and a 400 on Opus 5.5 at every effort level). The "scratchpad" is the model's own adaptive thinking, never text in the response. The budgets map onto effort levels:

| Scratchpad Budget | Effort Level | Typical Use |
|-------------------|--------------|-------------|
| 600–800 tokens | `high` / `xhigh` | Architects, hard design tradeoffs |
| 400–600 tokens | `medium` / `high` | Analysts, planners, AI strategy |
| 200–300 tokens | `medium` | Framework specialists, orchestrator |
| 100–200 tokens | `low` / `medium` | Developers, QA engineer, performance |

Opus 5.5 changes how to read this table:

- **Default effort is `medium`** on Opus 5.5 (API and Claude Code). Sonnet 5 stays at `high`. Opus 5.5 at `medium` matches or beats Opus 5 at `high`, so the effort column sits one notch lower than it did under Opus 5. Reserve `xhigh`/`max` for measured gains, because Opus 5.5 thinks more per turn at the same level.
- **Thinking is always on.** It can't be disabled (HTTP 400; Claude Code's toggle and `MAX_THINKING_TOKENS=0` are ignored). To spend less, lower effort. That works more reliably than "think less" instructions.
- **Never surface the scratchpad.** Prompts that push the model to reproduce its reasoning in the response can be declined as `reasoning_extraction`. The guardrail below (concise rationale bullets, no raw chain-of-thought) is what keeps agents compliant.
- Tune per-agent via `effort:` frontmatter only when warranted. No roster agent sets it today.

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
