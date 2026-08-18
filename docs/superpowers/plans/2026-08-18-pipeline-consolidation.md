# Pipeline Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Collapse the five-skill pipeline family into three self-contained skills, fix a silent gate failure in the severity scale, and eliminate documentation drift behind a permanent gate.

**Architecture:** `pipeline-quality` becomes a checks-only skill spanning deterministic gates (steps 1–9), a reasoning fan-out (10–11) and consuming gates (12–14). `pipeline-full-build-cloud` and `pipeline-full-build-desktop` each become complete standalone release chains that invoke it. `pipeline-full-build` and `pipeline-review` are deleted after every call site is rewired.

**Tech Stack:** Markdown skill definitions with YAML frontmatter; Bash verification scripts; git.

**Spec:** `docs/superpowers/specs/2026-08-18-pipeline-consolidation-design.md`

## Global Constraints

- Target version is **4.0.0**; `.claude-plugin/plugin.json` is the single source of truth for it.
- Final skill count is **33** (`skills/` currently holds 35; two directories are deleted).
- Severity scale is exactly four levels everywhere: **Critical / High / Medium / Low** (🔴 / 🟠 / 🟡 / 🟢).
- Deployment target for the cloud variant is **VPS + `docker compose` over SSH**; Kubernetes is a secondary branch, never the primary path.
- Every destructive or resource-claiming command must be **app-scoped**; `docker system prune -a` and `--volumes` are forbidden.
- `NOT RUN is not PASS` — a check that did not execute is recorded as `NOT RUN`, never as a pass.
- `CHANGELOG.md` historical mentions of deleted skills are **left untouched** — they are a record, not a reference.
- Work happens on branch `feat/v4.0.0-pipeline-consolidation`. Commit after every task. Tree must be clean and not behind `origin` at completion.
- These skills are documentation, not executable code. The "test" for each task is a Bash assertion in `scripts/`, run before and after the change.

---

### Task 1: Verification Harness

Builds the two scripts that gate every later task. `check-version-consistency.sh` is a permanent deliverable (spec §2b) that `pipeline-quality` will invoke; `verify-consolidation.sh` encodes the spec's acceptance criteria and is the migration's test suite.

**Files:**
- Create: `scripts/check-version-consistency.sh`
- Create: `scripts/verify-consolidation.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: two executable scripts. `check-version-consistency.sh` exits 0 when every declared version and skill count agrees with `plugin.json`, 1 otherwise. `verify-consolidation.sh` exits 0 when all seven acceptance criteria hold, 1 otherwise. Later tasks run both.

- [ ] **Step 1: Write the version-consistency check (the failing test)**

```bash
mkdir -p scripts
cat > scripts/check-version-consistency.sh <<'EOF'
#!/usr/bin/env bash
# Assert every declared version and skill count agrees with plugin.json.
# plugin.json is the single source of truth. Used by /pipeline-quality step 0.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0
note() { printf '  %-5s %s\n' "$1" "$2"; }

