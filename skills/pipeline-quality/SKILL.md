---
name: pipeline-quality
description: Universal pre-merge pipeline - lint, type check, build, a three-part security gate, tests, a happy/non-happy/edge case matrix, local Playwright E2E, conditional knip/dead-code analysis, dependency audit, then a parallel simplification and severity-rated code review, a zero-technical-debt gate and a no-regression gate. Use to review a diff, simplify code, or run the full quality gate. Stops before git - no commit, no release, no deploy. Records NOT RUN rather than passing a check that never executed. Stack-adaptive for desktop (Electron+Python) and cloud (web/API) projects.
---

# Pipeline Quality Gate

Universal pre-merge pipeline that auto-detects your stack, runs the deterministic checks fast, then closes with the reasoning passes an agent performs over a diff. Use as a pre-merge gate, a standalone quality check, or when asked to review a diff or simplify code.

**This skill never runs git, never tags, never deploys.** It stops before all of that — that boundary is the entire point of the v4.0.0 consolidation. Committing, merging, releasing, and deploying live in the release-automation variant skills (cloud and desktop), not here.

## When to Use This Skill

- Before merging any PR (quality gate)
- After completing a feature implementation
- As a periodic codebase health check
- When onboarding to a new project (baseline scan)
- When asked to review a diff or simplify code — the reasoning passes (Steps 10–11) cover both

## Target Agents

- `code-reviewer` - Primary operator for Steps 10–11 (simplification + review); quality gate during reviews
- `cyber-sentinel` - Security scanning pass
- `qa-engineer` - Automated validation
- `devops-engineer` - CI/CD pipeline integration
- `chief-operations-orchestrator` - Quality enforcement

## Pipeline Steps

| # | Step | Phase |
|---|------|-------|
| 0 | Stack detection, version consistency, knip decision | Setup |
| 1 | Lint + auto-fix | Deterministic |
| 2 | Type check | Deterministic |
| 3 | Build | Deterministic |
| 4 | Security gate (3-part) | Deterministic |
| 5 | Tests | Deterministic |
| 6 | Test case matrix (happy / non-happy / edge) | Deterministic |
| 7 | Local E2E (Playwright) | Deterministic |
| 8 | Dead code + knip | Deterministic |
| 9 | Dependency audit | Deterministic |
| 10 | Parallel analysis — one message | Reasoning |
| 11 | Remediation including pre-existing | Reasoning |
| 12 | Zero-debt gate | Consuming |
| 13 | No-regression gate | Consuming |
| 14 | Local worker purge | Cleanup |

Steps 1–9 are cheap and fail fast, so they run before the reasoning passes. Steps 12–13 consume the output of both phases. **This skill never runs git, never tags, never deploys.**

### Step 0a: Stack Detection

Auto-detect the project stack to select appropriate tools:

```bash
# Detect stack indicators
[ -f "package.json" ] && echo "NODE"
[ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ] && echo "PYTHON"
[ -f "Cargo.toml" ] && echo "RUST"
[ -f "go.mod" ] && echo "GO"
[ -f "Gemfile" ] && echo "RUBY"
[ -f "composer.json" ] && echo "PHP"
[ -f "pom.xml" ] || [ -f "build.gradle" ] && echo "JAVA"
[ -f "electron-builder.yml" ] || [ -f "electron.vite.config.*" ] && echo "ELECTRON"
[ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] && echo "DOCKER"
[ -f "tsconfig.json" ] && echo "TYPESCRIPT"
```

Stack detection above doubles as the desktop/cloud signal consumed by the variant skills; no separate sub-step is needed here.

### Step 0c: Version Consistency

`plugin.json` (or `package.json` for non-plugin projects) is the single source of truth. Every declared version and count elsewhere must agree with it.

```bash
./scripts/check-version-consistency.sh
```

**Gate rule:** any disagreement blocks. This is the check that prevents three versions and three skill counts coexisting in one repository — a drift that is invisible in review because each individual file reads as internally correct.

### Step 0d: knip Decision Rule

```bash
if [ -f knip.json ] || [ -f knip.jsonc ] || [ -f pnpm-workspace.yaml ] || [ -f turbo.json ] \
   || grep -q '"workspaces"' package.json 2>/dev/null; then
  echo "DEAD-CODE TOOL: knip"        # monorepo-aware: unused files, exports, deps
elif [ -f tsconfig.json ]; then
  echo "DEAD-CODE TOOL: ts-prune"    # single-package TS
elif [ -f pyproject.toml ] || [ -f setup.py ]; then
  echo "DEAD-CODE TOOL: vulture"
else
  echo "DEAD-CODE TOOL: NOT RUN — no applicable tool for this stack"
fi
```

