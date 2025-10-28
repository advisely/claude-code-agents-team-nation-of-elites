# Migration Guide: Nation of Elites

This guide helps you migrate between versions of Nation of Elites:
- **v1.x → v2.0**: Plugin system architecture
- **v2.0 → v3.0**: Agent Skills integration (latest)

## What's New in v3.0 (Latest)

### Agent Skills Integration 🎓

Nation of Elites v3.0 introduces **Agent Skills** - procedural knowledge packages that extend agent capabilities without bloating context:

**Key Features:**
- **Progressive Disclosure**: Skills load in 3 levels (metadata → instructions → resources)
- **Executable Code**: Skills can bundle Python/JavaScript for deterministic operations
- **Modular Expertise**: Framework patterns, security checklists, document processing
- **Zero Breaking Changes**: All v2.0 agents work exactly the same

**What's Added:**
- `~/.claude/skills/` directory with skill library
- Official Anthropic skills (pdf, docx, xlsx, mcp-builder, webapp-testing)
- Custom skills (django-patterns, react-patterns, security-audit, github-actions)
- Enhanced deployment script installs both agents + skills

**Migration Path v2.0 → v3.0:**

```bash
# Upgrade is automatic - just redeploy
git pull origin main
bash scripts/deploy_agents.sh
# Now installs agents + skills
```

**What Changed:**
- ✅ All 45 agents unchanged - fully backward compatible
- ✅ Deployment script now installs skills automatically
- ✅ Agents can invoke skills for enhanced capabilities
- ✅ Documentation updated with skills guidance

**New Capabilities:**
- Documentation Specialist can create/edit PDF, Word, PowerPoint, Excel
- QA Engineer can use Playwright for automated UI testing
- Integration Specialist can scaffold MCP servers
- Django/React experts access framework-specific best practices
- DevOps Engineer uses CI/CD templates

See **[SKILLS.md](SKILLS.md)** for comprehensive skills documentation.

---

## What's New in v2.0

### Plugin System Architecture

Nation of Elites v2.0 is now a **Claude Code plugin**, offering:

- **One-command installation** via `/plugin install`
- **Automatic updates** through the plugin system
- **Easy enable/disable** per project or globally
- **Reduced context overhead** with plugin toggling
- **Better integration** with Claude Code CLI

### Agent Invocation Changes

**v1.x (Old)**: Explicit agent mentions
```bash
claude "Use @agent-project-sponsor to define business objectives"
```

**v2.0 (New)**: Natural language with automatic agent selection
```bash
claude "Define business objectives for this project"
# Claude automatically spawns project-sponsor via Task tool
```

Both patterns still work, but v2.0's natural language approach is recommended.

## Migration Steps

### Step 1: Check Your Claude Code Version

```bash
claude --version
```

- **v2.0+**: Follow the Plugin Installation path
- **v1.x**: Continue with Legacy Installation or upgrade Claude Code

### Step 2: Choose Your Installation Method

You have two options for v2.0:

#### Option A: Standard Installation (Recommended - Works Now)

**Install agents directly** - this is the most reliable method:

```bash
# Clone repository
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites

# Deploy agents
bash scripts/deploy_agents.sh
```

This copies agents to `~/.claude/agents/` and you're done!

#### Option B: Plugin System Installation (Future-Proof)

**For Claude Code v2.0+ with plugin system**:

```bash
# Step 1: Add the GitHub marketplace source
/marketplace add advisely/claude-code-agents-team-nation-of-elites

# Step 2: Install the plugin from marketplace
/plugin install nation-of-elites

# Step 3: Remove old agents directory if migrating from v1.x
rm -rf ~/.claude/agents

# Step 4: Verify plugin is recognized
/plugin list
# Should show: "nation-of-elites v2.0.0"
```

**Alternative Plugin Method** (bypasses marketplace):
```bash
# Clone directly to plugins directory
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git ~/.claude/plugins/nation-of-elites

# Verify
/plugin list
```

**Important**: You **must** add the marketplace source first (`/marketplace add`) before running `/plugin install`, otherwise you'll get "Marketplace not found".

### Step 3: Verify Installation

```bash
# Check that agents are accessible
ls ~/.claude/agents/07_Orchestrators/Tech_Lead_Orchestrator.md
# OR (if using plugin system)
ls ~/.claude/plugins/nation-of-elites/agents/07_Orchestrators/Tech_Lead_Orchestrator.md

# Test agent invocation
claude "I need help with project planning"
# Should trigger appropriate agent response
```

### Step 4: Update Your Workflows

#### Old Pattern (v1.x)

```bash
# Explicit agent mentions
claude "Use @agent-tech-lead-orchestrator to coordinate development"
claude "Use @agent-react-expert for frontend implementation"
```

#### New Pattern (v2.0 - Recommended)

```bash
# Natural language - Claude selects agents automatically
claude "Coordinate development of the user dashboard feature"
claude "Implement the frontend components using React and TypeScript"
```

#### Backward Compatibility

The old `@agent-[name]` pattern still works if you prefer explicit control:

