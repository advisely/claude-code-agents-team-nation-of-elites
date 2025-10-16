# Migration Guide: v1.x to v2.0

This guide helps you migrate from Nation of Elites v1.x (Claude Code v1) to v2.0 (Claude Code v2 plugin system).

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

### Step 2: Uninstall v1.x (if applicable)

If you manually installed v1.x agents:

```bash
# Backup your existing configuration (optional)
cp -r ~/.claude/agents ~/.claude/agents.backup

# Remove old installation
rm -rf ~/.claude/agents/00_Executive_Wing
rm -rf ~/.claude/agents/01_Strategy_and_Planning_Wing
rm -rf ~/.claude/agents/02_Project_Management_Office
rm -rf ~/.claude/agents/03_Engineering_Division
rm -rf ~/.claude/agents/04_Quality_Assurance_Battalion
rm -rf ~/.claude/agents/05_SecOps_and_Infrastructure_Division
rm -rf ~/.claude/agents/06_AI_and_Machine_Learning_Division
rm -rf ~/.claude/agents/07_Orchestrators
```

### Step 3: Install v2.0

#### For Claude Code v2.0+

```bash
# Install as plugin
/plugin install advisely/claude-code-agents-team-nation-of-elites

# Verify installation
/plugin list
# Should show: "nation-of-elites v2.0.0"
```

#### For Claude Code v1.x (Legacy)

```bash
# Clone repository
git clone https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites

# Run deployment script
bash scripts/deploy_agents.sh
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