**Gate rule:** never skip silently. A stack with no applicable tool records `NOT RUN`, consistent with the security gate's semantics.

### Step 1: Lint

Run language-appropriate linters:

| Stack | Linter Command |
|-------|---------------|
| Python | `ruff check . --fix` or `flake8 .` |
| Node/TS | `npm run lint` or `eslint .` |
| Rust | `cargo clippy -- -D warnings` |
| Go | `golangci-lint run` |
| Ruby | `rubocop` |
| PHP | `./vendor/bin/phpstan analyse` |
| Java | `./mvnw checkstyle:check` |

### Step 2: Type Check (if applicable)

| Stack | Type Check Command |
|-------|-------------------|
| TypeScript | `npx tsc --noEmit` |
| Python | `mypy .` or `pyright` |

### Step 3: Build

The build a check-only gate needs is proof the project compiles/bundles cleanly — not the signed, packaged, or containerized artifact the variant skills produce for shipping. Run the stack-appropriate compile step:

```bash
set -euo pipefail

# Cloud / web (see pipeline-full-build-cloud Step 8 for the full release build)
npm run build || npx vite build
[ -f "pyproject.toml" ] && python -m build
[ -f "go.mod" ]        && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" ./...
[ -f "Cargo.toml" ]    && cargo build --release

# Desktop / Electron (see pipeline-full-build-desktop Step 8 for native rebuilds, signing)
npx tsc -p tsconfig.node.json --noEmit 2>/dev/null || true   # main process, if split config exists
npx tsc -p tsconfig.web.json  --noEmit 2>/dev/null || true   # renderer, if split config exists
npm run build || npx electron-vite build
```

**Gate rule:** a build failure here blocks before any reasoning pass runs — it is cheap and fails fast. This step proves the code compiles; native module ABI rebuilds, code signing, notarization, and container/SBOM work belong to `pipeline-full-build-desktop` and `pipeline-full-build-cloud` respectively, not here.

### Step 4: Security Gate

Three checks, deliberately independent: a pattern scanner, a hook-driven reviewer, and a reasoning pass. Each catches what the others structurally cannot.

**The rule that governs all three: NOT RUN is not PASS.** A security check that did not execute must be recorded as `NOT RUN` and must never be reported as a pass. Silence is the failure mode these steps exist to prevent — a scanner with no server, a hook that never fired, and a clean scan are three different outcomes that look identical in a log which only records findings.

#### Step 4a: `security-guidance` readiness

The `security-guidance` plugin has **no invocable command** — it is hooks-only (`SessionStart`, `UserPromptSubmit`, `PostToolUse`, `Stop`, and an agentic reviewer on `git commit`). You therefore cannot "run" it; you can only confirm it is armed, and treat an unarmed plugin as a check that did not happen.

```bash
sg_root=$(ls -d "$HOME/.claude/plugins/cache/claude-plugins-official/security-guidance"/*/ 2>/dev/null | sort -V | tail -1)
enabled=$(grep -c '"security-guidance@claude-plugins-official"[[:space:]]*:[[:space:]]*true' "$HOME/.claude/settings.json" 2>/dev/null)
venv_py="$HOME/.claude/security/agent-sdk-venv/bin/python"
[ -x "$venv_py" ] || venv_py="$HOME/.claude/security/agent-sdk-venv/Scripts/python.exe"   # Windows

if [ -n "$sg_root" ] && [ "${enabled:-0}" -ge 1 ] && [ -f "${sg_root}hooks/hooks.json" ] \
   && { "$venv_py" -c "import claude_agent_sdk" 2>/dev/null || python3 -c "import claude_agent_sdk" 2>/dev/null; }; then
  echo "security-guidance: ARMED (${sg_root})"
else
  echo "security-guidance: NOT ARMED — record as NOT RUN, do not report a pass"
fi
```

Each condition maps to a real way the plugin goes quiet: not installed, disabled in settings, hooks missing, or the agent SDK absent. That last one matters most — the commit reviewer needs it, the `SessionStart` installer builds a venv at `~/.claude/security/agent-sdk-venv`, and when that build fails the deepest layer stops running while the plugin still reports as enabled.

