# Skills Integration

## Skills vs Agents: Complementary Systems

| Aspect | Agents | Skills |
|--------|--------|--------|
| **Role** | Team members (orchestrators & specialists) | Training manuals & toolkits |
| **Location** | `~/.claude/agents/` | `~/.claude/skills/` |
| **Purpose** | Who performs work | What knowledge they access |
| **Loading** | Task-based spawning | Progressive disclosure (3 levels) |
| **Format** | Markdown with YAML frontmatter | `SKILL.md` with bundled resources |

**Key Principle**: Agents USE skills. A Backend Developer (agent) might invoke `django-patterns` (knowledge) or `xlsx` (tool).

## Progressive Disclosure Architecture

1. **Level 1: Metadata** (Always loaded) - Skill name and description in system prompt
2. **Level 2: Core Instructions** (Loaded when relevant) - Full `SKILL.md` with procedures
3. **Level 3: Additional Resources** (On-demand) - Referenced files, scripts, templates

## Agent-Skill Mapping

**Engineering Division:**
- `backend-developer`, `django-expert`, `laravel-expert` → Framework pattern skills
- `frontend-developer`, `react-expert`, `vue-expert` → UI framework skills
- `documentation-specialist` → pdf, docx, pptx skills

**Quality Assurance:**
- `qa-engineer`, `automated-test-scripter` → pytest-patterns, silent-failure-audit, semgrep-sast skills
- `visual-regression-specialist` → canvas-design, artifacts-builder skills
- `code-reviewer` → semgrep-sast, silent-failure-audit, pipeline-quality skills

**SecOps & Infrastructure:**
- `devops-engineer` → github-actions, kubernetes-deployment, semgrep-sast, pipeline-quality, pipeline-full-build-cloud, pipeline-full-build-desktop skills
- `cyber-sentinel` → security-audit, silent-failure-audit, semgrep-sast skills

**Content & Localization Wing:**
- `book-author`, `book-editor`, `publishing-specialist`, `translation-localization-specialist` → humanizer skill

**Business Development Wing:**
- `proposal-architect`, `social-media-strategist`, `lead-generation-specialist`, `client-success-manager`, `business-development-manager` → humanizer skill

**Orchestrators:**
- `integration-specialist` → mcp-builder skill for external integrations
- `chief-operations-orchestrator` → skill-creator for new capability development; council-of-experts for complex or multi-artifact reviews

**Council seats (council-of-experts):**
- `functional-analyst` → scribe for spec, AC, and traceability questions
- `code-reviewer` → gate seat when code is in scope
- `cyber-sentinel` → gate seat when security is in scope

## Workflow Skills

34 custom skills ship in `skills/`. The workflow skills run in the main session and orchestrate agents rather than adding knowledge:

| Skill | Use |
|-------|-----|
| `feature-workflow` | 7-phase feature build with quality gates |
| `quick-fix` | 4-step diagnose, fix, test, output |
| `pr-ready` | Quality checks, commit, push, PR, optional release |
| `council-of-experts` | Standard way to convene a panel of experts: 3-5 roster agents chosen by artifact type, independent review, one cross-critique round, ranked verdict. Runs in the main session so the user can steer; an optional Haiku 5.5 pre-read gathers facts only, never a panel seat |

## Cross-Surface Availability

Skills are the **most portable** component of the plugin — they run everywhere plugins load, including plain chat where agents and hooks do not:

| Surface | Skills | Agents |
|---------|--------|--------|
| Claude Code (CLI / Desktop / IDE) | ✅ | ✅ |
| Claude Cowork | ✅ | ✅ |
| Claude Desktop & web chat | ✅ | ❌ greyed out |

This makes skills the right home for knowledge that must survive outside an agentic session. Two consequences:

- **Don't duplicate Cowork's built-ins.** Cowork ships `pdf`, `docx`, `pptx`, `xlsx`, and `canvas-design` skills that load automatically for those file types. Custom skills should carry judgment (`humanizer`, `pipeline-quality`, `silent-failure-audit`), not file-format mechanics.
- **Frontmatter parsing is now tolerant** (Claude Code 2.1.186+): `display-name`, `default-enabled`, `fallback`, and `metadata.*` accept kebab-case, snake_case, and camelCase, and a malformed `SKILL.md` loads with empty metadata instead of failing. Existing skills need no changes.

## Security Considerations

- **Risk**: Malicious skills could introduce vulnerabilities or exfiltrate data
- **Mitigation**: Only install skills from trusted sources; audit contents before installation
- **Trusted Sources**: Official Anthropic (`github.com/anthropics/skills`), NoE custom skills (this repo)

For detailed skills documentation, see [SKILLS.md](../../SKILLS.md).
