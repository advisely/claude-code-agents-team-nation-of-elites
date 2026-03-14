---
name: pipeline-quality
description: Universal quality gate pipeline - lint, Semgrep SAST, tests, and dependency audit. Stack-adaptive for desktop (Electron+Python) and cloud (web/API) projects.
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
- `tech-lead-orchestrator` - Quality enforcement

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

### Step 4: Semgrep SAST Scan

```bash
# Default security scan
semgrep scan --config auto --error .

# Or via MCP plugin: use semgrep_scan tool

# For supply chain vulnerabilities
semgrep ci --supply-chain
```

**Gate rule:** Any ERROR-severity finding blocks the pipeline.

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

### Step 6: Dependency Audit

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
| Semgrep SAST | PASS/FAIL | [finding count] findings ([critical]/[high]/[medium]) |
| Tests | PASS/FAIL | [passed]/[total] tests, [coverage]% coverage |
| Dependency Audit | PASS/FAIL | [vuln count] vulnerabilities found |

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

      - name: Semgrep SAST
        uses: semgrep/semgrep-action@v1
        with:
          config: p/default p/owasp-top-ten p/secrets

      - name: Tests
        run: |  # Stack-specific test command

      - name: Dependency Audit
        run: |  # Stack-specific audit command
```