VERSION=$(grep -m1 '"version"' .claude-plugin/plugin.json \
  | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
COUNT=$(find skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
echo "source of truth: version=$VERSION skills=$COUNT"

check() {  # label, actual
  if [ "$2" = "$3" ]; then note ok "$1"; else
    note FAIL "$1 says '${2:-missing}', expected '$3'"; fail=1
  fi
}

check "README version badge" \
  "$(grep -oE 'badge/version-[0-9.]+' README.md | head -1 | sed 's/.*version-//')" "$VERSION"
check "README footer version" \
  "$(grep -oE 'Nation of Elites v[0-9.]+' README.md | head -1 | sed 's/.*v//')" "$VERSION"
check "README skills badge" \
  "$(grep -oE 'badge/skills-[0-9]+' README.md | head -1 | sed 's/.*skills-//')" "$COUNT"
check "README body count" \
  "$(grep -oE '\*\*[0-9]+ custom skills\*\*' README.md | head -1 | grep -oE '[0-9]+')" "$COUNT"
check "README footer count" \
  "$(grep -oE '\| [0-9]+ Skills' README.md | head -1 | grep -oE '[0-9]+')" "$COUNT"
check "CLAUDE.md body count" \
  "$(grep -oE '\*\*[0-9]+ custom skills\*\*' CLAUDE.md | head -1 | grep -oE '[0-9]+')" "$COUNT"
check "CLAUDE.md Cowork row" \
  "$(grep -oE 'Skills \([0-9]+\)' CLAUDE.md | head -1 | grep -oE '[0-9]+')" "$COUNT"
check "plugin.json description" \
  "$(grep -oE '[0-9]+ skills' .claude-plugin/plugin.json | head -1 | grep -oE '[0-9]+')" "$COUNT"

# Catch-all: ANY "<n> skills" / "<n> custom skills" claim anywhere in the docs
# must equal COUNT. The targeted checks above cover known phrasings; this
# catches a count hiding in a sentence nobody thought to pattern-match.
while IFS= read -r hit; do
  n=$(sed -E 's/.*[^0-9]([0-9]+) (custom )?skills.*/\1/' <<<"$hit")
  [ "$n" = "$COUNT" ] || { note FAIL "stale count: $hit"; fail=1; }
done < <(grep -rnoE '[0-9]+ (custom )?skills' README.md CLAUDE.md CONTRIBUTING.md \
           .claude-plugin/plugin.json docs/rules/*.md 2>/dev/null)

[ "$fail" -eq 0 ] && echo "version consistency: PASS" || echo "version consistency: FAIL"
exit "$fail"
EOF
chmod +x scripts/check-version-consistency.sh
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./scripts/check-version-consistency.sh`
Expected: FAIL. At v3.18.0 with 35 skills it should report the README version badge as 3.13.0, the footer as 3.14.0, the skills badge as 32, the README footer count as 33, and the CLAUDE.md Cowork row as 33.

- [ ] **Step 3: Write the acceptance-criteria check (the second failing test)**

```bash
cat > scripts/verify-consolidation.sh <<'EOF'
#!/usr/bin/env bash
# Acceptance criteria for the v4.0.0 pipeline consolidation.
# Spec: docs/superpowers/specs/2026-08-18-pipeline-consolidation-design.md
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0
note() { printf '  %-5s %s\n' "$1" "$2"; }

# Skill names that legitimately do not live in skills/ — official Anthropic
# and Cowork built-ins. CLAUDE.md says not to duplicate these.
EXTERNAL='pdf|docx|pptx|xlsx|canvas-design|webapp-testing|artifacts-builder'

# AC1 — exactly 33 skill directories, the two consolidated ones gone
n=$(find skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
[ "$n" = "33" ] && note ok "AC1 skill count 33" || { note FAIL "AC1 skill count is $n, expected 33"; fail=1; }
for d in pipeline-full-build pipeline-review; do
  [ -d "skills/$d" ] && { note FAIL "AC1 skills/$d still exists"; fail=1; } || note ok "AC1 skills/$d removed"
done

# AC2 — no live references to the deleted skills (CHANGELOG and specs/plans are records)
refs=$(grep -rln 'pipeline-review\|pipeline-full-build[^-]' \
        --include='*.md' --include='*.json' . 2>/dev/null \
        | grep -v node_modules | grep -v CHANGELOG.md | grep -v docs/superpowers/ || true)
[ -z "$refs" ] && note ok "AC2 no live refs to deleted skills" \
  || { note FAIL "AC2 live refs remain in: $(echo "$refs" | tr '\n' ' ')"; fail=1; }

# AC3 — in the two files that discuss nothing but skills and agents, every
# backticked kebab-case name must resolve to a real skill, a real agent, or a
# documented external built-in. Anything else is a phantom reference.
AGENTS=$(grep -rhoE '^name: [a-z0-9-]+' agents/ 2>/dev/null | sed 's/^name: //' | sort -u)
missing=""
for f in CONTRIBUTING.md docs/rules/skills-integration.md; do
  [ -f "$f" ] || continue
  for n in $(grep -ohE '`[a-z0-9]+(-[a-z0-9]+)+`' "$f" | tr -d '`' | sort -u); do
    [ -d "skills/$n" ]                  && continue
    grep -qx "$n" <<<"$AGENTS"          && continue
    grep -qE "^($EXTERNAL)$" <<<"$n"    && continue
    missing="$missing $f:$n"
  done
done
[ -z "$missing" ] && note ok "AC3 referenced names resolve" \
  || { note FAIL "AC3 unresolved:$missing"; fail=1; }

# AC3b — agent frontmatter skills: lists must resolve
badfm=""
while IFS= read -r line; do
  f=${line%%:*}; list=${line#*skills: [}; list=${list%]}
  for n in $(echo "$list" | tr ',' ' '); do
    [ -d "skills/$n" ] || badfm="$badfm $f:$n"
  done
done < <(grep -rn '^skills: \[' agents/ 2>/dev/null)
[ -z "$badfm" ] && note ok "AC3b agent frontmatter resolves" \
  || { note FAIL "AC3b unresolved frontmatter:$badfm"; fail=1; }

# AC4 — version consistency (delegated)
./scripts/check-version-consistency.sh >/dev/null 2>&1 \
  && note ok "AC4 version consistency" \
  || { note FAIL "AC4 version consistency (run scripts/check-version-consistency.sh)"; fail=1; }

# AC5 — one severity scale: 'Major'/'Minor' must not survive as severity labels
legacy=$(grep -rln '🟡 \*\*Major\*\*\|🟢 \*\*Minor\*\*' agents/ skills/ 2>/dev/null || true)
[ -z "$legacy" ] && note ok "AC5 single severity scale" \
  || { note FAIL "AC5 legacy Major/Minor scale in: $(echo "$legacy" | tr '\n' ' ')"; fail=1; }

# AC6 — each of the three skills exists and is self-contained
for s in pipeline-quality pipeline-full-build-cloud pipeline-full-build-desktop; do
  [ -f "skills/$s/SKILL.md" ] && note ok "AC6 $s present" \
    || { note FAIL "AC6 skills/$s/SKILL.md missing"; fail=1; }
done

# AC7 — clean tree, not behind origin
[ -z "$(git status --porcelain)" ] && note ok "AC7 tree clean" \
  || { note FAIL "AC7 uncommitted changes present"; fail=1; }
behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
[ "$behind" = "0" ] && note ok "AC7 not behind upstream" \
  || { note FAIL "AC7 branch is $behind commits behind upstream"; fail=1; }

[ "$fail" -eq 0 ] && echo "CONSOLIDATION: PASS" || echo "CONSOLIDATION: FAIL"
exit "$fail"
EOF
chmod +x scripts/verify-consolidation.sh
```

- [ ] **Step 4: Run it to verify it fails**

Run: `./scripts/verify-consolidation.sh`
Expected: FAIL on AC1 (35 skills, both directories present), AC2 (live refs), AC4 (version drift), AC5 (Major/Minor in `Code_Reviewer.md`).

- [ ] **Step 5: Commit**

```bash
git add scripts/check-version-consistency.sh scripts/verify-consolidation.sh
git commit -m "test: add version-consistency and consolidation acceptance checks"
```

---

### Task 2: Unify the Severity Scale

Ships first because it is the only actively-harmful defect in the set: `pipeline-review` gates on 🔴/🟠 while `code-reviewer` emits 🔴/🟡/🟢, so the delegate's blocking findings arrive labelled non-blocking.

**Files:**
- Modify: `agents/03_Engineering_Division/Code_Excellence_Guild/Code_Reviewer.md:34-38`

**Interfaces:**
- Consumes: `scripts/verify-consolidation.sh` from Task 1.
- Produces: the canonical four-level scale `🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low`, referenced by name in Tasks 3–5.

- [ ] **Step 1: Confirm the check fails**

Run: `./scripts/verify-consolidation.sh 2>&1 | grep AC5`
Expected: `FAIL  AC5 legacy Major/Minor scale in: agents/03_Engineering_Division/Code_Excellence_Guild/Code_Reviewer.md`

- [ ] **Step 2: Replace the three-level scale with the four-level scale**

Replace lines 34–38 of `Code_Reviewer.md`:

```markdown
4. **Severity & Delegation**
   • 🔴 **Critical** – security hole, data loss, or guaranteed incorrect behavior. **Blocks merge.** If security → delegate to `cyber-sentinel`.
   • 🟠 **High** – likely bug or real risk under realistic conditions. **Blocks merge.** If perf → delegate to `performance-optimizer`.
   • 🟡 **Medium** – maintainability or performance concern; should fix soon. Non-blocking by severity, but see the zero-debt gate in `/pipeline-quality`.
   • 🟢 **Low** – nit, style, optional improvement. Non-blocking by severity, but see the zero-debt gate in `/pipeline-quality`.
   • When complexity/refactor needed → delegate to `backend-developer` or `frontend-developer`.

> **Scale contract.** These four levels are the same ones `/pipeline-quality` gates on. Do not emit any other severity word — a label the gate does not recognise is read as non-blocking, which is how a blocking finding ships silently.
```

- [ ] **Step 3: Update the report format section to match**

Search `Code_Reviewer.md` for the report template and replace any `Major`/`Minor` headings with `High`/`Medium`/`Low` so the emitted report uses the same words as the scale.

```bash
grep -n 'Major\|Minor' agents/03_Engineering_Division/Code_Excellence_Guild/Code_Reviewer.md
```

- [ ] **Step 4: Verify the check passes**

Run: `./scripts/verify-consolidation.sh 2>&1 | grep AC5`
Expected: `ok    AC5 single severity scale`

- [ ] **Step 5: Commit**

```bash
git add agents/03_Engineering_Division/Code_Excellence_Guild/Code_Reviewer.md
git commit -m "fix: unify code-reviewer severity scale with the pipeline gate

The agent emitted Critical/Major/Minor while the gate blocked on
Critical/High. A Major finding — semantically High — arrived wearing
Medium's colour and passed a gate that should have stopped it."
```

---

### Task 3: Rewrite `pipeline-quality`

The largest task. Produces the checks-only skill with the operator's 8-step spine generalized, plus five new steps.

**Files:**
- Modify: `skills/pipeline-quality/SKILL.md` (full rewrite)

**Interfaces:**
- Consumes: the four-level severity scale from Task 2; `scripts/check-version-consistency.sh` from Task 1.
- Produces: step numbering `0`–`14` referenced by Tasks 4, 5 and 6. Step 0 = stack detection + version consistency + knip rule. Steps 1–9 deterministic. Steps 10–11 reasoning. Steps 12–14 consuming gates. Skill invoked as `/pipeline-quality`.

- [ ] **Step 1: Rewrite the frontmatter so routing survives the merge**

The description must trigger on review phrasing as well as gate phrasing, or the merged skill silently stops being selected for "review my diff" requests.

```yaml
---
name: pipeline-quality
description: Universal pre-merge pipeline - lint, type check, build, a three-part security gate, tests, a happy/non-happy/edge case matrix, local Playwright E2E, conditional knip/dead-code analysis, dependency audit, then a parallel simplification and severity-rated code review, a zero-technical-debt gate and a no-regression gate. Use to review a diff, simplify code, or run the full quality gate. Stops before git - no commit, no release, no deploy. Records NOT RUN rather than passing a check that never executed. Stack-adaptive for desktop (Electron+Python) and cloud (web/API) projects.
---
```

- [ ] **Step 2: Write the step table as the skill's contract**

```markdown
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
```

- [ ] **Step 3: Carry over steps 1–6, 8, 9 from the existing file**

Preserve verbatim from the current `SKILL.md`: stack detection (Step 1), lint table (Step 2), type check table (Step 3), the three-part security gate (Step 4 — `security-guidance` readiness, Semgrep, `/security-review`), tests table (Step 5), the test case coverage matrix (Step 6), dead code table (Step 7 → renumbered 8), dependency audit (Step 8 → renumbered 9). Insert `Build` as the new step 3 using the build commands currently in the variant skills. **Delete** the "Desktop Variant" and "Cloud Variant" sections at the end — those move to the variant skills (spec §1a, single-home rule).

- [ ] **Step 4: Add Step 0's version consistency and knip decision rule**

```markdown
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
```

- [ ] **Step 5: Add Step 7 — local E2E**

```markdown
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

**Gate rule:** the health assertion is not optional. A suite that starts before the server is ready either flakes or — worse on a shared host — connects to whatever else is listening. Teardown runs via `trap` so a failed run still cleans up.
```

- [ ] **Step 6: Add Steps 12, 13, 14**

```markdown
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

**Named deferral, never silent.** A deferral is permitted only when it is (a) justified in this run's report and (b) written to `PLAN.md`. An undocumented deferral is a gate failure. The principle is the same one the security gate uses: nothing is carried quietly.

### Step 13: No-Regression Gate

```bash
# Test count must not fall versus the previous release
prev=$(git show "$(git describe --tags --abbrev=0)":package.json 2>/dev/null | grep -c . || echo 0)
# (project-specific: resumeflex has `npm run check:docs -- --test-count=<n>`)

# No newly-skipped tests
git diff "$(git describe --tags --abbrev=0)"...HEAD -- '*test*' '*spec*' \
  | grep -E '^\+.*(\.skip|\.only|xit\(|xdescribe\()' \
  && { echo "ABORT: newly skipped tests without justification"; exit 1; }

# Coverage must not fall; bundle size within threshold of the previous release
```

**Gate rule:** a suite that shrank is a regression even when every remaining test passes. Deleting a failing test is the cheapest way to make a pipeline green, and this step exists to make it visible.

### Step 14: Local Worker Purge

```bash
# Stale dev servers, orphaned test runners and detached build jobs left by
# earlier runs. Scope by working directory — a blind pkill is a defect even
# when it happens to work.
ps -eo pid,pcpu,args --sort=-pcpu | awk -v cwd="$PWD" 'NR>1 && $2>50 {print}' | head -20
# Review, then kill by PID within this project's tree only.
```

**Gate rule:** never `pkill -f node`. On a machine running sibling projects that stops someone else's work.
```

- [ ] **Step 7: Update the output format and the closing section**

Extend the report table with the new rows (Version Consistency, Build, Local E2E, Zero-Debt, No-Regression, Worker Purge), each recording PASS / FAIL / NOT RUN. Replace the "Position in the Release Chain" section with one that names the two variant skills as callers and states explicitly: **the invoking agent applies edits — `code-reviewer` declares `tools: Read, Grep, Glob, Bash` and cannot write files.**

- [ ] **Step 8: Verify**

Run: `grep -c 'pipeline-review' skills/pipeline-quality/SKILL.md`
Expected: `0`

Run: `./scripts/verify-consolidation.sh 2>&1 | grep AC6`
Expected: `ok    AC6 pipeline-quality present`

- [ ] **Step 9: Commit**

```bash
git add skills/pipeline-quality/SKILL.md
git commit -m "feat(pipeline-quality): absorb review passes, add E2E/debt/regression gates"
```

---

### Task 4: Rewrite `pipeline-full-build-cloud`

**Files:**
- Modify: `skills/pipeline-full-build-cloud/SKILL.md` (full rewrite)

**Interfaces:**
- Consumes: `/pipeline-quality` steps 0–14 from Task 3; the severity scale from Task 2.
- Produces: a complete standalone chain, steps 0–13, invoked as `/pipeline-full-build-cloud`. No longer references a parent skill.

- [ ] **Step 1: Rewrite the frontmatter to describe a complete chain**

```yaml
---
name: pipeline-full-build-cloud
description: Complete standalone release chain for web/API apps deployed to a VPS or container platform - preflight, failsafe backup including a remote database dump, the full quality gate, commit/merge/push, container or compose build, GitHub release, deploy over SSH with an image-ID rollback target, production Playwright smoke with temporary accounts, post-deploy verification, documentation, worker purge and app-scoped cleanup.
---
```

- [ ] **Step 2: Add Step 0 — preflight**

```bash
# Refuse to start on a dirty tree or a branch behind origin. A release built
# from a tree that does not match the remote is unreproducible.
[ -z "$(git status --porcelain)" ] || { echo "ABORT: uncommitted changes"; exit 1; }
git fetch origin --quiet
behind=$(git rev-list --count HEAD..origin/main)
[ "$behind" = "0" ] || { echo "ABORT: $behind commits behind origin/main"; exit 1; }
```

- [ ] **Step 3: Carry the shared spine over from the deleted parent**

Copy from `skills/pipeline-full-build/SKILL.md` before deleting it in Task 7: Step 0 failsafe backup with the retention invariant, the version bump, the commit / merge / push steps including the post-rebase gate re-run, the release step, the two documentation steps, and the backup retention rule. Renumber to 0–13 per spec §3. Add the remote database dump to the backup step:

```bash
ssh "$VPS_HOST" "docker exec $DB_CONTAINER pg_dump -U $DB_USER -Fc $DB_NAME" \
  > "$BACKUP_ROOT/db-$STAMP.dump"
[ -s "$BACKUP_ROOT/db-$STAMP.dump" ] || { echo "ABORT: empty database dump"; exit 1; }
```

- [ ] **Step 4: Replace the Kubernetes deploy with compose-over-SSH as the primary path**

```markdown
### Step 8: Deploy to Production (VPS + docker compose)

```bash
# Capture the rollback target BY IMAGE ID, not by tag row.
# Tag rows are not images: a repository with three tags pointing at two
# images makes the third row the second image, and a cleanup that counts
# rows deletes the rollback target. That is a recorded incident, not a
# hypothetical — resumeflex lost its rollback target this way on 2026-07-30.
ROLLBACK_ID=$(ssh "$VPS_HOST" "docker inspect --format='{{.Image}}' $APP_CONTAINER")
ssh "$VPS_HOST" "docker tag $ROLLBACK_ID $APP_IMAGE:rollback-previous"
echo "$ROLLBACK_ID" > .previous-deployed-version

# Sync and bring up. Two shapes, both supported:
#   a) rsync source, build on the VPS
rsync -avz --delete "${RSYNC_EXCLUDES[@]}" ./ "$VPS_HOST:$REMOTE_APP_DIR/"
ssh "$VPS_HOST" "cd $REMOTE_APP_DIR && docker compose -f $COMPOSE_FILE up -d --build"
#   b) build locally, push to a registry, pull remotely
#      docker push "$REGISTRY/app:$new" && ssh "$VPS_HOST" "cd $REMOTE_APP_DIR && docker compose pull && docker compose up -d"

# Health-gate before declaring success
timeout 120 bash -c "until [ \"\$(ssh $VPS_HOST \"docker inspect -f '{{.State.Health.Status}}' $APP_CONTAINER\")\" = healthy ]; do sleep 5; done" \
  || { echo "ABORT: container never became healthy"; exit 1; }
```

**Rollback — one command, and it is real because the image is retained:**

```bash
ssh "$VPS_HOST" "cd $REMOTE_APP_DIR && docker tag $APP_IMAGE:rollback-previous $APP_IMAGE:latest && docker compose up -d"
```

**Kubernetes (secondary).** Where the target is a cluster rather than a VPS, substitute `kubectl set image` / `kubectl rollout status` / `kubectl rollout undo` with a canary stage. The gate rules are unchanged.
```

- [ ] **Step 5: Add Step 9 — production E2E with temporary accounts**

```markdown
### Step 9: Production E2E (critical path only)

Not a re-run of step 7 of `/pipeline-quality`. **Admission rule: a spec earns a place here only if it can fail in production while passing locally.** Everything else stays local.

Scope: login, one authenticated write, one authenticated read, logout. Nothing more.

```bash
RUN_ID=$(git rev-parse --short HEAD)
export E2E_ACCOUNT="e2e+${RUN_ID}@example.com"

# Refuse to start without teardown credentials. Creating accounts you cannot
# remove is worse than skipping the check.
[ -n "${E2E_ADMIN_TOKEN:-}" ] || { echo "SKIP: no teardown credentials — recorded as NOT RUN"; exit 0; }

# Sweep orphans from earlier failed runs BEFORE creating new ones
npm run e2e:sweep-orphans -- --pattern 'e2e+*@example.com' --older-than 1h

trap 'npm run e2e:teardown -- --account "$E2E_ACCOUNT"' EXIT

npx playwright test --config playwright.prod.config.ts \
  --grep @critical-path \
  --base-url "https://$DOMAIN"
```

All test traffic carries an analytics-exclusion header so the run does not pollute production metrics.

**Gate rule:** a failure here triggers the rollback gate. It cannot block in the ordinary sense because the tag and release already exist — the release is marked **superseded** rather than having its tag deleted, since deleting a published tag breaks anyone who already fetched it.

**Why this step exists.** Local tests cannot observe real TLS termination, the `X-Forwarded-For` chain, the real database, or real email dispatch. The v6.7.x contact-form failure was a proxy-layer 401 that every local test passed straight over; a Playwright run against production is what found it.
```

- [ ] **Step 6: Add Step 12 — worker purge, and rewrite Step 13 — cleanup, both app-scoped**

```markdown
### Step 12: Purge CPU-Eating Workers (local + VPS)

```bash
# Local
ps -eo pid,pcpu,args --sort=-pcpu | awk 'NR>1 && $2>50' | head -20

# VPS — scope to THIS app's containers. The box is multi-app.
ssh "$VPS_HOST" "docker stats --no-stream --format '{{.Name}}\t{{.CPUPerc}}' \
  | grep '^${APP_PREFIX}'"
```

**Gate rule:** identify, then kill by PID or container name within this app's scope. Never `pkill -f node`, never a host-wide sweep — sibling apps share this machine.

### Step 13: Cleanup — app-scoped

```bash
# Dangling layers only. Always safe: they are orphaned by rebuilds.
ssh "$VPS_HOST" "docker image prune -f"
ssh "$VPS_HOST" "docker builder prune -f --filter 'until=168h'"

# Tagged images: keep current AND rollback, matched by image ID
KEEP_IDS=$(ssh "$VPS_HOST" "docker inspect --format='{{.Image}}' $APP_CONTAINER; \
                            docker images -q $APP_IMAGE:rollback-previous")
# Remove only this app's images whose ID is not in KEEP_IDS.
```

**Never run** `docker system prune -a` or any `--volumes` prune. Volumes hold the database and uploads, and a host-wide prune reaches every sibling app on the box.
```

- [ ] **Step 7: Verify**

Run: `grep -cE 'pipeline-full-build[^-]|pipeline-review' skills/pipeline-full-build-cloud/SKILL.md`
Expected: `0` — no references to the deleted parent.

- [ ] **Step 8: Commit**

```bash
git add skills/pipeline-full-build-cloud/SKILL.md
git commit -m "feat(pipeline-full-build-cloud): standalone chain, VPS+compose primary, prod E2E"
```

---

### Task 5: Extend `pipeline-full-build-desktop`

**Files:**
- Modify: `skills/pipeline-full-build-desktop/SKILL.md`

**Interfaces:**
- Consumes: `/pipeline-quality` from Task 3; the shared spine content from Task 4's Step 3.
- Produces: a complete standalone chain invoked as `/pipeline-full-build-desktop`.

- [ ] **Step 1: Rewrite the frontmatter to describe a complete chain**

```yaml
---
name: pipeline-full-build-desktop
description: Complete standalone release chain for installable desktop apps - preflight, failsafe backup, the full quality gate, commit/merge/push, local compilation including native module rebuilds against the Electron ABI, code signing and notarization, packaged-binary E2E and launch smoke, GitHub release, staged update-feed publish with a clean-VM install smoke, documentation, worker purge and cleanup.
---
```

- [ ] **Step 2: Add the same preflight and shared spine as Task 4 Steps 2–3**

Copy the preflight block and the spine steps verbatim from Task 4. Omit the remote database dump — there is no VPS in this path.

- [ ] **Step 3: Add the security precondition that v3.18.0 skipped for desktop**

```markdown
**Security precondition.** Before shipping, state the quality gate's step 4 outcome explicitly — Semgrep, `/security-review`, and `security-guidance` readiness, each as PASS or NOT RUN. An unresolved High finding blocks the release outright. A `NOT RUN` does not block, but it must be named in the release record: shipping past an absent check is a decision someone should make on purpose rather than inherit from a quiet log. A desktop release cannot be recalled — once the update feed serves it, the only remedy is another release.
```

- [ ] **Step 4: Keep packaged-binary E2E in artifact validation, and say why**

```markdown
Desktop runs E2E **twice, against two different artifacts, deliberately**:

| Run | Artifact | Catches |
|-----|----------|---------|
| `/pipeline-quality` step 7 | Dev build | Logic regressions, fast and cheap |
| This step (10b) | Signed, packaged binary | Missing runtime deps, broken asar paths, native modules that load under Node but not under Electron |

Ordering makes this unavoidable: the quality gate runs before packaging exists, so it cannot test a binary that has not been built. The second run is not redundancy — the failures it catches appear nowhere else, and they appear only on a machine that is not the developer's.
```

- [ ] **Step 5: Add the ship step and a local-only worker purge**

Replace the update-feed section with a staged rollout plus a clean-VM install smoke. Worker purge is local only.

- [ ] **Step 6: Verify and commit**

```bash
grep -cE 'pipeline-full-build[^-]|pipeline-review' skills/pipeline-full-build-desktop/SKILL.md   # expect 0
git add skills/pipeline-full-build-desktop/SKILL.md
git commit -m "feat(pipeline-full-build-desktop): standalone chain, security precondition parity"
```

---

### Task 6: Rewire Call Sites

Must complete before Task 7 deletes anything, or the deletion breaks two live skills.

**Files:**
- Modify: `skills/pr-ready/SKILL.md:12-58` and `:141-168`
- Modify: `skills/feature-workflow/SKILL.md:41-55`
- Modify: `agents/03_Engineering_Division/Code_Excellence_Guild/Code_Reviewer.md:7`
- Modify: `agents/05_SecOps_and_Infrastructure_Division/DevOps_Engineer.md:7`

**Interfaces:**
- Consumes: `/pipeline-quality` from Task 3; `/pipeline-full-build-cloud` and `/pipeline-full-build-desktop` from Tasks 4–5.
- Produces: zero live references to the two deleted skills.

> **Correction to the spec:** §1a lists `qa-engineer` among the frontmatter sweeps. It is already clean — `QA_Engineer.md:7` is `skills: [pytest-patterns, semgrep-sast, pipeline-quality]`. Only two agent files need changes.

- [ ] **Step 1: Replace `pr-ready` Phase 1 with a delegation**

Replace the inlined lint / type-check / Semgrep / audit steps (lines 12–48) with:

```markdown
### Phase 1: Quality Gate

```
/pipeline-quality
```

Runs the entire gate — lint, type check, build, the three-part security gate, tests, the test case matrix, local E2E, dead code, dependency audit, the parallel review fan-out, and the zero-debt and no-regression gates.

**Do not inline these checks here.** A check added to `/pipeline-quality` must take effect everywhere it is used; a duplicated list silently stops running the new check while continuing to report a pass.
```

Delete Phase 1 Step 5's separate `/pipeline-review` call — it is now inside `/pipeline-quality`.

- [ ] **Step 2: Route `pr-ready` Phase 5 to the variant skills**

```markdown
### Phase 5: Release (Optional)

Only if the user requests a release. Do not hand-roll the version bump and tag here — route to the full chain, which carries the failsafe backup, the post-rebase gate re-run and the post-deploy verification that this phase previously lacked:

```
/pipeline-full-build-cloud      # or
/pipeline-full-build-desktop
```
```

- [ ] **Step 3: Retarget `feature-workflow` Phases 5–6**

Replace lines 41–55. The simplification and review passes now live inside `/pipeline-quality` steps 10–11:

```markdown
### Phase 5–6: Quality Gate, Simplification + Review

```
/pipeline-quality
```

Steps 10–11 are the reasoning passes: **simplification** (behavior-preserving — reuse, efficiency, altitude, naming; tests must still pass) and a **severity-rated review** delegated to the `code-reviewer` agent. Any 🔴 Critical or 🟠 High finding blocks the phase; the zero-debt gate at step 12 blocks on the rest unless a deferral is recorded in `PLAN.md`.

**OUTPUT**: Simplification changes applied + Quality Gate Report.
```

- [ ] **Step 4: Sweep the two agent frontmatter lines**

```bash
sed -i 's/^skills: \[semgrep-sast, pipeline-quality, pipeline-review\]$/skills: [semgrep-sast, pipeline-quality]/' \
  agents/03_Engineering_Division/Code_Excellence_Guild/Code_Reviewer.md
sed -i 's/^skills: \[github-actions, kubernetes-deployment, semgrep-sast, pipeline-quality, pipeline-full-build\]$/skills: [github-actions, kubernetes-deployment, semgrep-sast, pipeline-quality, pipeline-full-build-cloud, pipeline-full-build-desktop]/' \
  agents/05_SecOps_and_Infrastructure_Division/DevOps_Engineer.md
grep -rn '^skills: \[' agents/ | grep -i pipeline
```

- [ ] **Step 5: Verify and commit**

Run: `./scripts/verify-consolidation.sh 2>&1 | grep 'AC2\|AC3b'`
Expected: AC3b passes. AC2 still fails — the skill directories themselves exist until Task 7.

```bash
git add skills/pr-ready/SKILL.md skills/feature-workflow/SKILL.md agents/
git commit -m "refactor: retarget all call sites at the consolidated skills"
```

---

### Task 7: Delete the Consolidated Skills

**Files:**
- Delete: `skills/pipeline-full-build/`
- Delete: `skills/pipeline-review/`

**Interfaces:**
- Consumes: Tasks 3–6 complete (all content moved, all call sites rewired).
- Produces: 33 skill directories.

- [ ] **Step 1: Confirm nothing outside records still references them**

```bash
grep -rn 'pipeline-review\|pipeline-full-build[^-]' --include='*.md' --include='*.json' . \
  | grep -v node_modules | grep -v CHANGELOG.md | grep -v docs/superpowers/
```
Expected: only hits inside `skills/pipeline-full-build/` and `skills/pipeline-review/` themselves.

- [ ] **Step 2: Delete**

```bash
git rm -r skills/pipeline-full-build skills/pipeline-review
find skills -mindepth 1 -maxdepth 1 -type d | wc -l    # expect 33
```

- [ ] **Step 3: Verify**

Run: `./scripts/verify-consolidation.sh 2>&1 | grep 'AC1\|AC2'`
Expected: AC1 and AC2 both pass.

- [ ] **Step 4: Commit**

```bash
git commit -m "refactor!: remove pipeline-full-build and pipeline-review

Content redistributed: the shared release spine into both variant skills,
the simplify and review passes into pipeline-quality steps 10-11.

BREAKING CHANGE: /pipeline-full-build and /pipeline-review are no longer
invocable. Use /pipeline-full-build-cloud, /pipeline-full-build-desktop,
or /pipeline-quality."
```

---

### Task 8: Docs-Drift Sweep

**Files:**
- Modify: `CONTRIBUTING.md:406-413`
- Modify: `skills/security-audit/SKILL.md:417-421`
- Modify: `docs/rules/skills-integration.md:31,35`
- Modify: `docs/rules/orchestration.md`
- Modify: `SKILLS.md`

**Interfaces:**
- Consumes: Task 7's final skill list.
- Produces: every skill name in the docs resolves to a real directory or a documented external built-in.

- [ ] **Step 1: Fix the CONTRIBUTING category list — 11 of 18 names are phantom**

Replace lines 408–413 with names that exist:

```markdown
- **Framework Patterns**: `react-patterns`, `django-patterns`, `laravel-patterns`, `nextjs-patterns`, `vue-patterns`
- **Security**: `security-audit`, `semgrep-sast`, `silent-failure-audit`
- **DevOps**: `github-actions`, `kubernetes-deployment`, `terraform-patterns`
- **Pipelines**: `pipeline-quality`, `pipeline-full-build-cloud`, `pipeline-full-build-desktop`
- **Testing**: `pytest-patterns`
- **Language Patterns**: `python-patterns`, `typescript-patterns`, `go-patterns`, `java-patterns`
```

Removed because they do not exist: `owasp-checklist`, `penetration-testing`, `terraform-templates`, `pdf-tools`, `excel-automation`, `word-templates`, `playwright-patterns`, `test-strategies`, `microservices-patterns`, `event-driven-design`, `api-design`.

- [ ] **Step 2: Fix the `security-audit` dangling Level-3 links**

These are progressive-disclosure pointers an agent follows at runtime, so a broken one is a runtime dependency failure inside a security review — the review least likely to notice it degraded. The directory holds only `SKILL.md`.

```bash
ls skills/security-audit/        # confirm: SKILL.md only
```

Replace the "Additional Resources" block (lines 417–421) with references that resolve:

```markdown
## Additional Resources

- `/semgrep-sast` — automated SAST scanning via the Semgrep MCP plugin
- `/silent-failure-audit` — swallowed errors, hardcoded status, no-op handlers
- `/pipeline-quality` step 4 — the three-part security gate this skill feeds
```

- [ ] **Step 3: Reconcile `skills-integration.md` with actual agent frontmatter, both directions**

```bash
# Print each agent's declared skills, then fix the rules file to match
grep -rn '^skills: \[' agents/ | sed 's|agents/.*/||'
```

Line 31 becomes `code-reviewer` → `semgrep-sast, pipeline-quality`. Line 35 drops `owasp-checklist` from `cyber-sentinel`. Update the `devops-engineer` row to name both variant skills.

- [ ] **Step 4: Update `SKILLS.md` and `docs/rules/orchestration.md`**

Remove the `pipeline-full-build` and `pipeline-review` entries; describe the three-skill family.

- [ ] **Step 5: Verify and commit**

Run: `./scripts/verify-consolidation.sh 2>&1 | grep 'AC3'`
Expected: AC3 and AC3b both pass.

```bash
git add CONTRIBUTING.md skills/security-audit/SKILL.md docs/rules/ SKILLS.md
git commit -m "docs: remove phantom skill references and dangling level-3 links"
```

---

### Task 9: Version Bump, CHANGELOG, Final Verification

**Files:**
- Modify: `.claude-plugin/plugin.json:4` and its description
- Modify: `README.md:13,16,682`
- Modify: `CLAUDE.md:52,60,62,142`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: every prior task.
- Produces: a repository where `./scripts/verify-consolidation.sh` exits 0.

- [ ] **Step 1: Confirm the version check currently fails**

Run: `./scripts/check-version-consistency.sh`
Expected: FAIL on the README badge, footer, and the skill counts.

- [ ] **Step 2: Bump to 4.0.0 and reconcile every count**

```bash
sed -i 's/"version": "3.18.0"/"version": "4.0.0"/' .claude-plugin/plugin.json
sed -i 's/35 skills/33 skills/g'                   .claude-plugin/plugin.json
sed -i 's|badge/version-3\.13\.0|badge/version-4.0.0|' README.md
sed -i 's|badge/skills-32|badge/skills-33|'           README.md
sed -i 's/Nation of Elites v3\.14\.0/Nation of Elites v4.0.0/' README.md
sed -i 's/\*\*35 custom skills\*\*/**33 custom skills**/g' README.md CLAUDE.md
# CLAUDE.md's Cowork table already says 33 — the script confirms it rather than assuming
./scripts/check-version-consistency.sh
```

Iterate on the `sed` list until the script passes — it names every disagreement it finds, so it is the worklist.

- [ ] **Step 3: Update `CLAUDE.md`'s Skills System section**

Rewrite lines 60–62 to describe three skills rather than five: `pipeline-quality` as the complete pre-merge gate including the reasoning passes, and the two variants as complete standalone release chains. Note that VPS + `docker compose` is the cloud variant's primary deploy path.

- [ ] **Step 4: Write the CHANGELOG entry**

```markdown
## v4.0.0 - 2026-08-18

### Removed (BREAKING)
- `pipeline-full-build` and `pipeline-review` are no longer invocable. Content redistributed:
  the release spine into both variant skills, the simplify and review passes into
  `pipeline-quality` steps 10–11.

### Changed
- `pipeline-quality` is now the complete pre-merge pipeline: 15 steps across deterministic
  gates (1–9), a reasoning fan-out (10–11) and consuming gates (12–14).
- `pipeline-full-build-cloud` is a standalone chain with **VPS + docker compose over SSH** as
  the primary deploy path; Kubernetes is a documented secondary branch.
- `pr-ready` and `feature-workflow` delegate to `/pipeline-quality` instead of inlining checks.

### Added
- Local Playwright E2E (quality step 7) and production critical-path E2E with temporary
  accounts (cloud step 9), with mandatory teardown and an orphan sweep.
- Zero-debt and no-regression gates; named deferrals must be recorded in `PLAN.md`.
- Worker purge and app-scoped cleanup — the VPS is multi-app, so host-wide prunes are forbidden.
- `scripts/check-version-consistency.sh`, wired into quality step 0.

### Fixed
- **Silent gate failure:** `code-reviewer` emitted Critical/Major/Minor while the gate blocked on
  Critical/High. Major findings — semantically High — passed a gate that should have stopped them.
  One four-level scale now applies everywhere.
- 11 phantom skill names in `CONTRIBUTING.md`; three dangling level-3 resource links in
  `security-audit`; `owasp-checklist` references; skill-count and version drift across five files.
```

- [ ] **Step 5: Run the full acceptance suite**

```bash
git add -A && git commit -m "release: v4.0.0 — pipeline consolidation"
./scripts/verify-consolidation.sh
```
Expected: `CONSOLIDATION: PASS`, all criteria `ok`.

- [ ] **Step 6: Confirm the tree state the user asked for**

```bash
git status --porcelain     # expect empty
git fetch origin && git rev-list --count HEAD..origin/main   # expect 0
```

---

## Self-Review

**Spec coverage:** §1 → Tasks 3–7. §1a → Task 6. §2 → Task 3. §2b → Tasks 1, 3, 9. §3 → Task 4. §4 → Task 5. §5 → Tasks 7, 9. §6 → Tasks 8, 9. §7 → Task 2. §8 files-to-modify → Tasks 2–9. §9 files-to-delete → Task 7. §10 out-of-scope → honoured; no task touches clearpath or resumeflex. All seven acceptance criteria are encoded in `scripts/verify-consolidation.sh` and run in Task 9.

**Known deviation from the spec:** §1a lists `qa-engineer` among the frontmatter sweeps; it is already clean, so Task 6 changes two agent files rather than three. Recorded inline in Task 6.