```bash
# This still works in v2.0
claude "Use the tech-lead-orchestrator to coordinate development"
```

## Feature Comparison

| Feature | v1.x | v2.0 |
|---------|------|------|
| **Installation** | Manual copy or script | One-command plugin install |
| **Updates** | Manual git pull + redeploy | Automatic via plugin system |
| **Agent Invocation** | Explicit `@agent-name` | Natural language or explicit |
| **Context Management** | Manual | Automatic compaction at 80% |
| **Plugin Management** | N/A | Enable/disable per project |
| **Subagent Spawning** | Limited | Full Task tool support |
| **MCP Integration** | External setup | Built-in Integration Specialist |
| **Total Agents** | 45 | 45 (same structure) |

## Breaking Changes

### None - Full Backward Compatibility

v2.0 maintains **full backward compatibility** with v1.x:

✅ All 45 agents remain the same
✅ Agent names unchanged
✅ Directory structure unchanged
✅ Explicit `@agent-name` invocation still works
✅ All agent capabilities preserved

### What Changed

Only the **installation method** and **recommended invocation pattern** changed:

- **Installation**: Manual → Plugin system (preferred)
- **Invocation**: Explicit mentions → Natural language (preferred)

## Common Migration Issues

### Issue: Plugin Not Found

**Problem**: `/plugin install` returns "plugin not found"

**Solution**:
1. Ensure you're using Claude Code v2.0+: `claude --version`
2. Check GitHub URL is correct: `advisely/claude-code-agents-team-nation-of-elites`
3. Try alternative: Clone and use legacy installation

### Issue: Agents Not Responding

**Problem**: Claude doesn't spawn the right agent

**Solution**:
1. Verify plugin is active: `/plugin list`
2. Enable plugin: `/plugin enable nation-of-elites`
3. Use explicit agent mention as fallback: "Use the [agent-name] to..."

### Issue: Context Overhead

**Problem**: Too many agents loaded at once

**Solution**:
```bash
# Disable plugin when not needed
/plugin disable nation-of-elites

# Enable only for specific projects
cd my-project
/plugin enable nation-of-elites
```

## Best Practices for v2.0

### 1. Use Natural Language Commands

Let Claude pick the right agent:

```bash
# Good (v2.0)
claude "Design the microservices architecture for this e-commerce platform"

# Works but verbose (v1.x style)
claude "Use @agent-solution-architect to design microservices architecture"
```

### 2. Leverage Plugin Toggling

Enable plugins only when needed:

```bash
# For simple projects - disable to reduce context
/plugin disable nation-of-elites

# For enterprise projects - enable full workforce
/plugin enable nation-of-elites
```

### 3. Trust Automatic Agent Selection

Claude's Task tool is optimized to select the right specialist:

```bash
# Claude will automatically spawn:
# - react-typescript-expert (not react-expert) for TypeScript projects
# - crypto-api-developer for blockchain projects
# - storage-security-specialist for security tasks

claude "Build a type-safe React dashboard with user authentication"
# Spawns: react-typescript-expert, backend-developer, cyber-sentinel
```

### 4. Use Subagent Coordination

Let the Tech Lead Orchestrator spawn parallel subagents:

```bash
claude "Analyze this large codebase for performance bottlenecks and security issues"
# Tech Lead spawns: performance-optimizer + cyber-sentinel + code-archaeologist in parallel
```

## Rollback to v1.x

If you need to rollback:

```bash
# Uninstall v2.0 plugin
/plugin uninstall nation-of-elites

# Restore v1.x backup
cp -r ~/.claude/agents.backup ~/.claude/agents

# Or reinstall v1.x
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites
git checkout v1.x  # If v1.x branch exists
bash scripts/deploy_agents.sh
```

## Getting Help

- **Documentation**: [README.md](README.md)
- **Configuration Guide**: [CLAUDE.md](CLAUDE.md)
- **SDK Compliance**: [docs/SDK_COMPLIANCE_REPORT.md](docs/SDK_COMPLIANCE_REPORT.md)
- **Issues**: [GitHub Issues](https://github.com/advisely/claude-code-agents-team-nation-of-elites/issues)
- **Discussions**: [GitHub Discussions](https://github.com/advisely/claude-code-agents-team-nation-of-elites/discussions)

## Quick Reference

### v1.x → v2.0 Command Translation

| v1.x Command | v2.0 Equivalent |
|--------------|-----------------|
| `claude "Use @agent-project-sponsor to define goals"` | `claude "Define business goals for this project"` |
| `claude "Use @agent-tech-lead-orchestrator to coordinate"` | `claude "Coordinate development of the authentication feature"` |
| `claude "Use @agent-react-expert for frontend"` | `claude "Build the frontend dashboard with React"` |
| `claude "Use @agent-devops-engineer for CI/CD"` | `claude "Setup CI/CD pipeline with automated testing"` |

---

**Ready to migrate?** Follow the steps above and enjoy the streamlined v2.0 experience with plugin-based installation and natural language agent invocation!
