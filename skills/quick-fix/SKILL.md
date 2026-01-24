---
name: quick-fix
description: Rapid bug fix workflow - diagnose, fix, test, and verify in one pass. Use for simple bugs that don't need full feature workflow.
---

# Quick Fix Workflow

Fast-track workflow for simple bug fixes.

## Process

For bug: `$ARGUMENTS`

### 1. Diagnose (30 seconds)
- Locate the bug using Grep/Glob
- Read the relevant code
- Identify root cause

### 2. Fix (implement immediately)
- Apply minimal fix
- Don't refactor unrelated code
- Preserve existing patterns

### 3. Test (verify fix)
- Run relevant tests
- Verify the bug is fixed
- Check for regressions

### 4. Output
```
## Quick Fix Complete

**Bug**: [Description]
**Root Cause**: [What was wrong]
**Fix**: [What was changed]
**File(s)**: [Modified files]
**Tests**: [Pass/Fail status]
```

## When NOT to Use
- Complex bugs requiring architectural changes
- Bugs with unclear root cause
- Changes affecting multiple systems

For complex issues, use `/feature-workflow` instead.
