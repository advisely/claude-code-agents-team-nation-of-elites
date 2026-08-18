---
name: feature-workflow
description: End-to-end feature development workflow with planning, implementation, testing, simplification, review, and documentation phases. Invoke with /feature-workflow [feature-description].
---

# Feature Development Workflow

Execute a complete feature development lifecycle with quality gates at each phase.

## Workflow Phases

Execute these phases **in sequence**, waiting for user confirmation at checkpoints:

### Phase 1: Planning
1. Analyze the feature request: `$ARGUMENTS`
2. Identify affected files and components using Glob and Grep
3. Design the implementation approach
4. List dependencies and potential risks
5. **OUTPUT**: Present plan summary and ask for confirmation

### Phase 2: Implementation
After user confirms the plan:
1. Implement the feature following the approved plan
2. Write clean, well-structured code
3. Add inline comments for complex logic only
4. **OUTPUT**: Summary of changes made

### Phase 3: Testing
1. Write unit tests for new functionality
2. Write integration tests for component interactions
3. Run existing test suite to check for regressions
4. **OUTPUT**: Test results and coverage summary

### Phase 4: Edge Case Validation
1. Identify edge cases and boundary conditions
2. Add tests for edge cases
3. Handle error scenarios gracefully
4. Validate input boundaries
5. **OUTPUT**: Edge cases covered and any issues found

### Phase 5–6: Quality Gate, Simplification + Review

```
/pipeline-quality
```

Steps 10–11 are the reasoning passes: **simplification** (behavior-preserving — reuse, efficiency, altitude, naming; tests must still pass) and a **severity-rated review** delegated to the `code-reviewer` agent. Any 🔴 Critical or 🟠 High finding blocks the phase; the zero-debt gate at step 12 blocks on the rest unless a deferral is recorded in `PLAN.md`.

**OUTPUT**: Simplification changes applied + Quality Gate Report.

### Phase 7: Documentation
1. Update code comments where needed
2. Update README if API changes
3. Add changelog entry
4. Document any configuration changes
5. **OUTPUT**: Documentation updates made

## Checkpoint Protocol

At each phase completion, output:
```
## Phase [N] Complete: [Phase Name]

### Summary
[What was accomplished]

### Artifacts
[Files created/modified]

### Next Phase
[What Phase N+1 will do]

---
**Proceed to Phase [N+1]?** (yes/no/modify)
```

Wait for user confirmation before proceeding.

## Quality Gates

Each phase must pass before proceeding:
- **Planning**: User approval required
- **Implementation**: Code compiles/parses without errors
- **Testing**: All tests pass
- **Edge Cases**: No unhandled scenarios
- **Simplification**: Functionality preserved (tests still pass)
- **Review**: No critical issues
- **Documentation**: All changes documented

## Rollback Protocol

If any phase fails:
1. Report the failure clearly
2. Suggest remediation options
3. Wait for user decision: fix, skip, or abort
