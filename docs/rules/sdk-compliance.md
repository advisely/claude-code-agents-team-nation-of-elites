# Claude Agent SDK Alignment (v2.0.0+)

The Nation of Elites achieves **complete alignment** with Anthropic's Claude Agent SDK best practices.

## ✅ Subagent Coordination
- Chief Operations Orchestrator spawns 3-5 temporary, task-specific subagents for parallel information gathering
- Isolated context windows for efficient parallel processing
- Clear lifecycle: Created → Execute → Report → Terminate
- Descriptive naming convention for clarity (e.g., `subagent-search-logs-morning`)

## ✅ Context Compaction
- Automatic summarization triggers at 80% context usage
- Information hierarchy: Critical → Important → Archivable
- Preserves API contracts, security findings, and active blockers
- Example: 170K tokens → 90K tokens (47% reduction) while maintaining quality
- **New**: Server-side context compaction API (beta) available to supplement manual compaction

## ✅ File System Context Engineering
- Comprehensive guide: `CONTEXT_ENGINEERING.md`
- Efficient large file handling with bash commands (grep, head, tail)
- Hot/warm/cold file organization strategies
- Subagent patterns for parallel file processing

## ✅ MCP Integration
- Integration Specialist (07_Orchestrators) manages Model Context Protocol servers
- Supports 15+ external services: Slack, GitHub, Google Drive, Jira, databases, cloud platforms
- OAuth flow handling and secure authentication management
- Standardized tool/resource access through MCP protocol
- **New**: MCP Connector available for direct remote MCP server connections without client implementation

## ✅ Visual Feedback Loops
- Visual Regression Specialist provides development-time feedback
- Screenshot-based validation at key development checkpoints
- Multi-viewport testing with parallel subagents
- Real-time UI validation during component creation and style changes

## ✅ Code Generation Priority
- Backend Developer emphasizes code over configuration
- Generate vs Configure philosophy for precision and reusability
- Automation as code, rules as code, infrastructure as code
- Testable, composable, infinitely reusable outputs

## ✅ Agent Teams (Opus 4.6)
- Orchestrator can assemble agent teams that work in parallel and coordinate autonomously
- Flexible WIP limits for team scenarios (beyond the default 2-agent limit)
- Isolated context windows per team member with synthesized output

## ✅ Strict Tool Use
- Tool definitions support `strict: true` for guaranteed schema conformance
- Ensures no type mismatches or missing fields in tool inputs
- Recommended for production agents where invalid tool parameters would cause failures

## ✅ Server-Side Tools
- `web_search_20250305` - Web search executed on Anthropic's servers
- `web_fetch_20250305` - URL content fetching on Anthropic's servers
- Handle `pause_turn` for long-running server tool operations

## Quality Metrics

- **64 Total Agents** - Complete coverage across all organizational functions
- **10 Strategic Divisions** - Logical grouping of related capabilities
- **Hierarchical Structure** - Clear command and coordination patterns
- **Comprehensive Coverage** - From strategy to implementation to operations
- **Automatic Documentation** - Self-maintaining project documentation and change tracking
- **Complexity-Based Reasoning** - Tailored thinking budgets based on task complexity
- **SDK Compliance Score** - 10/10 full alignment with Anthropic Claude Agent SDK best practices