**Gate rule:** `NOT ARMED` does not fail the build — it is a local tooling state, not a defect in the code. It **does** forbid recording Step 4a as a pass, and it must appear in the report so the reviewer knows this layer was absent.

#### Step 4b: Semgrep SAST

```bash
# Default security scan
semgrep scan --config auto --error .

# Or via MCP plugin: use semgrep_scan tool

# For supply chain vulnerabilities
semgrep ci --supply-chain
```

**Gate rule:** Any ERROR-severity finding blocks the pipeline. If neither the CLI nor the MCP server is available, record `NOT RUN` — never let lint and type-check stand in for a SAST pass.

#### Step 4c: Agentic security review

```
/security-review
```

Reads the branch diff and traces data flow across files, so it reaches what pattern matching cannot: IDOR, authorization bypass, tenant-scope confusion, cross-file SSRF. Point it at an explicit range when the branch is already merged and a bare `git diff` would be empty:

```bash
git log --oneline "$(git merge-base HEAD origin/main)..HEAD"   # confirm the range first
```

**Gate rule:** any HIGH finding blocks. MEDIUM findings block unless explicitly accepted and recorded.

**Multi-tenant systems — check this explicitly.** Where a request is authorized against one tenant identifier and queried with another, every deterministic check above passes: it type-checks, it lints, and the tests exercise the honest path. Confirm the value that proved authorization is the same value reaching the `WHERE` clause. A route that authorizes on a header and selects on a path parameter is the canonical form of this bug.

### Step 5: Tests

| Stack | Test Command |
|-------|-------------|
| Python | `pytest -x --tb=short` |
| Node/TS | `npm test` or `vitest run` |
| Rust | `cargo test` |
| Go | `go test ./...` |
| Ruby | `bundle exec rspec` |
| PHP | `./vendor/bin/phpunit` |
| Java | `./mvnw test` |

### Step 6: Test Case Coverage Matrix (happy / non-happy / edge)

Step 5 proves the tests that exist **pass**. This step proves the tests that *should* exist **are there**. A green suite that only covers the happy path is the single most common blind spot this gate is designed to catch.

For every behavior changed in the diff, require all three classes:

| Class | What must be covered | Typical blind spot |
|-------|---------------------|-------------------|
| **Happy path** | The intended flow with valid, in-range input; the documented success contract | Asserted loosely — status checked, payload never inspected |
| **Non-happy path** | Invalid input, auth failure, missing/malformed data, dependency down, timeout, permission denied, conflicting state | Error *raised* but not asserted on type/message/code; retries untested |
| **Edge cases** | Empty, single-element, and maximum-size inputs; 0 / -1 / off-by-one bounds; null vs. undefined vs. absent; unicode & very long strings; duplicate keys; concurrent/repeat invocation (idempotency); timezone & DST boundaries; float precision; pagination first/last page | Boundaries tested at "typical" values only; concurrency never exercised |

```bash
# Enumerate changed behaviors from the diff, then confirm each has all three classes
base=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null)
git diff --name-only "$base"...HEAD | grep -Ev '(test|spec)' 

# Coverage signal per stack (a floor, not proof of adequacy)
pytest --cov --cov-report=term-missing --cov-branch   # Python: branch coverage exposes untaken paths
npx vitest run --coverage                              # Node/TS
go test ./... -cover                                   # Go
cargo tarpaulin --out Stdout                            # Rust
```

**Assertion quality check** — a test that runs but asserts nothing is worse than no test, because it reads as coverage:

```bash
# Tests with no assertion at all
grep -rLE 'assert|expect|should|require\.' --include='*test*' --include='*spec*' . 
# Assertions that can never fail
grep -rnE 'assert\s*\(\s*(True|true|1)\s*\)|expect\(true\)\.toBe\(true\)' --include='*test*' .
```

**Gate rule:** any behavior changed in the diff that lacks a non-happy-path **or** an edge case test fails this step. Record each gap explicitly — "no edge cases apply" is a claim that must be justified in the report, not a default.

### Step 7: Local E2E (Playwright)

The **full** suite, against a server this step starts and owns. Never against production.

