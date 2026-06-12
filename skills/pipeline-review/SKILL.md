---
name: pipeline-review
description: Universal reasoning-based review pipeline - code simplification pass plus a severity-rated correctness/security/performance review. The judgment counterpart to pipeline-quality (which runs deterministic CI gates). Delegates to the code-reviewer agent.
---

# Pipeline Review

The **judgment-based** counterpart to `/pipeline-quality`. Where `pipeline-quality` runs deterministic shell gates (lint, SAST, tests, audit) with binary pass/fail, `pipeline-review` performs the two **reasoning passes** an agent does over a diff: a **simplification pass** (quality-only, behavior-preserving) followed by a **review pass** (correctness, security, performance, maintainability) with severity-rated findings.

## Division of Labor

| Skill | Nature | Steps |
|-------|--------|-------|
| `pipeline-quality` | Deterministic CI gate | lint, type check, Semgrep SAST, tests, dead code, dep audit |
| **`pipeline-review`** (this) | **Reasoning passes** | **simplify pass, then review pass (severity-rated)** |
| `pipeline-full-build` | Release automation | version bump → quality gate → build → package → release |

Run `pipeline-quality` for the automated gate; run `pipeline-review` for the human-grade judgment. They are complementary — a full pre-merge check runs both.

## When to Use This Skill

- After completing a feature, before opening a PR
- As Phase 5–6 of `/feature-workflow` (simplification + review)
- As the simplification + review step of `/pr-ready`
- Any time you want a behavior-preserving cleanup plus a severity-rated review of a diff

## Target Agents

- `code-reviewer` - Primary operator; owns the review pass and routes specialist issues
- `qa-engineer` - Review pass during validation
- `chief-operations-orchestrator` - Pre-merge quality enforcement

## Scope Detection

Determine what to review. Default to the working-tree/branch diff, not the whole repo:

```bash
# Prefer the branch diff against the default branch
base=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null)
git diff --stat "$base"...HEAD 2>/dev/null || git diff --stat HEAD

# Fall back to unstaged + staged changes if not on a feature branch
git diff --stat && git diff --cached --stat
```

If there is no diff (e.g. reviewing an existing file set), review the explicitly named files only.

## Pass 1: Simplification (behavior-preserving)

Quality-only cleanup. **Does not hunt for bugs** — it makes correct code clearer. Every change must preserve behavior; tests must still pass afterward.

Review the diff for:

1. **Reuse** — Is this reimplementing something the codebase already provides? Replace with the existing helper/util/component.
2. **Simplification** — Unnecessary complexity, nested conditionals that flatten, redundant intermediate variables, dead branches.
3. **Efficiency** — Obvious wasteful work (repeated lookups, needless allocations, O(n²) where O(n) is trivial) — only when the fix is clear and behavior-preserving.
4. **Altitude** — Code sitting at the wrong abstraction level; logic that belongs in an existing layer.
5. **Naming & readability** — Unclear names, comments that restate the code, missing names for magic values.

**Constraint:** apply the *minimal* set of edits. Do not reformat untouched code, do not rename for taste, do not change public APIs. After applying, confirm the test suite still passes (`/pipeline-quality` Step 5, or the project's test command).

**Output:** list of simplifications applied (file:line → what changed → why), or "No simplifications needed."

## Pass 2: Review (severity-rated)

The judgment pass. Delegate to the **`code-reviewer` agent** for a rigorous, security-aware review; it routes deep security/performance/refactor concerns to specialist sub-agents (`cyber-sentinel`, `performance-optimizer`). When running inline, evaluate each dimension below.

### Dimensions

| Dimension | What to check |
|-----------|---------------|
| **Correctness** | Logic errors, off-by-one, wrong conditionals, unhandled return values, race conditions, incorrect assumptions about inputs |
| **Security** | Input validation, injection (SQL/command/XSS), authn/authz gaps, secrets in code, unsafe deserialization, SSRF — prefer secure-by-default libraries over hand-rolled crypto/sanitizers |
| **Error handling** | Swallowed exceptions, silent failures, missing error paths, single-path detection (see `silent-failure-audit`) |
| **Performance** | N+1 queries, unbounded loops/memory, blocking I/O on hot paths, missing pagination/indexes |
| **Maintainability** | SOLID / DRY / KISS violations, leaky abstractions, hidden coupling, untestable seams |
| **Test adequacy** | New logic without tests, missing edge/boundary/error cases, assertions that don't assert |

### Severity Scale

| Severity | Meaning | Gate |
|----------|---------|------|
| 🔴 **Critical** | Security hole, data loss, or guaranteed incorrect behavior | **Blocks merge** |
| 🟠 **High** | Likely bug or real risk under realistic conditions | **Blocks merge** |
| 🟡 **Medium** | Maintainability/perf concern; should fix soon | Non-blocking |
| 🟢 **Low** | Nit, style, optional improvement | Non-blocking |

**Gate rule:** any 🔴 Critical or 🟠 High finding fails the review.

## Output Format

```markdown
## Pipeline Review Report

**Scope:** [N files, +X/-Y lines] — [branch or file set]

### Pass 1: Simplification
| File:Line | Change | Rationale |
|-----------|--------|-----------|
| src/auth.ts:42 | Replaced manual loop with existing `findUser()` | Reuse |
| ... |
Tests after simplification: PASS / FAIL

### Pass 2: Review
| # | Severity | Dimension | File:Line | Finding | Suggested Fix |
|---|----------|-----------|-----------|---------|---------------|
| 1 | 🔴 Critical | Security | api/upload.ts:88 | Unvalidated path → traversal | Resolve + allowlist base dir |
| 2 | 🟡 Medium | Perf | db/users.ts:30 | N+1 on roles | Eager-load with join |

### Review Result: PASS / FAIL
- Blocking (🔴/🟠): [count]
- Non-blocking (🟡/🟢): [count]

### Recommendations
- [Non-blocking suggestions and follow-ups]
```

## Relationship to Other Skills

- Pair with **`/pipeline-quality`** for a complete pre-merge check (deterministic gate + reasoning passes). A common pattern: `pipeline-quality` first (cheap, fails fast), then `pipeline-review`.
- Invoked by **`/feature-workflow`** (Phases 5–6) and **`/pr-ready`** (simplification + review step) — those workflows delegate here instead of inlining checklists, so the review logic lives in one place.
- The review pass loads **`silent-failure-audit`** and **`semgrep-sast`** patterns where relevant; the `code-reviewer` agent preloads these.
