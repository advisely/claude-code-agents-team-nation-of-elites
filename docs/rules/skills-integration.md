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
- `qa-engineer`, `automated-test-scripter` → webapp-testing, silent-failure-audit, semgrep-sast skills
- `visual-regression-specialist` → canvas-design, artifacts-builder skills
- `code-reviewer` → security-audit, silent-failure-audit, semgrep-sast, pipeline-quality skills

**SecOps & Infrastructure:**
- `devops-engineer` → github-actions, kubernetes-deployment, semgrep-sast, pipeline-quality, pipeline-full-build skills
- `cyber-sentinel` → security-audit, owasp-checklist, silent-failure-audit, semgrep-sast skills

**Orchestrators:**
- `integration-specialist` → mcp-builder skill for external integrations
- `chief-operations-orchestrator` → skill-creator for new capability development

## Security Considerations

- **Risk**: Malicious skills could introduce vulnerabilities or exfiltrate data
- **Mitigation**: Only install skills from trusted sources; audit contents before installation
- **Trusted Sources**: Official Anthropic (`github.com/anthropics/skills`), NoE custom skills (this repo)

For detailed skills documentation, see [SKILLS.md](../../SKILLS.md).