```bash
PORT="${E2E_PORT:-4099}"     # dedicated, not the dev port

# 1. Kill stale listeners FIRST. On a shared box a suite can silently pass
#    against a sibling app's server — the failure mode is a green run that
#    proved nothing about this code.
lsof -ti :"$PORT" | xargs -r kill -9

# 2. Start the app and refuse to run specs until it is genuinely up
npm run start -- --port "$PORT" &
APP_PID=$!
trap 'kill $APP_PID 2>/dev/null; npm run e2e:teardown 2>/dev/null || true' EXIT

timeout 60 bash -c "until curl -fs localhost:$PORT/health >/dev/null; do sleep 1; done" \
  || { echo "ABORT: app never became healthy on :$PORT"; exit 1; }

# 3. Seed throwaway accounts in a scratch database
npm run e2e:seed

# 4. Run
npx playwright test --config playwright.config.ts
```

**Gate rule:** the health assertion is not optional. A suite that starts before the server is ready either flakes or — worse on a shared host — connects to whatever else is listening. Teardown runs via `trap` so a failed run still cleans up. If the project has no local E2E suite, record `NOT RUN`, not `SKIP`.

### Step 8: Dead Code Detection

Find unused exports, variables, imports, and unreachable code:

| Stack | Tool | Command |
|-------|------|---------|
| Python | Vulture | `vulture . --min-confidence 80` |
| Python | Ruff (unused imports) | `ruff check . --select F401,F841` |
| Node/TS | ESLint (unused vars) | `eslint . --rule '{"no-unused-vars": "error"}'` |
| Node/TS | Knip (unused exports/files/deps) | `npx knip` |
| Node/TS | ts-prune (unused exports) | `npx ts-prune` |
| Rust | Dead code warnings | `cargo build 2>&1 \| grep "warning.*dead_code\|warning.*unused"` |
| Go | Staticcheck (unused) | `staticcheck ./...` |
| Ruby | Debride | `debride .` |
| PHP | Psalm (unused) | `./vendor/bin/psalm --find-unused-code` |
| Java | SpotBugs (unused) | `./mvnw spotbugs:check` |

**Notes:**
- Use the tool selected by Step 0d's knip decision rule as the primary signal for Node/TS; the table above lists fallbacks by stack.
- For Python: prefer `vulture` for comprehensive dead code, `ruff --select F401,F841` for just unused imports/variables
- For Node/TS: `knip` when the Step 0d rule selects it (monorepo-aware: unused files, exports, dependencies); fall back to `ts-prune` for simpler unused export detection; use ESLint `no-unused-vars` as baseline
- For Rust: the compiler already warns on dead code by default; just check build output
- Semgrep also catches some dead code patterns via `p/javascript` and `p/python` rulesets (already run in Step 4)

### Step 9: Dependency Audit

| Stack | Audit Command |
|-------|--------------|
| Python | `pip-audit` or `safety check` |
| Node/TS | `npm audit --audit-level=high` |
| Rust | `cargo audit` |
| Go | `govulncheck ./...` |
| Ruby | `bundle audit check --update` |
| PHP | `composer audit` |

## Reasoning Phase (Steps 10–11)

Steps 1–9 are deterministic shell gates. Steps 10–11 are the **judgment passes** an agent performs over the diff — the reasoning counterpart absorbed into this skill from the former standalone reasoning skill. They run only after Steps 1–9 pass, because there is no reason to spend a reasoning pass on a diff that does not lint, build, or pass its tests.

**THE INVOKING AGENT APPLIES EDITS.** Steps 10–11 recommend and, where the invoking agent has write access, apply changes. The `code-reviewer` agent — the primary operator for this phase — declares `tools: Read, Grep, Glob, Bash` and has **no `Edit` or `Write` tool**. It cannot modify files itself. When `code-reviewer` runs Steps 10–11 standalone, its output is a report the invoking agent or a human applies; do not expect `code-reviewer` to have silently patched the diff. An orchestrator that wants edits applied automatically must delegate to an agent with `Edit`/`Write` (e.g. a framework specialist or `qa-engineer`) or apply the recommendations itself.

### Step 10: Parallel Analysis — One Message

Run the simplification lens and the review lens over the same diff in parallel, not sequentially — they read the same code and produce independent, non-overlapping findings, so there is no dependency forcing a second pass to wait on the first.

**Scope detection** (shared by both lenses). Default to the working-tree/branch diff, not the whole repo:

