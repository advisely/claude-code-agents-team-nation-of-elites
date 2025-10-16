# Changelog

All notable changes to the Nation of Elites multi-agent system will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- **Subagent Coordination**: Tech Lead Orchestrator can now spawn 3-5 temporary, task-specific subagents for parallel information gathering
  - Isolated context windows for each subagent
  - Descriptive naming convention (e.g., `subagent-search-logs-morning`)
  - Explicit lifecycle documentation (Created → Execute → Report → Terminate)
- **Context Compaction**: Automatic summarization triggers at 80% context usage
  - Program Manager, Product Manager, and Tech Lead Orchestrator equipped with compaction strategies
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
- **Tech Lead Orchestrator**: Enhanced with subagent coordination and context compaction capabilities
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

**Orchestration Completed**: tech-lead-orchestrator successfully delegated agent creation and documentation updates per approved business directive.
