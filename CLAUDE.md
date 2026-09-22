# Claude Code CLI Project Configuration - Nation of Elites

**Project:** Claude Code Agents - Team Nation of Elites
**Author:** Yassine Boumiza ([boumiza.com](https://boumiza.com))
**Repo:** [advisely/claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites)

## Mission

A multi-agent AI workforce that functions like a real-world company: 74 specialized agents across 12 divisions, taking projects from concept to production — and from lead to revenue — with systematic precision.

## Memory Layers

| Layer | File | Purpose |
|-------|------|---------|
| Identity & Voice | `CLAUDE.md` (this file) | Project identity, rule index |
| Facts & Canon | `docs/rules/*.md` | Agent roster, SDK rules, skill maps |
| Working Notes | `PLAN.md`, `CHANGELOG.md` | Current plan, decisions, session context |

## Rule Files (load on-demand)

| File | Domain | When Loaded |
|------|--------|-------------|
| [organization.md](docs/rules/organization.md) | 74 agents, 12 divisions, full roster | Always (project context) |
| [orchestration.md](docs/rules/orchestration.md) | Delegation, Agent Teams, context compaction | Orchestration & planning |
| [thinking-policies.md](docs/rules/thinking-policies.md) | Reasoning budgets (100–800 tokens) | Agent execution |
| [sdk-compliance.md](docs/rules/sdk-compliance.md) | Opus 5.5 features, surface coverage, task budgets, adaptive thinking, server tools, strict mode | SDK & API integration |
| [agent-selection.md](docs/rules/agent-selection.md) | Division guide, invocation patterns, v3.7 features | Task delegation |
| [skills-integration.md](docs/rules/skills-integration.md) | Skills vs agents, progressive disclosure, agent-skill map | Skills usage |
| [standards.md](docs/rules/standards.md) | Agent frontmatter spec, doc standards, tool use | Agent development |

## Organizational Structure

**74 agents across 12 divisions** — see [organization.md](docs/rules/organization.md) for the full roster.

| Division | Agents | Focus |
|----------|--------|-------|
| 00_Executive_Wing | 2 | Leadership & strategic direction |
| 01_Strategy_and_Planning_Wing | 5 | Strategic planning & architecture |
| 02_Project_Management_Office | 1 | Agile delivery & process management |
| 03_Engineering_Division | 31 | Development & technical implementation |
| 04_Quality_Assurance_Battalion | 4 | Quality assurance & testing |
| 05_SecOps_and_Infrastructure | 9 | Security, operations & infrastructure |
| 06_AI_and_ML_Division | 5 | AI, ML & data engineering |
| 07_Orchestrators | 3 | System coordination & integration |
| 08_Mobile_Development_Wing | 3 | Native & cross-platform mobile |
| 09_Construction_Industry | 1 | Construction industry AI orchestration |
| 10_Content_and_Localization | 4 | Publishing, books & multilingual localization |
| 11_Business_Development | 6 | BD pipeline, proposals, market strategy & social media |

## Skills System

**33 custom skills** + 9 official Anthropic skills with progressive disclosure (3-level loading). Framework specialists preload matching skills via `skills:` frontmatter. See [skills-integration.md](docs/rules/skills-integration.md) and [SKILLS.md](SKILLS.md).

`humanizer` skill preloads on all Content & Localization Wing agents (`book-author`, `book-editor`, `publishing-specialist`, `translation-localization-specialist`) and Business Development Wing agents (`proposal-architect`, `social-media-strategist`, `lead-generation-specialist`, `client-success-manager`, `business-development-manager`) -- removes 29 AI writing patterns with voice calibration and multi-pass auditing.

`silent-failure-audit` skill loads automatically on `code-reviewer`, `cyber-sentinel`, `qa-engineer`, and `automated-test-scripter` — no per-project config needed.

`semgrep-sast` skill integrates with the Semgrep MCP plugin for automated SAST scanning. Preloaded on `cyber-sentinel`, `code-reviewer`, `qa-engineer`, `automated-test-scripter`, and `devops-engineer`.

Three skills provide universal, stack-adaptive pre-merge and release automation, consolidated from five in v4.0.0. `pipeline-quality` is the **complete pre-merge gate**: deterministic checks (lint, type check, build, the three-part security gate, tests, happy/non-happy/edge **test case matrix**, local E2E, dead-code, dep audit) followed by its own reasoning fan-out (behavior-preserving simplification → severity-rated correctness/security/performance review, delegated to the `code-reviewer` agent) and consuming zero-debt / no-regression gates — the judgment pass is no longer a separate skill call.

`pipeline-full-build-cloud` and `pipeline-full-build-desktop` are each a **complete, standalone release chain** — preflight, failsafe backup, `/pipeline-quality`, version bump, commit, merge, push, build/package, ship, post-deploy verification, documentation, and cleanup — rather than a shared spine plus a routed variant. `pipeline-full-build-desktop` compiles locally against the **Electron ABI** (native module rebuilds, frozen Python sidecars), signs and notarizes, then validates the **packaged binary** — launch smoke, clean first-run, offline start, cross-platform matrix — and ships via a staged update feed that cannot be rolled back server-side. `pipeline-full-build-cloud` builds a container with SBOM and a CVE gate, validates against a **restored production schema** (migration up/down/up, lock inspection) plus contract and load tests on staging, then deploys to production — **VPS + `docker compose` over SSH is the primary deploy path**, with Kubernetes (and its canary/rolling mechanics) documented as a secondary branch. Rollback is one command and stays real because the deploy is **pinned to an explicit version** the compose file resolves (`image: ${APP_IMAGE}:${APP_VERSION}`), asserted at deploy time so a non-reversible deploy fails loudly there rather than silently at rollback. `/feature-workflow` (Phases 5–6) and `/pr-ready` delegate their quality-gate step to `/pipeline-quality` rather than inlining checklists, so review logic lives in one place. Preloaded on `code-reviewer` (`semgrep-sast`, `pipeline-quality`), `qa-engineer`, and `devops-engineer` (both variant skills).

## Official Plugin Integrations

**MCP connectors (v3.7.0).** Deploy scripts auto-detect and offer to configure official Anthropic connector plugins from the auto-available `claude-plugins-official` marketplace: GitHub, GitLab, Slack, Atlassian (Jira & Confluence ship as one `atlassian` plugin), Linear, Figma, Sentry, Vercel, Firebase, Supabase, Notion, Asana. See [orchestration.md](docs/rules/orchestration.md) for agent-plugin mapping.

**First-party dev-workflow & tooling plugins (v3.12.0).** The official marketplace has since grown well beyond connectors; these complement the workforce and are recommended alongside it:

- **Code workflow** — `feature-dev` (guided feature development), `code-review`, `code-simplifier`, `pr-review-toolkit`, `code-modernization`, `commit-commands`.
- **Security & quality** — `security-guidance` (secure-by-default library guidance), `hookify` (turn repeated instructions into hooks).
- **Authoring & extensibility** — `skill-creator`, `plugin-dev`, `agent-sdk-dev`, `mcp-server-dev`, `claude-md-management`, `frontend-design`, `playground`, `session-report`, `claude-code-setup`.
- **Language servers (LSP)** — first-party LSP plugins ship for TypeScript, Pyright, gopls, rust-analyzer, clangd, jdtls, kotlin, swift, php, ruby, lua, and C# — load via a plugin's `.lsp.json` (see "New Subagent Features").
- **Output styles** — `learning-output-style`, `explanatory-output-style`.

These overlap intentionally with Nation of Elites' own skills (e.g. `code-review`/`code-simplifier` vs. the review pass inside `pipeline-quality`, `feature-dev` vs. `feature-workflow`): the marketplace skills stay the curated, division-aware path; the official plugins are drop-in alternatives when a lighter, single-purpose tool is preferred.

## Agent Teams (Experimental)

Enable with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Parallel multi-agent coordination with shared task lists, direct inter-agent messaging, and hooks (`TeammateIdle`, `TaskCreated`, `TaskCompleted`). See [orchestration.md](docs/rules/orchestration.md).

## New Subagent Features (v3.7.0)

- `maxTurns`: Cap agentic turns per subagent for cost control
- `isolation: worktree`: Git worktree isolation for parallel development
- MCP Elicitation: Servers can request user input mid-workflow
- Hook `if` field (v2.1.85+): Permission-rule syntax for fine-grained filtering
- LSP servers in plugins: `.lsp.json` for language server protocol integrations

## Recurring Tasks — `/loop` (v3.13.0)

`/loop` is a Claude Code session-level scheduler: a prompt + cadence that re-fires on each tick against current project context. Self-paces when the interval is omitted, is session-scoped, and auto-expires after 7 days. A distinct axis from Agent Teams / Dynamic Workflows (which parallelize *within* a task) — `/loop` repeats one task *across time*. The orchestrator uses it for monitoring/polling briefs; the nine inherently-recurring agents (`aiops-specialist`, `sre-specialist`, `observability-engineer`, `devops-engineer`, `client-success-manager`, `business-development-manager`, `lead-generation-specialist`, `market-intelligence-analyst`, `social-media-strategist`) each carry a `Recurring Work (/loop)` note. Use `/schedule` instead when the cadence must survive across sessions. See [orchestration.md](docs/rules/orchestration.md).

## Claude Opus 5.5 Alignment (v4.1.0)

The `opus` model alias resolves to `claude-opus-5-5` (released 2026-09-22). It succeeds Opus 5 at a **lower** price: $4/$20 per Mtok (was $5/$25), cache reads $0.20, 1M context, 128K output. It performs at Fable 5.1 level on most work, generates output >30% faster, and tends to finish tasks in fewer tokens. It is the `default` model on every Claude plan and needs Claude Code **v2.1.280+**. No frontmatter sweep was needed: all 25 `opus` agents inherited it on release day. (On Microsoft Foundry, `opus` still resolves to Opus 4.6. Set `ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-5-5` there.)

**Default effort dropped to `medium`**, one level below Opus 5's `high`, and Claude Code doesn't carry the Opus 5 setting over. That is fine for the roster: Opus 5.5 at `medium` matches or beats Opus 5 at `high` on coding and knowledge work. No agent sets `effort:`, and none should without measured evidence. Opus 5.5 thinks *more* per turn than Opus 5 at the same level, so reserve `xhigh`/`max` for measured gains.

**Four breaking changes (SDK users):**

- **Thinking can't be disabled.** `disabled` and `budget_tokens` return 400 at every effort level, so effort is the only control. In Claude Code, `alwaysThinkingEnabled` / `MAX_THINKING_TOKENS=0` have no effect
- **Forced `tool_choice` (`any`/`tool`) returns 400.** Use `auto` + `strict: true`, or structured outputs
- **Preserved thinking.** Thinking blocks are tied to the model and to an unedited prefix, so harnesses must be append-only (enforced for accounts created on/after 2026-08-31)
- **Computer use needs `computer_toolset_20260801`** on the Claude API and Google Cloud

**Carried over from Opus 5, re-test before relying on it:**

- **Delegation caps.** Opus 5 needed a **cap, not a nudge**, and the caps stay as the default. Opus 5.5 sustains multi-hour runs with parallel subagents well
- **No self-verification prompts.** "Double-check" caused over-verification on Opus 5. Keep such prompts out
- **Explicit bounds on length and scope** still help, though Opus 5.5's reports are clearer

**New Opus 5.5 steering the roster adopts:**

- **Unattended early stops.** A text-only end of turn is a *report*, not completion. Re-prompt with open checklist items, capped at 2–3 continuations (orchestrator, `/loop`, Agent Teams)
- **Time signals.** Agent-team leads get an elapsed-time budget (`elapsed 340s / 1200s`) and finish sooner at comparable quality
- **Explore before acting.** BD-wing agents open all relevant email/docs/CRM sources before changing anything
- **Name concrete anti-patterns** for frontend design (`ux-ui-architect`, `frontend-developer`)
- **Broader safeguards.** Biology joins cyber, plus `reasoning_extraction`, so never ask an agent to print its reasoning. `cyber-sentinel` points authorized offensive work at the Cyber Verification Program
- **Sharper vision.** Re-test crop/zoom scaffolding for charts and screenshots. Technical drawings still benefit from high-res images plus a crop tool
- **Fast mode** is $8/$40 (Claude API only). `/fast` applies in Claude Code

**Coming soon:** Sonnet 5.5 and Haiku 5.5 are announced for "the coming weeks". The `sonnet` alias will move automatically, and the sonnet/opus split gets re-evaluated then (the price gap is already down to ~1.33×).

See [sdk-compliance.md](docs/rules/sdk-compliance.md) for SDK migration details and [orchestration.md](docs/rules/orchestration.md) for steering notes and delegation discipline.

## Claude Sonnet 5 Alignment (v3.13.0)

The `sonnet` model alias resolves to `claude-sonnet-5` (released 2026-06-30) — the default workhorse for the ~51 `sonnet` agents. No frontmatter sweep was needed; the alias-based policy means agents inherit it automatically. What the roster gains:

- **1M-token context window** — matches Opus 5.5; `sonnet` agents can hold large codebases / many documents in one request
- **Near-Opus quality at lower cost** — close to the Opus tier on reasoning, tool use, coding, and knowledge work; prefer `sonnet` as default, reserve `opus` for orchestration and the hardest reasoning
- **Most agentic Sonnet yet** — stronger autonomous planning, browser/terminal tool use, sustained multi-step completion
- **Context awareness** — tracks remaining context window during long agentic loops
- **Stronger safety defaults** — lower hallucination/sycophancy, better prompt-injection resistance, cyber safeguards on by default
- **Same effort scale** — `low → medium → high → xhigh → max`; Sonnet 5 defaults to `high` (Opus 5.5 defaults to `medium`)
- **Pricing** — introductory $2/$10 per Mtok through 2026-08-31, then standard $3/$15

**Haiku is not used.** Every agent runs on `opus` or `sonnet`. With Sonnet 5 closing the gap to the Opus tier at lower cost, `sonnet` is the floor for lightweight work — never `haiku`. Opus 5.5 widens the gap on genuinely hard agentic coding, so `opus` is now more clearly worth it for multi-file features and large refactors.

## Surface Coverage — Claude Cowork (v3.14.0)

**Claude Cowork** — Anthropic's agentic surface for non-technical knowledge work, built on the Claude Code engine — now loads plugins as a research preview for all paid Claude users. Cowork went web + mobile for Max subscribers in July 2026, running in an isolated cloud environment so work survives closing your laptop.

**Nation of Elites installs into Cowork unchanged** — same marketplace entry, same `plugin.json`. Component support by surface:

| Component | Claude Code (CLI / Desktop / IDE) | Cowork | Claude Desktop & web chat |
|-----------|------|--------|---------------------------|
| Skills (33) | ✅ | ✅ | ✅ |
| Slash commands | ✅ | ✅ | ✅ |
| MCP connectors | ✅ | ✅ (via Anthropic cloud) | ✅ |
| **Agents (74)** | ✅ | ✅ | ❌ greyed out |
| **Hooks** | ✅ | ✅ | ❌ greyed out |

Agents and hooks run **only in Claude Code and Cowork**. In plain chat the skills and slash commands still work — which is why skills are the right home for portable knowledge.

**Cowork constraints:** connectors egress through Anthropic's cloud (internal-only MCP servers won't reach), plugins save locally per machine (org-wide marketplaces announced, not shipped), and Cowork's built-in `pdf`/`docx`/`pptx`/`xlsx`/`canvas-design` skills load automatically — don't duplicate them.

The **11_Business_Development**, **10_Content_and_Localization**, **02_Project_Management_Office**, and **01_Strategy_and_Planning** wings map most directly onto Cowork's audience. See [orchestration.md](docs/rules/orchestration.md) → *Claude Cowork*.

## Setup & Usage

See [README.md](README.md) for installation, deployment, quick-start examples, and troubleshooting.