```bash
# Prefer the branch diff against the default branch
base=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null)
git diff --stat "$base"...HEAD 2>/dev/null || git diff --stat HEAD

# Fall back to unstaged + staged changes if not on a feature branch
git diff --stat && git diff --cached --stat
```

If there is no diff (e.g. reviewing an existing file set), review the explicitly named files only.

#### Lens 1: Simplification (behavior-preserving, five lenses)

Quality-only cleanup. **Does not hunt for bugs** — it makes correct code clearer. Every change must preserve behavior; tests must still pass afterward.

Review the diff for:

1. **Reuse** — Is this reimplementing something the codebase already provides? Replace with the existing helper/util/component.
2. **Simplification** — Unnecessary complexity, nested conditionals that flatten, redundant intermediate variables, dead branches.
3. **Efficiency** — Obvious wasteful work (repeated lookups, needless allocations, O(n²) where O(n) is trivial) — only when the fix is clear and behavior-preserving.
4. **Altitude** — Code sitting at the wrong abstraction level; logic that belongs in an existing layer.
5. **Naming & readability** — Unclear names, comments that restate the code, missing names for magic values.

**Constraint:** the *minimal* set of edits. Do not reformat untouched code, do not rename for taste, do not change public APIs. After edits are applied (by an agent with write access — see above), confirm the test suite still passes (Step 5).

**Output:** list of simplifications recommended (file:line → what changed → why), or "No simplifications needed."

#### Lens 2: Review (severity-rated, six dimensions)

The judgment pass. Delegate to the **`code-reviewer` agent** for a rigorous, security-aware review; it routes deep security/performance/refactor concerns to specialist sub-agents (`cyber-sentinel`, `performance-optimizer`). When running inline, evaluate each dimension below.

| Dimension | What to check |
|-----------|---------------|
| **Correctness** | Logic errors, off-by-one, wrong conditionals, unhandled return values, race conditions, incorrect assumptions about inputs |
| **Security** | Input validation, injection (SQL/command/XSS), authn/authz gaps, secrets in code, unsafe deserialization, SSRF — prefer secure-by-default libraries over hand-rolled crypto/sanitizers |
| **Error handling** | Swallowed exceptions, silent failures, missing error paths, single-path detection (see `silent-failure-audit`) |
| **Performance** | N+1 queries, unbounded loops/memory, blocking I/O on hot paths, missing pagination/indexes |
| **Maintainability** | SOLID / DRY / KISS violations, leaky abstractions, hidden coupling, untestable seams |
| **Test adequacy** | New logic without tests, missing edge/boundary/error cases, assertions that don't assert |

**Severity scale** (four levels, used everywhere in this pipeline):

| Severity | Meaning | Gate |
|----------|---------|------|
| 🔴 **Critical** | Security hole, data loss, or guaranteed incorrect behavior | **Blocks** |
| 🟠 **High** | Likely bug or real risk under realistic conditions | **Blocks** |
| 🟡 **Medium** | Maintainability/perf concern; should fix soon | Non-blocking |
| 🟢 **Low** | Nit, style, optional improvement | Non-blocking |

**Gate rule:** any 🔴 Critical or 🟠 High finding fails the review. A finding that was never evaluated (the reviewer ran out of scope, a dimension above was skipped) is recorded as `NOT RUN` for that dimension — never folded into "no findings."

### Step 11: Remediation Including Pre-Existing

Apply the findings from both lenses. Two distinct buckets, both in scope:

1. **Findings on the changed diff** — the direct output of Step 10.
2. **Pre-existing issues surfaced incidentally** — a Critical or High finding in code the diff merely touches (not authored by this change) still blocks Step 12. The zero-debt gate does not grandfather debt just because this diff didn't create it; it does require the finding to be **named**, not silently absorbed into scope creep.

**Constraint restated: the invoking agent applies edits.** `code-reviewer` (Read/Grep/Glob/Bash only) reports; it does not patch. Remediation happens either by the orchestrator applying the recommended diff, or by handing the report to an agent that holds `Edit`/`Write`.

