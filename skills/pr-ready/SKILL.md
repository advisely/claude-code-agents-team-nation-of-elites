---
name: pr-ready
description: Complete PR workflow - runs tests, linting, security scan, simplification, then commits, pushes, creates PR with comments, and optionally creates a release. Use after completing feature implementation.
---

# PR Ready Workflow

Complete pre-PR checklist with automated git operations.

## Workflow Phases

### Phase 1: Quality Checks

#### Step 1: Run Tests
```bash
# Auto-detect and run test suite
npm test || yarn test || pnpm test || pytest || go test ./... || bundle exec rspec || cargo test
```
- All tests must pass before proceeding
- Report coverage if available

#### Step 2: Run Linter
```bash
# Auto-detect and run linter
npm run lint || yarn lint || ruff check . || golangci-lint run || rubocop || cargo clippy
```
- Auto-fix what's possible
- Report remaining issues

#### Step 3: Type Check (if applicable)
```bash
# TypeScript/Python type checking
npx tsc --noEmit || mypy . || pyright
```

#### Step 4: Security Scan
Check for:
- [ ] Hardcoded secrets (API keys, passwords, tokens)
- [ ] SQL injection vulnerabilities
- [ ] XSS vulnerabilities
- [ ] Insecure dependencies (`npm audit` / `pip-audit`)
- [ ] Sensitive files in .gitignore

#### Step 5: Code Simplification Pass
Review changes for:
- Unnecessary complexity
- Redundant code
- Unclear naming
- Missing error handling
Apply minimal fixes while preserving functionality.

### Phase 2: Documentation

#### Step 6: Documentation Check
- [ ] Code comments for complex logic (only where needed)
- [ ] README updated if API/usage changed
- [ ] CHANGELOG entry added with version
- [ ] API docs updated if endpoints changed

### Phase 3: Git Operations

#### Step 7: Stage Changes
```bash
git status
git diff --stat
git add -p  # Interactive staging (or specific files)
```

#### Step 8: Create Commit
```bash
git commit -m "$(cat <<'EOF'
feat(scope): Brief description of change

- Detail 1
- Detail 2

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Follow conventional commits:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance

#### Step 9: Push to Remote
```bash
git push origin HEAD
# Or create new branch and push
git checkout -b feature/branch-name
git push -u origin feature/branch-name
```

### Phase 4: Create Pull Request

#### Step 10: Create PR with GitHub CLI
```bash
gh pr create \
  --title "feat(scope): Brief description" \
  --body "$(cat <<'EOF'
## Summary
[1-3 bullet points describing the change]

## Changes
- [List of specific changes]

## Test Plan
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if UI changes)
[Add screenshots if applicable]

---
🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

#### Step 11: Add PR Comments (Optional)
```bash
# Add review comments for specific lines
gh pr comment --body "Note: This section handles edge case X"

# Request reviewers
gh pr edit --add-reviewer username1,username2
```

### Phase 5: Release (Optional)

#### Step 12: Create Release Version
Only if user requests release:

```bash
# Bump version (detect package manager)
npm version patch|minor|major || poetry version patch|minor|major

# Create git tag
git tag -a v1.2.3 -m "Release v1.2.3: Brief description"
git push --tags

# Create GitHub release
gh release create v1.2.3 \
  --title "v1.2.3" \
  --notes "$(cat <<'EOF'
## What's Changed
- Feature 1
- Fix 2

## Contributors
- @username

**Full Changelog**: https://github.com/owner/repo/compare/v1.2.2...v1.2.3
EOF
)"
```

## Output Format

```markdown
## PR Ready Report

### Quality Checks
| Check | Status | Details |
|-------|--------|---------|
| Tests | ✅ PASS | 47/47 passed, 92% coverage |
| Lint | ✅ PASS | 0 errors, 2 warnings (ignored) |
| Types | ✅ PASS | No type errors |
| Security | ✅ PASS | No vulnerabilities |
| Simplification | ✅ Done | Removed 12 lines of dead code |

### Documentation
- [x] Comments adequate
- [x] README current
- [x] CHANGELOG updated

### Git Operations
- **Branch**: feature/user-profile-edit
- **Commits**: 3 new commits
- **Files changed**: 8
- **Insertions**: +247
- **Deletions**: -34

### Pull Request
- **PR URL**: https://github.com/owner/repo/pull/123
- **Title**: feat(profile): Add user profile editing with image upload
- **Reviewers**: @reviewer1, @reviewer2
- **Labels**: enhancement, needs-review

### Release (if created)
- **Version**: v1.2.3
- **Tag**: https://github.com/owner/repo/releases/tag/v1.2.3

---
✅ **PR created successfully!**
```

## User Prompts

The skill will ask for confirmation at key points:

1. **After quality checks**: "All checks passed. Proceed to commit?" (yes/no)
2. **After staging**: "These files will be committed. Proceed?" (yes/no)
3. **After PR creation**: "Create a release version?" (yes/no/version)

## Flags/Arguments

```
/pr-ready                    # Full workflow, prompts for release
/pr-ready --no-release       # Skip release step
/pr-ready --release minor    # Auto-create minor release
/pr-ready --draft            # Create draft PR
/pr-ready --reviewer @user   # Add specific reviewer
```
