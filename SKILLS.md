# Agent Skills Documentation - Nation of Elites v3.0

## What are Agent Skills?

**Agent Skills** are procedural knowledge packages that extend agent capabilities through progressive disclosure, executable code, and modular expertise. Think of them as training manuals and toolkits that agents can access when needed.

### The Fundamental Distinction

| Aspect | **Agents** | **Skills** |
|--------|------------|------------|
| **Role** | Team members (orchestrators & specialists) | Training manuals & toolkits |
| **Location** | `~/.claude/agents/` | `~/.claude/skills/` |
| **Purpose** | Who performs work | What knowledge they access |
| **Loading** | Task-based spawning | Progressive disclosure (3 levels) |
| **Format** | Markdown with YAML frontmatter | `SKILL.md` with bundled resources |
| **Execution** | Coordinate & delegate | Provide procedures & executable code |

**Key Principle**: Agents USE skills. A Backend Developer (agent) might invoke the `django-patterns` skill (knowledge) or `xlsx` skill (tool) to enhance their work.

---

## Progressive Disclosure Architecture

Skills minimize context usage through three-level loading:

### Level 1: Metadata (Always Loaded)
- Skill name and description loaded into system prompt
- Claude decides relevance without loading full content
- Zero context overhead until skill is needed

```yaml
---
name: django-patterns
description: Django best practices, ORM optimization, and REST API patterns
---
```

### Level 2: Core Instructions (Loaded When Relevant)
- Full `SKILL.md` with procedures and guidance
- Loaded only when Claude identifies task match
- Contains primary procedural knowledge

```markdown
# Django Development Patterns

## When to Use This Skill
- Building Django REST API backends
- Implementing authentication

## Core Patterns
### API View Architecture
...
```

### Level 3: Additional Resources (On-Demand)
- Referenced files, scripts, templates
- Loaded only when specific sub-context needed
- Can include executable code

```markdown
## Additional Resources
See [security.md](security.md) for Django security hardening.
See [templates/](templates/) for project scaffolding.
```

**Example**: PDF skill loads metadata always, full instructions when user mentions PDFs, form-filling procedures only when filling forms.

---

## Available Skills

### Official Anthropic Skills (Automatically Installed)

#### Document Processing
- **pdf** - PDF manipulation, form filling, extraction, merging
  - Creating professional technical specifications
  - Filling out forms programmatically
  - Extracting data from existing PDFs
  - Merging multiple PDFs into one

- **docx** - Word document creation, editing, formatting
  - Creating formatted documentation
  - Generating reports with styling
  - Building document templates
  - Adding headers, footers, tables

- **pptx** - PowerPoint presentation generation and styling
  - Architecture overview presentations
  - Onboarding slide decks
  - Training materials
  - Chart and diagram generation

- **xlsx** - Excel operations with formulas, charts, data validation
  - API endpoint catalogs
  - Configuration matrices
  - Data dictionaries
  - Complex formulas and pivot tables

#### Development Tools
- **mcp-builder** - MCP server development guidance and templates
  - Creating custom MCP servers
  - OAuth flow implementation
  - API integration patterns
  - Security best practices

- **webapp-testing** - Playwright-based UI testing automation
  - Automated browser testing
  - Visual regression testing
  - End-to-end test scenarios
  - Multi-browser compatibility

- **skill-creator** - Interactive skill development assistant
  - Creating new custom skills
  - Following skill structure guidelines
  - Progressive disclosure patterns
  - Skill validation

#### Design Tools
- **artifacts-builder** - Complex HTML artifacts with React/Tailwind
  - Building interactive React components
  - Tailwind CSS styling
  - shadcn/ui integration
  - Responsive design patterns

- **canvas-design** - Visual art creation in PNG/PDF formats
  - Graphic design principles
  - Color theory and composition
  - Logo and icon design
  - Visual asset creation

### Custom Nation of Elites Skills (Included in Repository)

#### Framework Patterns (8 skills)
- **django-patterns** - Django ORM, DRF, authentication, testing
  - Authentication and authorization patterns
  - Database optimization with select_related/prefetch_related
  - Django REST Framework serializers
  - Service layer pattern
  - Background jobs with Celery