**Output:** remediation applied (file:line → what changed), or the reason a finding was deferred (feeds Step 12's named-deferral rule).

### Step 12: Zero-Debt Gate

Every severity blocks. Debt is defined concretely so this is enforceable rather than aspirational.

| Blocks | Detection |
|--------|-----------|
| `TODO`/`FIXME` with no linked task id | `grep -rnE '(TODO\|FIXME)' --include='*.ts' --include='*.py' . \| grep -vE '#[0-9]+\|[A-Z]+-[0-9]+'` |
| `as any` / `# type: ignore` with no justification comment | `grep -rnE 'as any\|# type: ignore' . \| grep -v '//.*because\|#.*because'` |
| Empty `catch` blocks | `/silent-failure-audit` |
| `.backup` / `.old` / `.deprecated` files | `find . -name '*.backup' -o -name '*.old' -o -name '*.deprecated'` |
| Hardcoded secrets, mock data on production paths | Semgrep (step 4) + grep |
| Dead code | step 8 output |
| Any review finding, Critical through Low | step 10 output |

**Named deferral, never silent.** A deferral is permitted only when it is (a) justified in this run's report and (b) written to `PLAN.md`. An undocumented deferral is a gate failure. The principle is the same one the security gate uses: nothing is carried quietly. Any of the checks above that could not run for lack of a tool records `NOT RUN` and is not treated as a pass.

### Step 13: No-Regression Gate

Five sub-checks. Each either runs for real or is recorded as `NOT RUN` — never as a silent pass, and never as a bare comment describing a check that does not execute.

```bash
prev_tag=$(git describe --tags --abbrev=0 2>/dev/null)

# 1. Test count must not fall versus the previous release. Count test
#    DECLARATIONS in test files, stack-adaptively — not lines of a manifest,
#    which measures nothing about test coverage.
count_tests() {   # ref -> integer count
  local ref="$1" pattern='\b(it|test)\(|\bdef test_|\bfunc Test'
  git ls-tree -r --name-only "$ref" -- '*test*' '*spec*' '*_test.go' 2>/dev/null \
    | grep -E '\.(ts|tsx|js|jsx|py|go)$' \
    | while read -r f; do git show "$ref:$f" 2>/dev/null; done \
    | grep -cE "$pattern"
}

if [ -n "$prev_tag" ]; then
  prev_count=$(count_tests "$prev_tag")
  head_count=$(count_tests HEAD)
  echo "test declarations: previous=$prev_count head=$head_count"
  [ "$head_count" -lt "$prev_count" ] \
    && { echo "ABORT: test count dropped ($prev_count -> $head_count)"; exit 1; }
else
  echo "1. Test count:  NOT RUN — no previous tag to compare against (first release)"
fi

# 2. No newly-skipped tests
git diff "${prev_tag:-$(git rev-list --max-parents=0 HEAD)}"...HEAD -- '*test*' '*spec*' \
  | grep -E '^\+.*(\.skip|\.only|xit\(|xdescribe\()' \
  && { echo "ABORT: newly skipped tests without justification"; exit 1; }

# 3-5. These genuinely need per-project wiring; emit as NOT RUN rather than
#      silently absent, so they surface in the report as unexecuted checks.
echo "3. Coverage vs. previous release:      NOT RUN — requires per-project wiring: a coverage threshold plus a stored baseline (previous release's coverage %) to diff against"
echo "4. Previously-green E2E specs:         NOT RUN — requires per-project wiring: a record of which Step 7 specs passed on the previous release, to detect specs that flipped or were silently removed"
echo "5. Artifact size vs. previous release: NOT RUN — requires per-project wiring: a stored baseline artifact/bundle size and an acceptable-drift threshold"
```

**Gate rule:** a suite that shrank is a regression even when every remaining test passes. Deleting a failing test is the cheapest way to make a pipeline green, and sub-check 1 exists to make it visible — by counting actual test declarations, not a proxy. If there is no previous tag to compare against (first release), sub-check 1 records `NOT RUN` rather than a vacuous pass. Sub-checks 3–5 are unimplementable without project-specific configuration (a coverage tool's threshold, a baseline artifact size); recording them as `NOT RUN` with the exact wiring they need is the same principle Step 4's security gate already applies — an unexecuted check is never reported as passing.

### Step 14: Local Worker Purge

```bash
# Stale dev servers, orphaned test runners and detached build jobs left by
# earlier runs. Scope by working directory — a blind pkill is a defect even
# when it happens to work.
ps -eo pid,pcpu,args --sort=-pcpu | awk -v cwd="$PWD" 'NR>1 && $2>50 {print}' | head -20
# Review, then kill by PID within this project's tree only.
```

**Gate rule:** never `pkill -f node`. On a machine running sibling projects that stops someone else's work.

## Output Format

```markdown
## Quality Gate Report

| Step | Status | Details |
|------|--------|---------|
| 0a Stack Detection | [stack] | Auto-detected: [languages/frameworks] |
| 0c Version Consistency | PASS/FAIL | ./scripts/check-version-consistency.sh result |
| 0d knip Decision | [tool]/NOT RUN | tool selected for this stack |
| Lint | PASS/FAIL | [error count] errors, [warning count] warnings |
| Type Check | PASS/FAIL/NOT RUN | [error count] type errors |
| Build | PASS/FAIL | compile/bundle result |
| security-guidance | ARMED/NOT RUN | hooks armed; agent SDK importable |
| Semgrep SAST | PASS/FAIL/NOT RUN | [finding count] findings ([critical]/[high]/[medium]) |
| Security Review | PASS/FAIL/NOT RUN | [n] HIGH, [n] MEDIUM — HIGH blocks |
| Tests | PASS/FAIL | [passed]/[total] tests, [coverage]% coverage |
| Test Case Matrix | PASS/FAIL | [n] behaviors changed: [n] happy, [n] non-happy, [n] edge — [n] gaps |
| Local E2E | PASS/FAIL/NOT RUN | [passed]/[total] specs |
| Dead Code | PASS/FAIL/NOT RUN | [count] unused exports/vars/imports found |
| Dependency Audit | PASS/FAIL | [vuln count] vulnerabilities found |
| Simplification (Lens 1) | DONE | [n] simplifications recommended/applied |
| Review (Lens 2) | PASS/FAIL | 🔴[n] 🟠[n] 🟡[n] 🟢[n] |
| Zero-Debt Gate | PASS/FAIL | [n] debt items, [n] named deferrals |
| No-Regression Gate | PASS/FAIL/NOT RUN | test count / coverage / bundle size vs. previous release |
| Worker Purge | DONE | [n] stale processes reviewed |

### Test Case Matrix Detail

| Changed Behavior | Happy | Non-Happy | Edge | Gap |
|------------------|-------|-----------|------|-----|
| [function/endpoint] | ✅ | ✅ | ❌ | Missing empty-input and max-length cases |

### Review Findings

| # | Severity | Dimension | File:Line | Finding | Suggested Fix |
|---|----------|-----------|-----------|---------|---------------|
| 1 | 🔴 Critical | Security | api/upload.ts:88 | Unvalidated path → traversal | Resolve + allowlist base dir |
| 2 | 🟡 Medium | Perf | db/users.ts:30 | N+1 on roles | Eager-load with join |

### Gate Result: PASS / FAIL

### Blocking Issues (if any)
1. [Issue description] - [file:line]
2. ...

### Recommendations
- [Non-blocking suggestions]
```

## CI/CD Integration

Invoke the gate as **one opaque step** — never re-list its individual checks in a workflow file:

```yaml
- name: Quality Gate
  run: |  # invoke /pipeline-quality (or the project's equivalent gate command)
```

A partial copy of Steps 0–14 is a second, lossy definition of the gate: it silently stops covering whatever check is added here later, the same drift `pr-ready` must guard against. If you need a fuller GitHub Actions template — matrix builds, caching, artifact upload — see the `github-actions` skill; it should still call this gate as a single step, not re-implement it.

## Position in the Release Chain

This skill is the **checks-only gate** that precedes release automation. It is called by `pipeline-full-build-cloud` and `pipeline-full-build-desktop` as their pre-build quality gate, and can be invoked standalone for a diff review or simplification pass.

- **`pipeline-full-build-cloud`** and **`pipeline-full-build-desktop`** are the two callers: each runs this skill's Steps 0–14 before proceeding to its own Phase 3 build (native compilation, container/SBOM, signing, deploy). Neither variant re-implements lint, security, or test logic — they consume this skill's PASS/FAIL result.
- **The invoking agent applies edits.** `code-reviewer`, the primary operator for Steps 10–11, declares `tools: Read, Grep, Glob, Bash` and has no `Edit` or `Write` tool — it cannot write the simplifications or remediations it recommends. An orchestrator or an agent with write access applies them; do not expect `code-reviewer` alone to leave the working tree changed.
- This skill stops at Step 14. Commit, merge, tag, release, and deploy are entirely out of scope here and belong to the variant skills.
