# Contributing to Nation of Elites

Thank you for your interest in contributing to the Nation of Elites! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Agent Development Guidelines](#agent-development-guidelines)
- [Testing Your Changes](#testing-your-changes)
- [Submitting Changes](#submitting-changes)
- [Style Guide](#style-guide)

## Code of Conduct

This project follows a simple code of conduct:

- **Be respectful** and constructive in discussions
- **Be patient** with newcomers and those learning
- **Be collaborative** and help others improve
- **Be professional** in all communications

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When you create a bug report, include:

- **Clear title** and description
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Claude Code version** (`claude --version`)
- **Operating system** and version
- **Any error messages** or logs

### Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- **Clear use case** - Why is this enhancement needed?
- **Detailed description** - What should it do?
- **Examples** - How would it work?
- **Agent fit** - Which division/agent would this belong to?

### Contributing Code

Types of code contributions:

1. **New Agents** - Add specialized agents for new domains
2. **Agent Improvements** - Enhance existing agent capabilities
3. **Bug Fixes** - Fix issues in agent logic or documentation
4. **Documentation** - Improve guides, examples, or clarity
5. **Testing** - Add validation scripts or test scenarios

## Getting Started

### Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR-USERNAME/claude-code-agents-team-nation-of-elites.git
cd claude-code-agents-team-nation-of-elites

# Add upstream remote
git remote add upstream https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
```

### Local Development Setup

```bash
# Install locally for testing
bash scripts/deploy_agents.sh

# Or install as plugin (Claude Code v2+)
/plugin install /path/to/your/local/repo
```

### Keep Your Fork Updated

```bash
# Fetch upstream changes
git fetch upstream

# Merge upstream/main into your local main
git checkout main
git merge upstream/main

# Push to your fork
git push origin main
```

## Development Workflow

### Create a Feature Branch

```bash
# Create and switch to a new branch
git checkout -b feature/your-feature-name

# Examples:
# git checkout -b feature/add-rust-expert
# git checkout -b fix/orchestrator-delegation
# git checkout -b docs/update-installation-guide
```

### Make Your Changes

1. Make your code changes
2. Test locally (see Testing section)
3. Update documentation if needed
4. Commit with clear messages

### Commit Messages

Use clear, descriptive commit messages:

```bash
# Good commit messages
git commit -m "feat: add Rust programming language expert agent"
git commit -m "fix: correct delegation pattern in tech-lead-orchestrator"
git commit -m "docs: update installation guide for Windows users"

# Use conventional commits format
# feat: new feature
# fix: bug fix
# docs: documentation changes
# refactor: code refactoring
# test: testing changes
# chore: maintenance tasks
```

## Agent Development Guidelines

### Agent Structure

All agents must follow this structure:

```markdown
---
name: agent-name
description: |
  Clear description of agent's purpose and capabilities
tools: LS, Read, Grep, Glob, Bash, Write, Edit, MultiEdit
---

# Agent Title

## Mission
Clear statement of the agent's core responsibility

## Responsibilities
- Specific responsibility 1
- Specific responsibility 2
- ...

## Workflow
1. Step 1
2. Step 2
3. ...

## Output Format
```
Expected output structure
```

## Heuristics
- When to use this agent
- What triggers its involvement
- Key decision points

## Delegations
| Trigger | Delegate | Goal |
|---------|----------|------|
| ...     | ...      | ...  |

## Thinking Policy (if applicable)
- Trigger conditions
- Budget (token limit)
- Output style
- Guardrails
```

### Choosing the Right Division

Place your agent in the appropriate division:

- **00_Executive_Wing**: Business leadership and strategic oversight
- **01_Strategy_and_Planning_Wing**: Planning, architecture, and strategy
- **02_Project_Management_Office**: Project and process management
- **03_Engineering_Division**: Development and implementation
  - Core_Development_Team: API, backend, frontend
  - Framework_Specialists: Technology-specific experts
  - Code_Excellence_Guild: Code quality and optimization
- **04_Quality_Assurance_Battalion**: Testing and quality validation
- **05_SecOps_and_Infrastructure_Division**: Security, operations, infrastructure
- **06_AI_and_Machine_Learning_Division**: AI, ML, and data engineering
- **07_Orchestrators**: System coordination (rarely modified)

### Naming Conventions

- **Agent name**: `agent-name` (lowercase, hyphenated)
- **File name**: `Agent_Name.md` (PascalCase with underscores)
- **Display name**: Human-readable title in the header

Example:
```yaml
name: react-typescript-expert
File: React_TypeScript_Expert.md
Title: # React TypeScript Expert
```

### Tool Selection

Choose appropriate tools based on agent needs:

- **LS**: Directory listing
- **Read**: File reading
- **Grep**: Code search
- **Glob**: Pattern matching
- **Bash**: Command execution
- **Write**: File creation
- **Edit**: File modification
- **MultiEdit**: Multiple file edits

Most agents use: `LS, Read, Grep, Glob, Bash, Write, Edit, MultiEdit`

Orchestrators typically use: `LS, Read, Grep, Glob, Bash` (no write operations)

### Thinking Budgets

Assign appropriate thinking budgets:

- **High (600-800 tokens)**: Architects (Solution, UX/UI, API, Cloud)
- **Medium (400-600 tokens)**: Analysts, Planners, Strategists
- **Medium-Low (200-300 tokens)**: Framework Specialists, Infrastructure
- **Low (100-200 tokens)**: Developers, Engineers, QA
- **Orchestration (≤300 tokens)**: Orchestrators, Coordinators

### Delegation Patterns

Every agent should clearly define:

1. **When to delegate** - Triggers for involving other agents
2. **Who to delegate to** - Specific agents for specific tasks
3. **What context to pass** - Information needed by the delegated agent

Example:
```markdown
## Delegations
| Trigger | Delegate | Goal |
|---------|----------|------|
| Security concerns | `cyber-sentinel` | Security analysis and remediation |
| Database design needed | `database-expert` | Schema design and optimization |
| TypeScript React project | `react-typescript-expert` | Type-safe implementation |
```

## Testing Your Changes

### Local Testing

```bash
# Deploy your changes locally
bash scripts/deploy_agents.sh

# Or for plugin testing
/plugin install /path/to/your/local/repo
```

### Manual Testing

Test your agent in real scenarios:

```bash
# Test agent invocation
claude "Use the [your-agent-name] to [perform task]"

# Test natural language invocation
claude "[Describe task that should trigger your agent]"

# Test delegation patterns
claude "[Task that should trigger delegation from your agent]"
```

### Validation Checklist

Before submitting:

- [ ] Agent follows the standard structure
- [ ] Agent is in the correct division
- [ ] Tools are appropriate for the agent's tasks
- [ ] Thinking budget is appropriate
- [ ] Delegation patterns are clearly defined
- [ ] Documentation is clear and complete
- [ ] Agent name follows conventions
- [ ] File name follows conventions
- [ ] No typos or grammatical errors
- [ ] Tested locally and works as expected

## Submitting Changes

### Create a Pull Request

1. Push your branch to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. Go to the original repository on GitHub

3. Click "New Pull Request"

4. Select your fork and branch

5. Fill out the PR template with:
   - **Title**: Clear, descriptive summary
   - **Description**: What does this PR do?
   - **Motivation**: Why is this change needed?
   - **Testing**: How did you test it?
   - **Related Issues**: Link any related issues

### PR Review Process

1. **Automated Checks**: Basic validation runs automatically
2. **Code Review**: Maintainer reviews your changes
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, PR will be merged
5. **Release**: Changes included in next release

### After Your PR is Merged

1. Pull the latest changes:
   ```bash
   git checkout main
   git pull upstream main
   ```

2. Delete your feature branch:
   ```bash
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
   ```

3. Update your fork:
   ```bash
   git push origin main
   ```

## Style Guide

### Markdown Formatting

- Use **bold** for emphasis
- Use `code` for agent names, commands, file names
- Use code blocks with language tags:
  ```bash
  # Shell commands
  ```
  ```yaml
  # YAML frontmatter
  ```

### Writing Style

- **Be concise** - Clear and to the point
- **Be specific** - Avoid vague descriptions
- **Be actionable** - Provide concrete steps/examples
- **Be consistent** - Follow existing patterns

### Documentation

When updating documentation:

- Keep language simple and accessible
- Provide examples for complex concepts
- Update all affected files (README, CLAUDE.md, etc.)
- Verify all links work
- Check formatting renders correctly

## Questions?

- **Documentation**: Check [README.md](README.md) and [CLAUDE.md](CLAUDE.md)
- **Migration**: See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
- **Issues**: Browse or create [GitHub Issues](https://github.com/advisely/claude-code-agents-team-nation-of-elites/issues)
- **Discussions**: Join [GitHub Discussions](https://github.com/advisely/claude-code-agents-team-nation-of-elites/discussions)

## Recognition

Contributors are recognized in:

- Git commit history
- Release notes (for significant contributions)
- Special thanks in documentation (for major features)

Thank you for contributing to Nation of Elites! Your contributions help make AI-assisted development more powerful and accessible for everyone.
