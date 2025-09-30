# Context Engineering Best Practices

## File System as Context Management

The file system structure represents information that could be pulled into the model's context. This document outlines best practices for organizing and accessing project information efficiently.

## Standard Project Structure

```
/project-root
├── /docs                    # Documentation and context
│   ├── /architecture       # System design documents (Solution Architect)
│   ├── /requirements       # Business requirements (Business Analyst)
│   ├── /decisions         # Architecture Decision Records (ADRs)
│   ├── /conversations     # Historical context and discussions
│   ├── /logs             # System logs for debugging
│   └── /research         # Market research and analysis
├── /src                    # Source code
├── /tests                  # Test files
├── /scripts               # Build and deployment scripts
└── /artifacts            # Build outputs and deliverables
```

## Efficient File Access Patterns

### 1. Use Bash Commands for Large Files

Never load entire large files into context. Instead, use targeted bash commands:

#### Searching for Patterns
```bash
# Search with context lines
grep -A 5 -B 5 "pattern" file.log

# Search recursively with line numbers
grep -rn "TODO" ./src

# Search specific file types
find . -name "*.ts" -exec grep -l "Component" {} \;
```

#### Viewing File Portions
```bash
# View first 100 lines
head -n 100 large_file.log

# View last 100 lines
tail -n 100 large_file.log

# View specific line range
sed -n '50,150p' file.txt

# View file with line numbers
nl -ba file.txt | head -50
```

#### Analyzing File Structure
```bash
# Count lines in files
wc -l *.js

# Find large files
find . -type f -size +1M

# Get file statistics
stat file.txt
```

### 2. Subagent Patterns for File Processing

When dealing with multiple files or large datasets, use subagents:

```markdown
## Subagent Pattern: Parallel Log Analysis

1. **Main Agent**: Identifies log files to analyze
2. **Subagent-1**: Analyzes logs from 00:00-08:00
   - Uses: `grep "ERROR" logs/2024-01-*.log | head -100`
   - Returns: Summary of critical errors only
3. **Subagent-2**: Analyzes logs from 08:00-16:00
   - Uses: `grep "ERROR" logs/2024-01-*.log | head -100`
   - Returns: Summary of critical errors only
4. **Subagent-3**: Analyzes logs from 16:00-24:00
   - Uses: `grep "ERROR" logs/2024-01-*.log | head -100`
   - Returns: Summary of critical errors only
5. **Main Agent**: Consolidates findings
```

### 3. Context-Aware File Organization

#### Organize by Access Frequency
- **Hot**: Files accessed frequently → Keep in root or /src
- **Warm**: Files accessed occasionally → Keep in /docs
- **Cold**: Archive files → Keep in /archive or compressed

#### Use Meaningful Naming Conventions
```
/docs/
├── 2024-01-15-architecture-decision-auth.md
├── 2024-01-20-requirements-user-management.md
└── 2024-01-25-meeting-notes-sprint-planning.md
```

## Context Compaction Strategies

### 1. Automatic Summarization Triggers

When context usage exceeds 80%, automatically summarize:

```markdown
## Context Summary at 80% Usage

### Decisions Made
- Chose PostgreSQL for database (scalability)
- Implemented JWT authentication (security)
- Selected React for frontend (team expertise)

### Current Status
- ✅ Database schema complete
- ✅ Authentication implemented
- 🔄 Frontend components in progress
- ⏳ API endpoints pending

### Active Issues
- Performance bottleneck in user search
- CORS configuration for staging environment

### Next Steps
1. Complete remaining API endpoints
2. Implement caching layer
3. Deploy to staging
```

### 1.1. Before/After Compaction Example

#### Before Compaction (Context at 85%, ~170K tokens)
```markdown
## Full Project Context

### Architecture Discussion (5,000 tokens)
[Detailed conversation about microservices vs monolith...]
[Multiple viewpoints and debates...]
[Historical context about why each option was considered...]

### User Story #1 - Login Feature (8,000 tokens)
**Full Requirements:**
As a user, I want to log in so I can access my account...
[Detailed acceptance criteria, edge cases, UI mockups...]

**Implementation Details:**
[Complete code walkthrough of authentication flow...]
[Database schema design process...]
[Security considerations discussed...]

**Testing Discussion:**
[Unit tests, integration tests, e2e tests...]
[Test data setup and teardown...]

**Code Review Comments:**
[15 review comments with full thread discussions...]

**RESOLVED** - Login now works with JWT tokens

### User Story #2 - Dashboard (10,000 tokens)
[Similarly verbose details...]

### Bug #47 - Password Reset Issue (6,000 tokens)
[Full debugging session transcript...]
[Stack traces and error logs...]
**RESOLVED** - Fixed email template configuration

### Performance Analysis (12,000 tokens)
[Complete profiling data...]
[Every metric and graph discussed...]
[COMPLETED] - Optimized queries, 50% faster

[... continues with similar verbose entries ...]
```

#### After Compaction (Context at 45%, ~90K tokens)
```markdown
## Compacted Project Context

### Critical Decisions
- **Architecture**: Monolith with modular design (easier deployment for team size)
- **Database**: PostgreSQL with read replicas (proven scalability)
- **Auth**: JWT with refresh tokens (stateless, mobile-friendly)
- **Frontend**: React + TypeScript (team expertise)

### Active Work (Sprint 3)
- 🔄 Dashboard widgets (Frontend Dev, 60% complete)
- 🔄 Analytics API endpoints (Backend Dev, in progress)
- ⏳ User preferences (Next up)

### Active Blockers
- **CRITICAL**: Performance bottleneck in user search (>5s response)
  - Impact: Affects 2 user stories
  - Owner: Performance Optimizer
  - Due: End of sprint

### API Contracts (Preserve Exactly)
```typescript
// POST /api/v1/login
interface LoginRequest { email: string; password: string }
interface LoginResponse { token: string; refreshToken: string; user: User }