- **react-patterns** - React Composition API, hooks, performance optimization
  - Component architecture patterns
  - Custom hooks (useFetch, useForm)
  - State management (Context + useReducer)
  - Performance optimization (useMemo, useCallback, React.memo)
  - Error boundaries and testing

- **vue-patterns** - Vue 3 Composition API, Pinia state management
  - Composition API with `<script setup>`
  - Composables for reusable logic
  - Pinia for state management
  - Vue Router patterns
  - Async components & Suspense

- **nextjs-patterns** - Next.js 14 App Router, Server Components, Server Actions
  - App Router structure
  - Server Components (default) vs Client Components
  - Server Actions for mutations
  - Dynamic routes & metadata
  - Streaming & Suspense

- **rails-patterns** - Ruby on Rails, ActiveRecord, RESTful APIs
  - ActiveRecord associations and scopes
  - Controller patterns and service objects
  - Background jobs with Sidekiq
  - Concerns for shared behavior
  - RSpec testing patterns

- **java-patterns** - Java Spring Boot, JPA/Hibernate, microservices
  - Layered architecture (Controller, Service, Repository)
  - Entity mapping with JPA
  - DTO pattern with MapStruct
  - Global exception handling
  - Spring Security configuration

- **go-patterns** - Go concurrency, interfaces, idiomatic patterns
  - Interface design patterns
  - Error handling and wrapping
  - Concurrency patterns (worker pools, context cancellation)
  - HTTP server patterns
  - Middleware pattern

- **laravel-patterns** - Laravel Eloquent, API resources, authentication
  - MVC architecture patterns
  - Eloquent ORM best practices
  - API resources and collections
  - Laravel Sanctum authentication
  - Form request validation

#### UI/Styling Patterns (2 skills)
- **tailwind-patterns** - Tailwind utility-first CSS, responsive design
  - Component patterns with utility classes
  - Responsive design (mobile-first)
  - Custom Tailwind configuration
  - Dark mode implementation
  - Optimization with PurgeCSS

- **antd-patterns** - Ant Design React components, enterprise UI
  - Form patterns with Form.useForm()
  - Table with actions and sorting
  - Custom theming with ConfigProvider
  - TypeScript integration
  - Professional dashboard components

#### Security & DevOps (4 skills)
- **security-audit** - OWASP Top 10 security checklist
  - OWASP Top 10 (2021) comprehensive checklist
  - Authentication and authorization patterns
  - Input validation and sanitization
  - Cryptographic best practices
  - Security logging and monitoring

- **github-actions** - CI/CD pipeline templates
  - Node.js CI/CD pipelines
  - Python Django workflows
  - Docker build and push
  - Kubernetes deployment
  - Security scanning (Snyk, CodeQL, TruffleHog)

- **kubernetes-deployment** - K8s deployments, autoscaling, services
  - Deployment and Service configurations
  - Horizontal Pod Autoscaler
  - ConfigMaps and Secrets
  - Ingress configuration
  - Production best practices

- **terraform-patterns** - Infrastructure as Code, modules
  - Reusable module structure
  - Remote state management
  - Multi-environment setup
  - Provider versioning
  - State locking with DynamoDB

#### Specialized Domains (2 skills)
- **financial-trading-patterns** - Algorithmic trading, risk management
  - Order Management System
  - Risk management patterns
  - Strategy backtesting
  - Market data handling
  - Position sizing algorithms

- **crypto-defi-patterns** - Cryptocurrency, DeFi, blockchain integration
  - Web3 integration with ethers.js
  - Smart contract interaction
  - Wallet management (HD wallets)
  - Exchange API integration (CCXT)
  - DeFi protocol patterns

#### Testing (1 skill)
- **pytest-patterns** - Python testing with pytest
  - Fixture patterns
  - Parametrized testing
  - Mocking with unittest.mock
  - Django testing with pytest-django
  - Coverage reporting

---

## How Skills Work

### Automatic Skill Discovery

Claude automatically discovers and loads skills based on task context:

```
User Request → Claude analyzes task → Identifies relevant skills → Loads progressively
```

**Example Flow:**
1. User: "Create a Django REST API with authentication"
2. Claude identifies: Django + API + Authentication
3. Skills loaded: `django-patterns` (Level 1 metadata)
4. When writing auth code: `django-patterns` (Level 2 core patterns)
5. When implementing security: `security-audit` (on-demand)

### Skills and Code Execution

