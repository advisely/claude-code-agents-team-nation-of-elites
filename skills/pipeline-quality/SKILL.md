---
name: pipeline-quality
description: Universal quality gate pipeline - lint, type check, a three-part security gate (security-guidance readiness, Semgrep SAST, /security-review), tests, happy/non-happy/edge case coverage matrix, dead code detection, and dependency audit. Records NOT RUN rather than passing a check that never executed. Stack-adaptive for desktop (Electron+Python) and cloud (web/API) projects.
---

# Pipeline Quality Gate

Universal quality gate that auto-detects your stack and runs the appropriate checks. Use as a pre-merge gate or standalone quality check.

## When to Use This Skill

- Before merging any PR (quality gate)
- After completing a feature implementation
- As a periodic codebase health check
- When onboarding to a new project (baseline scan)

## Target Agents

- `code-reviewer` - Quality gate during reviews
- `cyber-sentinel` - Security scanning pass
- `qa-engineer` - Automated validation
- `devops-engineer` - CI/CD pipeline integration
- `chief-operations-orchestrator` - Quality enforcement

## Pipeline Steps

### Step 1: Stack Detection

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

### Step 2: Lint

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

### Step 3: Type Check (if applicable)

| Stack | Type Check Command |
|-------|-------------------|
| TypeScript | `npx tsc --noEmit` |
| Python | `mypy .` or `pyright` |

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
cargo tarpaulin --out Stdout                           # Rust
```

**Assertion quality check** — a test that runs but asserts nothing is worse than no test, because it reads as coverage:

```bash
# Tests with no assertion at all
grep -rLE 'assert|expect|should|require\.' --include='*test*' --include='*spec*' . 
# Assertions that can never fail
grep -rnE 'assert\s*\(\s*(True|true|1)\s*\)|expect\(true\)\.toBe\(true\)' --include='*test*' .
```

**Gate rule:** any behavior changed in the diff that lacks a non-happy-path **or** an edge case test fails this step. Record each gap explicitly — "no edge cases apply" is a claim that must be justified in the report, not a default.

### Step 7: Dead Code Detection

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
- For Python: prefer `vulture` for comprehensive dead code, `ruff --select F401,F841` for just unused imports/variables
- For Node/TS: prefer `knip` for monorepo-aware analysis (unused files, exports, dependencies); fall back to `ts-prune` for simpler unused export detection; use ESLint `no-unused-vars` as baseline
- For Rust: the compiler already warns on dead code by default; just check build output
- Semgrep also catches some dead code patterns via `p/javascript` and `p/python` rulesets (already run in Step 4)

### Step 8: Dependency Audit

| Stack | Audit Command |
|-------|--------------|
| Python | `pip-audit` or `safety check` |
| Node/TS | `npm audit --audit-level=high` |
| Rust | `cargo audit` |
| Go | `govulncheck ./...` |
| Ruby | `bundle audit check --update` |
| PHP | `composer audit` |

## Output Format

```markdown
## Quality Gate Report

| Step | Status | Details |
|------|--------|---------|
| Stack Detection | [stack] | Auto-detected: [languages/frameworks] |
| Lint | PASS/FAIL | [error count] errors, [warning count] warnings |
| Type Check | PASS/FAIL/SKIP | [error count] type errors |
| security-guidance | ARMED/NOT RUN | hooks armed; agent SDK importable |
| Semgrep SAST | PASS/FAIL/**NOT RUN** | [finding count] findings ([critical]/[high]/[medium]) |
| Security Review | PASS/FAIL/**NOT RUN** | [n] HIGH, [n] MEDIUM — HIGH blocks |
| Tests | PASS/FAIL | [passed]/[total] tests, [coverage]% coverage |
| Test Case Matrix | PASS/FAIL | [n] behaviors changed: [n] happy, [n] non-happy, [n] edge — [n] gaps |
| Dead Code | PASS/FAIL/SKIP | [count] unused exports/vars/imports found |
| Dependency Audit | PASS/FAIL | [vuln count] vulnerabilities found |

### Test Case Matrix Detail

| Changed Behavior | Happy | Non-Happy | Edge | Gap |
|------------------|-------|-----------|------|-----|
| [function/endpoint] | ✅ | ✅ | ❌ | Missing empty-input and max-length cases |

### Gate Result: PASS / FAIL

### Blocking Issues (if any)
1. [Issue description] - [file:line]
2. ...

### Recommendations
- [Non-blocking suggestions]
```

## Desktop Variant (Electron + Python)

For Electron/desktop projects, add these checks:

```bash
# Electron-specific
npx electron-builder --check  # Validate build config
npm run typecheck              # Full TS check including main/renderer

# Python backend (if hybrid)
ruff check . --fix
semgrep scan --config auto --error .
pytest -x --tb=short
```

## Cloud Variant (Web/API)

For cloud/web projects, add infrastructure checks:

```bash
# Infrastructure validation
[ -f "terraform" ] && terraform validate
[ -f "Dockerfile" ] && docker build --check .
[ -f "k8s/" ] && kubectl apply --dry-run=client -f k8s/

# API contract validation
[ -f "openapi.yaml" ] && npx @redocly/cli lint openapi.yaml
```

## CI/CD Template (GitHub Actions)

```yaml
name: Quality Gate
on: [pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Lint
        run: |  # Stack-specific lint command

      - name: Security Gate (Semgrep SAST)
        uses: semgrep/semgrep-action@v1
        with:
          config: p/default p/owasp-top-ten p/secrets

      - name: Tests
        run: |  # Stack-specific test command

      - name: Test Case Matrix (branch coverage)
        run: |  # e.g. pytest --cov --cov-branch --cov-fail-under=80

      - name: Dependency Audit
        run: |  # Stack-specific audit command
```

## Position in the Release Chain

This skill is **Step 1 of the Verify phase** in `/pipeline-full-build`. It runs before `/pipeline-review` because it is cheap and fails fast — no reason to spend reasoning passes on a diff that does not lint or compile.