// GET /api/v1/dashboard
interface DashboardResponse { widgets: Widget[]; metrics: Metrics }
```

### Completed & Archived
- ✅ Sprint 1: Authentication system (JWT implemented)
- ✅ Sprint 2: User management CRUD (All tests passing)
- ✅ Bug #47: Password reset email (Fixed template)
- ✅ Performance: Query optimization (50% improvement)

### Key Learnings
- Email templates need test environment validation
- Database indexes critical for search performance
- JWT refresh logic needs clear documentation

### Security Notes
- All passwords hashed with bcrypt (cost factor 12)
- Rate limiting: 5 failed logins = 15min lockout
- CORS configured for app.example.com only

### Next Sprint Planning
1. Complete dashboard features
2. Implement caching layer (Redis)
3. User preferences UI
4. Mobile responsiveness pass
```

**Compaction Results:**
- **Removed**: Verbose discussions (40K tokens), resolved bug details (15K tokens), completed code reviews (10K tokens), old meeting notes (15K tokens)
- **Preserved**: API contracts (exact), active blockers (detailed), security configs (exact), architectural decisions (rationale)
- **Space Saved**: ~80K tokens (47% reduction)
- **Context Quality**: Enhanced - easier to navigate, critical info prominent

### 2. Information Hierarchy

Preserve information based on importance:

```
CRITICAL (Always Keep)
├── Active bugs and blockers
├── Security vulnerabilities
├── API contracts and interfaces
└── Current sprint goals

IMPORTANT (Keep if Space)
├── Architecture decisions
├── Test results
├── Performance metrics
└── User feedback themes

ARCHIVABLE (Summarize/Remove)
├── Completed tasks
├── Resolved issues
├── Old meeting notes
└── Verbose explanations
```

## Grep Patterns for Common Tasks

### Code Analysis
```bash
# Find all TODO comments
grep -rn "TODO\|FIXME\|HACK" --include="*.js" --include="*.ts"

# Find function definitions
grep -rn "function\|const.*=.*=>" --include="*.js"

# Find imports from specific module
grep -rn "from ['\"]\@company" --include="*.ts"
```

### Security Scanning
```bash
# Find potential secrets
grep -rE "(api[_-]?key|secret|password|token)" --exclude-dir=node_modules

# Find hardcoded IPs
grep -rE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" --include="*.config"
```

### Documentation Search
```bash
# Find markdown headers
grep -rn "^#\+" --include="*.md"

# Find broken links
grep -rn "\[.*\]\(.*\)" --include="*.md" | grep -v "http"
```

## Best Practices

### 1. File Access Guidelines
- ✅ Use `grep`, `head`, `tail` for large files
- ✅ Process files in chunks through subagents
- ✅ Search before reading entire files
- ❌ Don't load files > 1000 lines entirely
- ❌ Don't read binary files directly
- ❌ Don't load entire log directories

### 2. Context Preservation
- ✅ Summarize completed work immediately
- ✅ Keep decision rationale concise
- ✅ Archive resolved issues
- ❌ Don't keep verbose discussions
- ❌ Don't duplicate information
- ❌ Don't retain outdated context

### 3. Subagent Coordination
- ✅ Use subagents for parallel searches
- ✅ Isolate context per subagent
- ✅ Return only relevant excerpts
- ❌ Don't share full context between subagents
- ❌ Don't exceed 5 parallel subagents
- ❌ Don't use subagents for simple tasks

## Integration with Agent Workflow

### Tech Lead Orchestrator
- Uses file structure to understand project
- Spawns subagents for parallel analysis
- Manages context through compaction

### Specialized Agents
- Access only relevant directories
- Use grep/tail/head for efficiency
- Report summaries, not full content

### Documentation Agents
- Maintain /docs structure
- Update with summaries only
- Archive completed work

## Examples

### Example 1: Analyzing a Large Codebase
```bash
# Step 1: Get overview
find ./src -name "*.ts" | wc -l  # Count TypeScript files

# Step 2: Find main components
grep -rn "export.*class\|export.*interface" --include="*.ts" | head -20

# Step 3: Identify dependencies
grep -rn "^import" --include="*.ts" | cut -d: -f2 | sort | uniq -c | sort -rn | head -10
```

### Example 2: Debugging Production Issue
```bash
# Step 1: Find recent errors
tail -n 1000 /var/log/app.log | grep ERROR | tail -20

# Step 2: Get context around error
grep -A 10 -B 10 "OutOfMemoryError" /var/log/app.log

# Step 3: Check system resources at time
grep "2024-01-15 14:3" /var/log/system.log | grep -E "memory|cpu"
```

### Example 3: Parallel Documentation Search
```markdown
Main Agent: "Find all references to authentication in docs"
├── Subagent-1: grep -rn "auth" ./docs/architecture
├── Subagent-2: grep -rn "auth" ./docs/requirements  
├── Subagent-3: grep -rn "auth" ./docs/decisions
└── Consolidate: Merge and summarize findings
```

## Monitoring Context Usage

### Context Usage Indicators
```markdown
## Current Context Status
- Usage: 75% (150K/200K tokens)
- Active Topics: 5
- Subagents Running: 2
- Files Loaded: 12
- Action: Prepare for compaction
```

### Compaction Checklist
- [ ] Summarize completed tasks
- [ ] Archive resolved issues
- [ ] Consolidate duplicate information
- [ ] Extract key decisions
- [ ] Update documentation
- [ ] Clear verbose explanations

This approach ensures efficient context management while maintaining access to all necessary project information.
