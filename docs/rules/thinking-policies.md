# Thinking Policies & Budgets

The orchestrator enforces explicit, budgeted internal reasoning across roles. Agents use an internal scratchpad only when triggered and surface concise rationale summaries (no raw chain-of-thought) in outputs.

**Claude Opus 5 alignment:** the token budgets below are scratchpad-bytes, not SDK `thinking.budget_tokens` (removed in 4.7 and still removed on Opus 5 — it returns HTTP 400). They map onto the current effort levels:

| Scratchpad Budget | Effort Level | Typical Use |
|-------------------|--------------|-------------|
| 600–800 tokens | `xhigh` / `max` | Architects, hard design tradeoffs |
| 400–600 tokens | `high` | Analysts, planners, AI strategy |
| 200–300 tokens | `medium` | Framework specialists, orchestrator |
| 100–200 tokens | `low` / `medium` | Developers, QA engineer, performance |

Default effort is `high` on all surfaces (API + Claude Code). Two Opus 5 changes affect how to read this table:

- **Thinking is on by default.** Omitting `thinking` now runs adaptive, reversing Opus 4.8. Agents that previously ran thinking-off by omission now think — and since `max_tokens` caps thinking *plus* output, check that any tight budget still fits.
- **`low` and `medium` punch above their weight.** Opus 5 holds quality at low effort far better than 4.8, so the lower rows of this table are cheaper than the mapping implies. Treat the effort column as a **starting point to sweep down from**, not a floor. Raise to `xhigh` for agentic coding and hard architecture work; tune per-agent via `effort:` frontmatter only when warranted.
- **Disabling thinking is capped at `high` effort.** `thinking: disabled` paired with `xhigh`/`max` returns HTTP 400. Prefer low effort with thinking on over disabling it.

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