Skills can include executable Python/JavaScript code for deterministic operations:

**Why Use Executable Code:**
- More efficient than token generation for sorting, calculations, parsing
- Deterministic and repeatable
- Can leverage standard libraries
- Doesn't load into context until executed

**Example Structure:**
```
skills/pdf-processor/
├── SKILL.md              # Instructions
├── scripts/
│   ├── extract_forms.py  # Extract PDF form fields
│   ├── merge_pdfs.py     # Merge multiple PDFs
│   └── requirements.txt  # Python dependencies
```

**In SKILL.md:**
```markdown
## Extracting Form Fields

To extract form fields from a PDF:

```bash
python scripts/extract_forms.py input.pdf
```

This script uses PyPDF2 to extract all form fields without loading
the PDF content into context.
```

---

## Which Agents Use Which Skills?

### Engineering Division

**Backend Development:**
- `backend-developer` → django-patterns, security-audit
- `django-expert` → django-patterns (primary user)
- `laravel-expert` → laravel-patterns (when available)
- `api-architect` → RESTful API patterns from framework skills

**Frontend Development:**
- `frontend-developer` → react-patterns, artifacts-builder
- `react-expert` → react-patterns (primary user)
- `react-typescript-expert` → react-patterns + TypeScript patterns
- `vue-expert` → vue-patterns (when available)
- `nextjs-expert` → react-patterns + Next.js patterns

**Code Excellence Guild:**
- `documentation-specialist` → pdf, docx, pptx, xlsx
- `code-reviewer` → security-audit, framework best practices
- `performance-optimizer` → react-patterns (performance section)

### Quality Assurance Battalion
- `qa-engineer` → webapp-testing
- `automated-test-scripter` → webapp-testing, test patterns
- `visual-regression-specialist` → canvas-design, artifacts-builder

### SecOps & Infrastructure Division
- `devops-engineer` → github-actions, kubernetes patterns
- `cyber-sentinel` → security-audit (primary user)
- `cloud-architect` → cloud deployment patterns

### Orchestrators
- `integration-specialist` → mcp-builder (primary user)
- `tech-lead-orchestrator` → skill-creator (for new capabilities)

---

## Installation

### Automatic Installation (Recommended)

Skills are automatically installed by the deployment script:

```bash
cd claude-code-agents-team-nation-of-elites
bash scripts/deploy_agents.sh
# Installs agents + official Anthropic skills + custom skills
```

**What Gets Installed:**
- `~/.claude/agents/` - All 45 agents
- `~/.claude/skills/` - Official + custom skills

### Manual Installation

#### Install Anthropic's Official Skills:
```bash
# Clone Anthropic's skills repository
git clone https://github.com/anthropics/skills.git /tmp/skills

# Install document skills
mkdir -p ~/.claude/skills
cp -r /tmp/skills/document-skills/* ~/.claude/skills/

# Install other useful skills
cp -r /tmp/skills/mcp-builder ~/.claude/skills/
cp -r /tmp/skills/webapp-testing ~/.claude/skills/
cp -r /tmp/skills/skill-creator ~/.claude/skills/
cp -r /tmp/skills/artifacts-builder ~/.claude/skills/
cp -r /tmp/skills/canvas-design ~/.claude/skills/

# Cleanup
rm -rf /tmp/skills
```

#### Install Nation of Elites Custom Skills:
```bash
# From the repository root
cp -r skills/* ~/.claude/skills/
```

### Verification

Check installed skills:
```bash
# List all installed skills
find ~/.claude/skills -name "SKILL.md"

# Should show multiple SKILL.md files including:
# - ~/.claude/skills/pdf/SKILL.md
# - ~/.claude/skills/docx/SKILL.md
# - ~/.claude/skills/django-patterns/SKILL.md
# - ~/.claude/skills/react-patterns/SKILL.md
# - etc.
```

---

## Creating Custom Skills

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed skill development guidelines.

### Quick Start

1. **Create skill directory:**
```bash
mkdir -p skills/my-skill
```

2. **Create SKILL.md:**
```markdown
---
name: my-skill
description: Brief description of what this skill provides
---

# My Skill Title

## When to Use This Skill
- Scenario 1
- Scenario 2

## Core Instructions
Main procedural knowledge here...

## Additional Resources (Optional)
See [advanced.md](advanced.md) for advanced patterns.
```

