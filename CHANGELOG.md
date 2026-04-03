# Changelog

All notable changes to the Nation of Elites multi-agent system will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2026-04-03] - Humanizer Skill Integration (v3.8.1)

### Added

- **`humanizer`** skill (32nd custom skill) - Remove signs of AI-generated writing from text
  - Based on Wikipedia's "Signs of AI writing" guide maintained by WikiProject AI Cleanup
  - Detects 29 distinct patterns across 5 categories (content, language, style, communication, filler/hedging)
  - Voice calibration: match a user's personal writing style from samples
  - Multi-pass auditing: draft rewrite → AI-ism detection audit → final revision
  - Source: [blader/humanizer](https://github.com/blader/humanizer) (MIT license)

- **Humanizer preloaded on 9 agents** across 2 full divisions:
  - Content & Localization Wing (4): `book-author`, `book-editor`, `publishing-specialist`, `translation-localization-specialist`
  - Business Development Wing (5): `proposal-architect`, `social-media-strategist`, `lead-generation-specialist`, `client-success-manager`, `business-development-manager`

### Changed

- **skills-integration.md** - Added Content & Localization Wing and Business Development Wing agent-skill mappings
- **SKILLS.md** - Added humanizer skill documentation, updated agent-skill mapping, updated roadmap and counts
- **CLAUDE.md** - Added humanizer skill description and agent mappings
- **README.md** - Updated skills badge (31→32), version badge (3.8.0→3.8.1), Content/BD agent tables with skills column, skills library section
- **plugin.json** - Bumped to v3.8.1, updated description with 74 agents and humanizer

### Stats

- **Total Agents**: 74 (unchanged)
- **Total Skills**: 31 → 32 (+1 skill)
- **Agents with humanizer preloaded**: 0 → 9
- **Files Changed**: 14 (1 new skill + 9 agents + 4 docs)

---

## [2026-03-30] - Content Wing, BD Wing, Orchestrator Rename & Opus Upgrades (v3.8.0)

### Added

- **Content & Localization Wing** (Division 10) - 4 new agents:
  - `book-author` - Draft and structure books, chapters, outlines with narrative voice
  - `book-editor` - Review and refine manuscripts for clarity, consistency, grammar, pacing
  - `publishing-specialist` - Book formatting, platform requirements (KDP, IngramSpark), metadata, ISBNs
  - `translation-localization-specialist` - Translate documents across languages with cultural fidelity

- **Business Development Wing** (Division 11) - 6 new agents:
  - `business-development-manager` - BD pipeline, opportunity tracking, deal lifecycle, win/loss analysis
  - `lead-generation-specialist` - Prospecting, outreach sequences, lead scoring, nurture workflows
  - `proposal-architect` - RFP responses, proposal workflow, compliance matrices, win themes
  - `client-success-manager` - Client lifecycle, onboarding, retention, renewals
  - `market-intelligence-analyst` - Competitive intelligence, market analysis, pricing strategy
  - `social-media-strategist` - Multi-platform social content, paid ads, campaigns

### Changed

- **Orchestrator renamed**: `tech-lead-orchestrator` → `chief-operations-orchestrator` (canonical)
- **Model upgrades to opus**: All BD Wing agents (6), Content Wing agents (3: book-author, book-editor, translation-localization-specialist), plus key Strategy Wing agents (business-analyst, functional-analyst, product-manager)
- **README.md completely refreshed**: New banner image (banner_v2.jpeg), updated badges (74 agents, 12 divisions), complete agent roster tables with Simple Icons for all 12 divisions
- **Organization rule file**: Updated with Divisions 10 and 11, full roster

### Stats

- **Total Agents**: 64 → 74 (+10 agents)
- **Total Divisions**: 10 → 12 (+2 divisions)
- **New Divisions**: Content & Localization Wing, Business Development Wing
- **Agents upgraded to opus**: 9+

---

## [2026-03-27] - Official Plugin Integrations, Agent Teams & README Overhaul (v3.7.0)

### Added

- **Official plugin autoconfiguration** in deploy scripts (bash + PowerShell)
  - Interactive setup for 12 official Anthropic plugins: GitHub, Slack, Jira, Linear, Figma, Sentry, Vercel, Firebase, Supabase, Notion, Confluence, Asana
  - Agent-to-plugin mapping documented in orchestration rules
  - Non-interactive fallback with manual install instructions

- **Agent Teams documentation** (experimental feature)
  - Enable via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
  - Detailed comparison table (Agent Teams vs Subagents)
  - Hook events: `TeammateIdle`, `TaskCreated`, `TaskCompleted`
  - Known limitations documented (session resume, nested teams, lead transfer)
  - Best practices: 3-5 teammates, 5-6 tasks each

- **New subagent features** documented in orchestration rules and standards:
  - `maxTurns` frontmatter field for cost control
  - `isolation: worktree` for git worktree isolation
  - MCP Elicitation support (servers request user input mid-workflow)
  - Hook `if` field (v2.1.85+) for permission-rule syntax filtering
  - LSP servers in plugins via `.lsp.json`
  - `effort` field for per-agent reasoning depth override
  - `mcpServers` field for scoped MCP server definitions

### Changed

- **README.md completely rewritten** with modern GitHub styling:
  - Shield badges (agents, divisions, skills, SDK compliance, version, license)
  - Complete agent roster table organized by department with Simple Icons
  - Collapsible sections for each division with icons
  - Official plugin integrations table
  - Streamlined quick start, documentation, and contributing sections

- **orchestration.md** expanded with:
  - Agent Teams experimental flag and configuration
  - Official plugin integrations table (12 plugins with agent mappings)
  - Subagent advanced features (maxTurns, worktree, elicitation, LSP, hooks)

- **standards.md** updated to Mar 2026 spec:
  - Added `effort`, `mcpServers`, and `if` hook fields to template
  - New field priority guidelines for maxTurns, isolation, mcpServers, effort

- **CLAUDE.md** updated with v3.7.0 features:
  - Official Plugin Integrations section
  - Agent Teams (experimental) section
  - New Subagent Features section

- **plugin.json** bumped to 3.7.0 with updated description and keywords

- **Deploy scripts** (bash + PowerShell) now include plugin autoconfiguration step

### Stats

- **Total Agents**: 64 (unchanged)
- **Total Skills**: 31 (unchanged)
- **Official Plugins Supported**: 0 -> 12
- **New Frontmatter Fields Documented**: 5 (maxTurns, effort, mcpServers, isolation details, hook if)
- **Files Changed**: 8 (README.md, CLAUDE.md, CHANGELOG.md, plugin.json, orchestration.md, standards.md, deploy_agents.sh, deploy_agents.ps1)

---

## [2026-03-14] - Semgrep SAST & Universal Pipelines (v3.6.0)

### Added

- **`semgrep-sast`** skill - Semgrep SAST scanning via CLI and MCP plugin integration
  - Default, OWASP, and secrets rule packs
  - Custom rule writing with pattern operators
  - Supply chain / dependency vulnerability scanning
  - CI/CD integration templates (GitHub Actions)
  - Severity mapping to NoE quality gates

- **`pipeline-quality`** skill - Universal quality gate pipeline
  - Auto-detects project stack (Python, Node, Rust, Go, Ruby, PHP, Java)
  - 6-step gate: lint, type check, Semgrep SAST, tests, supply chain, dependency audit
  - Desktop (Electron+Python) and cloud (web/API) variants

- **`pipeline-full-build`** skill - Universal full build pipeline
  - 8-step pipeline: version bump, quality gate, build, compile, package, CI, release, post-release
  - Desktop variant (Electron packaging) and cloud variant (Docker/K8s)

### Changed

- **Agent updates** - Added Semgrep and pipeline skills to 5 agents:
  - `cyber-sentinel`: +semgrep-sast
  - `code-reviewer`: +semgrep-sast, +pipeline-quality (plus Semgrep in automated pass workflow)
  - `qa-engineer`: +semgrep-sast, +pipeline-quality
  - `automated-test-scripter`: +semgrep-sast
  - `devops-engineer`: +semgrep-sast, +pipeline-quality, +pipeline-full-build

- **Deployment scripts** - Both bash and PowerShell now:
  - Check for Semgrep CLI installation and token configuration
  - Validate semgrep-sast and pipeline skills deployment
  - Report Semgrep status in deployment output

- **`pr-ready`** skill updated with Semgrep SAST scan step in security checks
- **`security-audit`** skill updated with Semgrep reference in static analysis tools

### Stats

- **Total Agents**: 64 (unchanged)
- **Total Skills**: 28 -> 31 (+3 skills)
- **Agents updated**: 5

---

## [2026-03-13] - Revit BIM Expert & Standards Alignment (v3.5.1)

### Added

- **`revit-bim-expert`** agent (64th agent) - Revit API specialist: pyRevit IronPython/C# scripting, Dynamo visual programming, Autodesk Platform Services (APS/Forge) cloud workflows, MCP connectors for Claude-to-Revit integration
- Updated Chief Operations Orchestrator delegation table with Revit BIM routing

### Fixed

- **Standards alignment**: Corrected agent counts across all documentation
  - Framework Specialists: 16 -> 19
  - Engineering Division: 25 -> 31
  - Total agents: 63 -> 64
- **Missing `permissionMode: acceptEdits`** on `autodesk-cloud-construction-expert` and `construction-ai-orchestrator`

### Changed

- **CLAUDE.md optimized**: Reduced from 329 -> 56 lines (85% token reduction) while preserving all essential information
- **Organization rule file**: Updated agent counts and added Revit BIM Expert to roster

### Stats

- **Total Agents**: 63 -> 64 (+1 agent)
- **Engineering Division**: 25 -> 31 agents (corrected count)
- **Framework Specialists**: 16 -> 19 (corrected count)
- **Files changed**: 14 (1 new agent + 13 modified)

---

## [2026-03-01] - Silent Failure Audit Skill (v3.5.0)

### Added

- **`silent-failure-audit`** skill - Cross-project truthfulness verification for status/health/detection code
  - Automatically loaded by `code-reviewer`, `cyber-sentinel`, `qa-engineer`, and `automated-test-scripter`
  - Detects code that passes tests but lies about reality (phantom detections, mock-only validation, silent swallowing)
  - No per-project CLAUDE.md changes required - the skill travels with the agents

### Stats

- **Total Agents**: 63 (unchanged)
- **Total Skills**: 27 -> 28 (+1 skill)

---

## [2026-02-22] - Official Spec Compliance, Persistent Memory & Skills Preloading (v3.4.0)

### Major Update - Feb 2026 Official Spec Alignment

Full audit against official Anthropic documentation (Feb 2026), 6+ popular community repos (wshobson/agents, VoltAgent, affaan-m, 0xfurai), and Claude Code CLI v2.1.50 spec. Updated 28 agent files and 2 documentation files.

### Added - Persistent Agent Memory (7 agents)

- **`chief-operations-orchestrator`**: `memory: project` - Remembers decisions, team assignments, project context
- **`code-reviewer`**: `memory: project` - Remembers code patterns, style conventions, recurring issues
- **`cyber-sentinel`**: `memory: project` - Remembers vulnerabilities found, security patterns, scan history
- **`functional-analyst`**: `memory: project` - Remembers FSD, acceptance criteria, domain glossary
- **`code-archaeologist`**: `memory: project` - Remembers codebase structure and previous findings
- **`integration-specialist`**: `memory: project` - Remembers integration configs and MCP server patterns
- **`catia-design-expert`**: `memory: project` - Remembers design patterns and MCP connector configs

### Added - Skills Preloading (18 agents)

Framework specialists now preload matching skills at startup via `skills:` frontmatter:

- `django-expert` -> `django-patterns`
- `react-expert` -> `react-patterns`
- `vue-expert` -> `vue-patterns`
- `nextjs-expert` -> `nextjs-patterns`
- `rails-expert` -> `rails-patterns`
- `java-expert` -> `java-patterns`
- `go-expert` -> `go-patterns`
- `laravel-expert` -> `laravel-patterns`
- `react-typescript-expert` -> `react-patterns, typescript-patterns`
- `tailwind-css-expert` -> `tailwind-patterns`
- `antd-ui-developer` -> `antd-patterns`
- `crypto-api-developer` -> `crypto-defi-patterns`
- `financial-systems-expert` -> `financial-trading-patterns`
- `cyber-sentinel` -> `security-audit`
- `devops-engineer` -> `github-actions, kubernetes-deployment`
- `cloud-architect` -> `terraform-patterns`
- `qa-engineer` -> `pytest-patterns`
- `automated-test-scripter` -> `pytest-patterns`

### Added - Permission Modes (16 agents)

All code-writing framework specialists now use `permissionMode: acceptEdits` for frictionless development flow.

### Added - CATIA MCP Connector Support

Enhanced `catia-design-expert` with 90+ lines covering:
- **CATIA v5 connector**: COM/VBA automation via Python (pywin32) or Node.js MCP server
- **CATIA v6 connector**: 3DEXPERIENCE REST API via HTTP-based MCP server
- **MCP tool definitions**: `catia_open_part`, `catia_add_feature`, `catia_run_ekl`, `catia_export`, etc.
- **MCP resource definitions**: `catia://parameters`, `catia://feature-tree`, etc.
- **Development workflow**: 8-step process from assessment to documentation
- **Delegation to `integration-specialist`** for MCP scaffolding and OAuth

### Changed - Model Optimization

- **`integration-specialist`**: `model: opus` -> `model: sonnet` (integration work doesn't need opus-level reasoning)

### Changed - Description Improvements

- **`cyber-sentinel`**: Added "Use PROACTIVELY for security audits" trigger and memory note
- **`integration-specialist`**: Added "Use when connecting to external APIs" trigger and memory note

### Changed - Documentation Updates

- **`docs/rules/standards.md`**: Updated agent format template with full Feb 2026 official spec (memory, skills, permissionMode, hooks, isolation, background, maxTurns)
- **`docs/rules/agent-selection.md`**: Added "New Features (Feb 2026)" section documenting persistent memory, skills preloading, and permission modes
- **`CLAUDE.md`**: Added v3.4 features summary table
- **`plugin.json`**: Version bumped to 3.4.0, updated description

### Stats

- **Total Agents**: 63 (unchanged)
- **Agents with `memory: project`**: 0 -> 7
- **Agents with `skills:` preloading**: 0 -> 18
- **Agents with `permissionMode:`**: 0 -> 16
- **Files changed**: 30 (28 agents + 2 docs)
- **Lines added**: 475+
- **Model cost optimization**: 1 agent demoted from opus to sonnet

---

## [2026-02-14] - Anthropic Best Practices Alignment & New Agents (v3.3.0)

### 🏗️ Major Update - Modular Rules Architecture & Opus 4.6 Alignment

This release restructures CLAUDE.md into modular rule files per Anthropic's latest best practices, adds two new specialist agents, and integrates Opus 4.6 features including Agent Teams and adaptive thinking.

### Added - Modular Rule Files (7 files)

- **`docs/rules/organization.md`** (46 lines) - Division structure and full agent roster
- **`docs/rules/orchestration.md`** (73 lines) - Agent Teams, subagent coordination, context compaction, adaptive thinking
- **`docs/rules/thinking-policies.md`** (40 lines) - Reasoning budgets (100-800 tokens) per role
- **`docs/rules/sdk-compliance.md`** (66 lines) - Claude Agent SDK alignment, Opus 4.6 features, server-side tools
- **`docs/rules/agent-selection.md`** (70 lines) - Division selection guide and invocation patterns
- **`docs/rules/skills-integration.md`** (46 lines) - Skills vs agents, progressive disclosure, agent-skill mapping
- **`docs/rules/standards.md`** (58 lines) - Agent format standards, documentation standards, strict tool use

### Added - New Agents (2)

- **`rust-expert`** - Rust programming specialist: ownership/borrowing, zero-cost abstractions, async/await, unsafe boundary documentation, clippy/audit workflows
- **`unreal-engine-expert`** - Unreal Engine 5 specialist: C++ gameplay programming, Blueprints, Nanite/Lumen rendering, GAS multiplayer, World Partition, cross-platform deployment

### Added - Opus 4.6 Features

- **Agent Teams**: Parallel multi-agent coordination beyond simple subagent spawning (documented in orchestrator and orchestration rules)
- **Adaptive Thinking**: Effort levels (low/medium/high/maximum) for dynamic reasoning depth
- **Strict Tool Use**: `strict: true` schema validation for guaranteed tool input conformance
- **Server-Side Tools**: `web_search_20250305` and `web_fetch_20250305` documentation
- **MCP Connector**: Direct remote MCP server connections without client implementation
- **Context Compaction API**: Server-side beta feature noted alongside manual compaction

### Changed - CLAUDE.md Refactored

- **Reduced from 738 → 206 lines** — now a lightweight index pointing to 7 modular rule files
- **Structured memory pattern** — Identity & Voice (CLAUDE.md) → Facts & Canon (rule files) → Working Notes (PLAN.md, CHANGELOG.md)
- **UE5 quick start example** added to invocation patterns

### Changed - Chief Operations Orchestrator Enhanced

- Agent Teams section with comparison table (Agent Teams vs Subagents)
- Adaptive thinking capability with effort levels
- Routing rules for `rust-expert` and `unreal-engine-expert`
- Delegation table entries for both new agents

### Fixed - Documentation Accuracy

- **Agent count**: SKILLS.md corrected from 45 → 63
- **Roadmap**: v3.1 and v3.2 marked as released, v4.0 added as next milestone
- **Engineering Division count**: Updated across all docs to reflect new agents

### Stats 📈

- **Total Agents**: 61 → 63 (+2 agents)
- **Total Rule Files**: 0 → 7 (new modular architecture)
- **CLAUDE.md Size**: 738 → 206 lines (72% reduction)
- **Opus 4.6 Features**: 6 new capabilities documented
- **Engineering Division**: 23 → 25 agents
- **Framework Specialists**: 14 → 16 agents

---

## [2026-01-24] - Claude Code v2.1.x Alignment (v3.2.0)

### 🔧 Major Update - Full Claude Code v2.1.x Compliance

This release ensures complete compatibility with Claude Code v2.1.x plugin and skills systems, following official Anthropic documentation and format requirements.

### Fixed - Plugin Structure Compliance

- **Plugin manifest renamed**: `.claude-plugin/manifest.json` → `.claude-plugin/plugin.json` (official format)
- **Removed non-standard files**: `marketplace.json` moved out of plugin directory
- **Simplified plugin.json**: Now contains only official schema fields

### Fixed - Agent Name Conflicts

- **Renamed conflicting agents** to avoid collision with Claude Code built-ins:
  - `general-purpose` → `noe-general-purpose`
  - `statusline-setup` → `noe-statusline-setup`

### Fixed - Tool Validation (61 agents updated)

- **Removed invalid tools**: `LS` (use `Glob` instead), `MultiEdit` (use `Edit`)
- **All agents now use only valid Claude Code tools**: `Read`, `Grep`, `Glob`, `Bash`, `Write`, `Edit`

### Added - Model Specifications (61 agents)

- **Added `model` field to all agents** based on complexity:
  - `opus`: Orchestrators, architects, executives, strategists (10 agents)
  - `sonnet`: All other specialists and developers (51 agents)

### Changed - Description Format

- **Simplified descriptions**: Removed verbose "MUST BE USED when" and "Use PROACTIVELY when" patterns
- **Removed legacy syntax**: Eliminated all `@agent-` references (Claude Code v2 auto-selects agents)
- **Removed Examples sections**: Descriptions now follow official code-simplifier format
- **Removed contact/promotion sections** from agent files

### Added - New Workflow Skills (3)

- **feature-workflow**: Complete 7-phase development workflow (plan → implement → test → validate → simplify → review → document)
- **quick-fix**: Rapid 4-step bug fix workflow
- **pr-ready**: Enhanced PR workflow with git commit, push, PR creation, and optional release

### Added - New Framework Skills (7)

- **nodejs-patterns**: Async patterns, streams, worker threads, error handling
- **python-patterns**: Type hints, async/await, dataclasses, modern Python 3.12+
- **fastapi-patterns**: FastAPI best practices, dependency injection, async database
- **express-patterns**: Express.js middleware, error handling, authentication
- **typescript-patterns**: Advanced types, generics, utility types, type guards
- **vite-patterns**: Build configuration, plugins, optimization, testing
- **zustand-patterns**: State management, slices pattern, middleware, persistence

### Removed - Redundant Files

- `CHANGELOG_v3.1.0.md` - Content merged into main CHANGELOG.md
- `docs/SDK_ALIGNMENT_TODO.md` - All items completed
- `docs/SDK_ALIGNMENT_SUMMARY.md` - Redundant with SDK_COMPLIANCE_REPORT.md
- `marketplace.json` (root) - No longer needed with proper plugin.json

### Stats 📈

- **Total Agents**: 61 (unchanged)
- **Total Skills**: 20 → 27 (+7 skills)
- **Workflow Skills**: 0 → 3 (new)
- **Framework Skills**: 17 → 24 (+7)
- **Model-specified Agents**: 0 → 61 (100%)
- **Plugin Schema Compliance**: Full alignment with Claude Code v2.1.x

---

## [2025-10-28] - Agent Skills Integration (v3.0.0)

### 🎓 Major Release - Agent Skills System

This release introduces **Agent Skills** - a revolutionary approach to extending agent capabilities through procedural knowledge packages that use progressive disclosure to minimize context overhead while maximizing expertise.

### Added - Skills Infrastructure 📚

- **Agent Skills System** (`~/.claude/skills/`)
  - Progressive 3-level disclosure architecture (metadata → instructions → resources)
  - Executable Python/JavaScript code for deterministic operations
  - Modular expertise packages for domain-specific knowledge
  - Automatic skill discovery and loading by Claude based on task relevance
  - Zero context overhead until skill is needed

- **Official Anthropic Skills** (Automatically Installed)
  - **pdf** - PDF manipulation, form filling, extraction, merging
  - **docx** - Word document creation, editing, formatting
  - **pptx** - PowerPoint presentation generation and styling
  - **xlsx** - Excel operations with formulas, charts, data validation
  - **mcp-builder** - MCP server development guidance and templates
  - **webapp-testing** - Playwright-based UI testing automation
  - **skill-creator** - Interactive skill development assistant
  - **artifacts-builder** - Complex HTML artifacts with React/Tailwind
  - **canvas-design** - Visual art creation in PNG/PDF formats

- **Custom Nation of Elites Skills** (Included in Repo)
  - **django-patterns** - Django best practices, ORM optimization, REST API patterns
  - **react-patterns** - React architecture, hooks patterns, performance optimization
  - **security-audit** - OWASP Top 10 checklist, security hardening procedures
  - **github-actions** - CI/CD pipeline templates and deployment workflows

- **New Documentation**
  - `SKILLS.md` - Comprehensive Agent Skills system documentation
  - Skills integration section in `CLAUDE.md`
  - Skills overview in `README.md`
  - v3.0 migration guide in `MIGRATION_GUIDE.md`

### Changed - Enhanced Agent Capabilities 🚀

**Deployment Script Enhancement:**
- `scripts/deploy_agents.sh` now installs both agents AND skills
- Automatic cloning of Anthropic's official skills repository
- Skills validation and installation verification
- Optional skills installation with graceful fallback

**Agent Enhancements (Non-Breaking):**
- **Documentation Specialist** → Can now create/edit PDF, Word, PowerPoint, Excel
- **QA Engineer** → Can use Playwright for automated UI testing
- **Integration Specialist** → Can scaffold MCP servers with templates
- **Django Expert** → Accesses django-patterns for framework best practices
- **React Expert** → Accesses react-patterns for component architecture
- **DevOps Engineer** → Uses github-actions templates for CI/CD
- **Cyber Sentinel** → Uses security-audit checklists for vulnerability scanning
- **Chief Operations Orchestrator** → Uses skill-creator for new capability development

**Documentation Updates:**
- `CLAUDE.md` - Added comprehensive "Agent Skills Integration (v3.0)" section
- `README.md` - Added "Agent Skills System (v3.0)" with usage examples
- `MIGRATION_GUIDE.md` - Added v2.0 → v3.0 upgrade path
- Updated version to v3.0 in all documentation

### Technical - Skills Architecture ⚙️

**Progressive Disclosure Model:**
1. **Level 1 (Always Loaded)**: Skill name and description (minimal context)
2. **Level 2 (When Relevant)**: Full `SKILL.md` with procedures and guidance
3. **Level 3 (On-Demand)**: Additional resources, scripts, templates

**Code Execution Integration:**
- Skills can bundle executable scripts (Python, JavaScript)
- Deterministic operations bypass expensive token generation
- Scripts execute via Code Execution Tool without loading into context
- Example: PDF form extraction runs Python script without context overhead

**Agent + Skills Architecture:**
```
Agents (Who performs work)
  └─> USE Skills (What knowledge they access)
      └─> Progressive Loading (Only what's needed)
```

**Directory Structure:**
```
~/.claude/
├── agents/        # 45 specialized agents (unchanged)
└── skills/        # Skill library (NEW)
    ├── pdf/
    ├── docx/
    ├── xlsx/
    ├── django-patterns/
    ├── react-patterns/
    ├── security-audit/
    └── github-actions/
```

### Benefits - Why Skills Matter 🎁

1. **Context Efficiency**: Unlimited skill library without context bloat
2. **Specialized Knowledge**: Domain-specific expertise on-demand
3. **Deterministic Tools**: Executable code for reliable operations
4. **Modular Expertise**: Reusable knowledge packages across projects
5. **Composability**: Skills stack together for complex tasks
6. **Portability**: Same skills work in Claude.ai, Claude Code, and API

### Migration Path for v2.0 Users 🛤️

**Automatic Upgrade (Recommended):**
```bash
# Pull latest version
git pull origin main

# Redeploy (automatically installs skills)
bash scripts/deploy_agents.sh
```

**Manual Skills Installation:**
```bash
# Clone Anthropic's skills
git clone https://github.com/anthropics/skills.git /tmp/skills

# Install specific skills
mkdir -p ~/.claude/skills
cp -r /tmp/skills/document-skills/* ~/.claude/skills/
cp -r /tmp/skills/{mcp-builder,webapp-testing,skill-creator} ~/.claude/skills/

# Install Nation of Elites custom skills
cp -r skills/* ~/.claude/skills/
```

### Breaking Changes ❌

**None** - This release maintains full backward compatibility with v2.0:
- ✅ All 45 agents unchanged
- ✅ Agent names unchanged
- ✅ Directory structure unchanged (skills are additive)
- ✅ All invocation patterns still work
- ✅ No configuration changes required
- ✅ Skills are optional enhancement (agents work without them)

### Security Considerations 🔒

**Skills Security Model:**
- Skills can execute code and provide procedural guidance
- **Risk**: Malicious skills could introduce vulnerabilities
- **Mitigation**: Only install from trusted sources
- **Best Practice**: Audit skill contents before installation

**Trusted Sources:**
- ✅ Official Anthropic skills: `github.com/anthropics/skills`
- ✅ Nation of Elites custom skills: Included in this repo
- ⚠️ Community skills: Audit thoroughly before use

### Future Roadmap 🔮

- **v3.1**: Additional custom skills (Laravel, Vue, Next.js patterns)
- **v3.2**: Skills marketplace and community contributions
- **v3.3**: Agent self-modification (agents create/edit their own skills)
- **v4.0**: Skill composition and dependency management

---

## [2025-10-15] - Claude Code v2 Plugin System Migration (v2.0.0)

### 🎯 Major Release - Plugin System Integration

This release transforms Nation of Elites into a **Claude Code v2 plugin**, providing one-command installation, automatic updates, and seamless integration with the new Claude Code plugin ecosystem.

### Added - Plugin Infrastructure 🔌

- **Plugin Manifest** (`.claude-plugin/manifest.json`)
  - Complete metadata for 45 agents across 7 divisions
  - Version tracking (v2.0.0)
  - Feature flags for SDK compliance
  - Division structure documentation
  - Agent path mappings for automatic loading

- **Marketplace Configuration** (`.claude-plugin/marketplace.json`)
  - Official marketplace entry for public distribution
  - Multiple preset configurations (Full Suite, Core, Frontend, Backend, DevOps, AI/ML)
  - Category classification for easy discovery
  - Installation command variants
  - Support documentation links

- **Migration Guide** (`MIGRATION_GUIDE.md`)
  - Comprehensive v1.x → v2.0 upgrade path
  - Feature comparison table
  - Breaking changes documentation (none - fully backward compatible)
  - Common migration issues and solutions
  - Command translation reference

- **Contributing Guide** (`CONTRIBUTING.md`)
  - Community contribution guidelines
  - Agent development standards
  - Testing procedures
  - PR submission process
  - Style guide and best practices

### Changed - Installation & Invocation Patterns 🚀

**Installation Methods:**
- **Recommended**: Automated deployment script: `bash scripts/deploy_agents.sh` (works immediately for all users)
- **Plugin System**: Clone to `~/.claude/plugins/nation-of-elites/` or `/plugin install` when marketplace is indexed
- **Manual**: Direct copy to `~/.claude/agents/` (still fully supported)

**Agent Invocation:**
- **NEW (Recommended)**: Natural language - Claude automatically selects agents via Task tool
  ```bash
  claude "Design the system architecture for this microservices platform"
  # Automatically spawns solution-architect
  ```
- **Legacy**: Explicit agent mentions still supported for backward compatibility
  ```bash
  claude "Use @agent-solution-architect to design the system architecture"
  ```

### Documentation Updates 📚

**README.md:**
- Updated Quick Start with plugin installation as primary method
- Added v2 vs v1 installation comparison
- New "Using the Agents" section with natural language examples
- Plugin verification instructions

**CLAUDE.md:**
- Added plugin installation section with `/plugin` commands
- Updated agent invocation patterns (v2 vs v1)
- Added verification steps for plugin loading
- Updated communication protocols (Task tool vs @agent mentions)
- Comprehensive usage examples for both invocation patterns

**New Documentation:**
- `MIGRATION_GUIDE.md` - v1 to v2 upgrade guide
- `CONTRIBUTING.md` - Community contribution guidelines
- `.claude-plugin/manifest.json` - Plugin metadata
- `.claude-plugin/marketplace.json` - Marketplace configuration

### Technical - Plugin System Integration ⚙️

**Backward Compatibility:**
- ✅ All 45 agents unchanged
- ✅ Agent names unchanged
- ✅ Directory structure unchanged
- ✅ Explicit `@agent-name` invocation still works
- ✅ Manual installation still supported

**New Capabilities:**
- **Plugin Management**: Enable/disable per project with `/plugin enable|disable`
- **Automatic Updates**: Plugin system handles version updates
- **Reduced Context**: Plugin toggling reduces context overhead
- **Marketplace Discovery**: Listed in Claude Code plugin marketplace
- **Installation Verification**: `/plugin list` shows active plugins

**Installation Paths:**
- **Plugin (v2)**: `~/.claude/plugins/nation-of-elites/`
- **Manual (v1)**: `~/.claude/agents/` (legacy, still supported)

### Benefits - Why Upgrade to v2 Plugin System 🎁

1. **Faster Setup**: `/plugin install` vs multi-step manual deployment
2. **Auto Updates**: Plugin system handles updates automatically
3. **Better UX**: Natural language invocation vs explicit agent mentions
4. **Context Control**: Toggle plugins on/off to reduce overhead
5. **Discovery**: Browse in plugin marketplace
6. **Community**: Easier for others to find and install

### Migration Path for Existing Users 🛤️

**Recommended for All Users:**
```bash
# Clone the latest version
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites

# Deploy (overwrites v1.x with v2.0)
bash scripts/deploy_agents.sh
```

**Alternative - Plugin Installation (when marketplace is live):**
```bash
# Clone to plugins directory
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git ~/.claude/plugins/nation-of-elites

# Or from marketplace (when indexed)
/plugin install advisely/claude-code-agents-team-nation-of-elites
```

See `MIGRATION_GUIDE.md` for detailed instructions and options.

### Breaking Changes ❌

**None** - This release maintains full backward compatibility with v1.x:
- Manual installation still works
- Explicit agent mentions still work
- All agents unchanged
- No configuration changes required

Users can choose to adopt plugin installation at their convenience.

---

## [2025-09-29] - Claude Agent SDK Full Alignment (v1.x)

### Added - SDK Alignment Features ⭐
- **Subagent Coordination**: Chief Operations Orchestrator can now spawn 3-5 temporary, task-specific subagents for parallel information gathering
  - Isolated context windows for each subagent
  - Descriptive naming convention (e.g., `subagent-search-logs-morning`)
  - Explicit lifecycle documentation (Created → Execute → Report → Terminate)
- **Context Compaction**: Automatic summarization triggers at 80% context usage
  - Program Manager, Product Manager, and Chief Operations Orchestrator equipped with compaction strategies
  - Information hierarchy: Critical → Important → Archivable
  - Before/after compaction examples with quantifiable token savings (47% reduction)
- **File System Context Engineering**: New comprehensive guide (CONTEXT_ENGINEERING.md)
  - Bash command patterns for efficient large file handling (grep, head, tail)
  - Hot/warm/cold file organization strategies
  - Subagent patterns for parallel file processing
- **MCP Integration**: New Integration Specialist agent for Model Context Protocol servers
  - Relocated to 07_Orchestrators as cross-cutting coordinator
  - Covers 15+ external services (Slack, GitHub, Google Drive, Jira, databases)
  - OAuth flow handling and authentication management
- **Visual Feedback Loops**: Enhanced Visual Regression Specialist
  - Development-time visual verification checkpoints
  - Screenshot-based validation during UI development
  - Multi-viewport testing with parallel subagents
- **Code Generation Priority**: Backend Developer emphasizes code over configuration
  - Generate vs Configure philosophy
  - Automation as code, rules as code, infrastructure as code

### Changed
- **Integration Specialist**: Moved from `05_SecOps_and_Infrastructure_Division/` to `07_Orchestrators/`
  - Recognized as cross-cutting coordination role
  - Division 05: 7 agents → 6 agents
  - Division 07: 2 agents → 3 agents (Tech Lead, Team Configurator, Integration Specialist)
- **Chief Operations Orchestrator**: Enhanced with subagent coordination and context compaction capabilities
- **Program Manager**: Added context management triggers and subagent spawning patterns
- **Product Manager**: Added context management triggers and parallel market research patterns
- **Visual Regression Specialist**: Expanded mission to include development-time feedback
- **Backend Developer**: Added "Code Generation First" approach section

### Documentation
- **New Files**:
  - `CONTEXT_ENGINEERING.md` - Comprehensive context management best practices
  - `SDK_ALIGNMENT_SUMMARY.md` - Complete implementation summary
  - `SDK_ALIGNMENT_TODO.md` - Implementation tracking document
  - `SDK_COMPLIANCE_REPORT.md` - Final 10/10 compliance certification
- **Updated Files**:
  - `README.md` - Added SDK aligned features section, updated agent counts
  - `CLAUDE.md` - Added 07_Orchestrators section, updated organizational structure
  - `AGENT_WORKFLOW.md` - Added SDK alignment features appendix
  - All modified agent files with context management and delegation patterns

### Technical
- **SDK Compliance Score**: 9.5/10 → 10/10 ⭐⭐⭐⭐⭐
- **Agent Count**: 45 specialized agents (no change, but Integration Specialist relocated)
- **Architecture Improvements**:
  - Temporary subagent model with clear lifecycle management
  - Practical before/after compaction examples with token metrics
  - Integration Specialist positioned as orchestrator for clarity
- **Best Practices Alignment**:
  - ✅ Agent Feedback Loop (complete)
  - ✅ Subagent Parallelization (complete with lifecycle)
  - ✅ Context as File System (complete with examples)
  - ✅ MCP External Services (complete with orchestrator)
  - ✅ Visual Feedback (complete with dev-time checkpoints)
  - ✅ Code Generation Priority (complete)
  - ✅ Context Compaction (complete with examples)

### Rationale
This major release achieves **full alignment** with Anthropic's Claude Agent SDK best practices while preserving the unique "Nation of Elites" hierarchical structure. Key improvements focus on:
1. **Efficiency**: Parallel processing through subagents, context compaction for longer sessions
2. **Integration**: MCP support for seamless external service connections
3. **Quality**: Real-time visual feedback, code generation emphasis
4. **Clarity**: Explicit agent roles, temporary vs permanent agent distinction

---

## [2025-09-27] - Ant Design UI Specialist Addition

### Added
- **antd-ui-developer** - New Framework Specialist for Ant Design React UI development
  - Deep expertise in Ant Design component customization and theming
  - Enterprise-grade interface design patterns and best practices
  - Integration with existing React specialists (react-expert, react-typescript-expert)
  - Medium-Low complexity thinking budget (200-300 tokens)
  - Automatic documentation update capabilities

### Changed
- **Nation of Elites workforce expansion**: 44 → 45 specialized agents
- **Engineering Division**: 20 → 21 agents total
- **Framework Specialists**: 13 → 14 specialist agents
- **Enhanced Specialization**: Added Ant Design UI expertise to the team capabilities

### Technical
- Added comprehensive delegation patterns for React ecosystem coordination
- Implemented proper YAML frontmatter and agent format standards
- Integrated automatic documentation update mechanisms
- Established thinking policy compliance with orchestrator budgets

### Documentation
- Updated CLAUDE.md organizational structure and agent counts
- Updated Framework Specialists listing with antd-ui-developer
- Updated Quality Metrics to reflect expanded team capabilities
- Created CHANGELOG.md for tracking future modifications

---

**Orchestration Completed**: chief-operations-orchestrator successfully delegated agent creation and documentation updates per approved business directive.