3. **Test locally:**
```bash
cp -r skills/my-skill ~/.claude/skills/
# Test with relevant agent tasks
```

4. **Submit via Pull Request**

### Skill Structure Guidelines

```
skills/
└── skill-name/
    ├── SKILL.md              # Main skill file (required)
    ├── additional-docs.md    # Extra documentation (optional)
    ├── templates/            # Code templates (optional)
    │   ├── template1.py
    │   └── template2.js
    └── scripts/              # Executable scripts (optional)
        ├── process.py
        └── requirements.txt
```

---

## Best Practices

### For Users

1. **Trust Automatic Loading** - Don't explicitly mention skills; Claude loads them automatically
2. **Describe Tasks Clearly** - Clear task descriptions help Claude identify relevant skills
3. **Leverage Agents** - Delegate to agents; they'll use appropriate skills
4. **Audit Third-Party Skills** - Only install skills from trusted sources

### For Developers

1. **Progressive Disclosure** - Structure skills for 3-level loading
2. **Keep Core Lean** - Main SKILL.md should be concise
3. **Bundle Executable Code** - Use scripts for deterministic operations
4. **Document Target Agents** - Specify which agents benefit from the skill
5. **Test Thoroughly** - Verify skills work with intended agents

### For Orchestrators (Tech Lead)

1. **Agents Own Skills** - Delegate to the agent who uses the skill
2. **Don't Mention Explicitly** - Skills load automatically based on context
3. **Use for Procedural Knowledge** - Skills for how-to, not who-does
4. **Create New Skills** - Use `skill-creator` when identifying reusable patterns

---

## Security Considerations

### Skills Security Model

Skills can execute code and provide procedural guidance:

**Risks:**
- Malicious skills could introduce vulnerabilities
- Skills might exfiltrate data
- Bundled scripts could have security issues

**Mitigation:**
- Only install from trusted sources
- Audit skill contents before use
- Review bundled scripts and dependencies
- Check for external network calls

### Trusted Sources

**✅ Trusted:**
- Official Anthropic skills: `github.com/anthropics/skills`
- Nation of Elites custom skills: Included in this repository
- Verified community contributors

**⚠️ Audit Required:**
- Third-party community skills
- Forked or modified skills
- Skills with external dependencies

### Auditing Checklist

Before installing a skill:
- [ ] Read `SKILL.md` completely
- [ ] Review all bundled scripts
- [ ] Check dependencies in `requirements.txt` or `package.json`
- [ ] Verify no suspicious external connections
- [ ] Test in isolated environment first

---

## Troubleshooting

### Skill Not Loading

**Problem**: Skill doesn't seem to be used

**Solutions**:
1. Verify skill is installed: `ls ~/.claude/skills/skill-name`
2. Check SKILL.md has valid YAML frontmatter
3. Ensure task context matches skill description
4. Try more explicit task description

### Skill Conflicts

**Problem**: Multiple skills for similar tasks

**Solution**:
- Skills are designed to be composable
- Claude will load the most relevant skill(s)
- More specific skills take precedence

### Performance Issues

**Problem**: Skills cause slowdown

**Check**:
- Skills should NOT cause slowdown (progressive loading)
- If experiencing issues, check for:
  - Malformed SKILL.md
  - Circular references in resources
  - Very large bundled files

---

## Roadmap

### v3.1 (Next Release)
- Laravel patterns skill
- Vue.js patterns skill
- Next.js patterns skill
- Kubernetes deployment skill

### v3.2 (Future)
- Skills marketplace
- Community skill submissions
- Skill ratings and reviews
- Skill dependency management

### v3.3 (Future)
- Agent self-modification (agents create their own skills)
- Skill composition (skills that use other skills)
- Skill versioning and updates

---

## Resources

- **Agent Skills Engineering Blog**: [Building Effective Agents](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- **Anthropic Skills Repository**: [github.com/anthropics/skills](https://github.com/anthropics/skills)
- **Nation of Elites Repository**: [github.com/advisely/claude-code-agents-team-nation-of-elites](https://github.com/advisely/claude-code-agents-team-nation-of-elites)
- **Contributing Guide**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Migration Guide**: [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)

---

**Agent Skills v3.0** - Progressive Disclosure | Executable Code | Modular Expertise | Zero Context Overhead
