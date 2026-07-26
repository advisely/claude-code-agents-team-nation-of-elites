---
name: pipeline-full-build
description: Universal end-to-end release pipeline - failsafe backup, quality gate, simplify/review/commit, merge, push, build, package, release, deploy to prod, doc updates, and junk/dangling-image reclamation. Desktop and cloud variants.
---

# Pipeline Full Build

End-to-end release pipeline from failsafe backup through production deploy and cleanup. Every destructive action is preceded by a verified backup, and every gate must pass before the next phase begins.

## When to Use This Skill

- Preparing a release build
- Running the full CI/CD pipeline locally
- Before tagging a version or creating a GitHub release
- After completing a milestone or sprint
- Shipping to production, including the post-deploy documentation and cleanup work

## Target Agents

- `devops-engineer` - Primary pipeline operator
- `chief-operations-orchestrator` - Release coordination
- `code-reviewer` - Pre-release quality gate and review pass
- `cyber-sentinel` - Pre-release security scan
- `qa-engineer` - Test case matrix and post-deploy verification
- `sre-specialist` - Production deploy and rollback gate
- `documentation-specialist` - Project and Claude doc updates

## Pipeline Overview

Seven phases, seventeen steps. The phase order is the safety contract: **nothing is deleted before it is backed up, nothing ships before it is verified, and nothing is reclaimed before the release is confirmed healthy.**

```
Phase 0 — SAFEGUARD
  Step 0:  Failsafe Backup & Retention Proof

Phase 1 — VERIFY
  Step 1:  Quality Gate            → /pipeline-quality (incl. happy/non-happy/edge matrix)
  Step 2:  Code Simplify           → /pipeline-review Pass 1
  Step 3:  Code Review             → /pipeline-review Pass 2 (severity-rated)

Phase 2 — INTEGRATE
  Step 4:  Version Bump
  Step 5:  Commit                  → /pipeline-review Pass 3
  Step 6:  Merge to main
  Step 7:  Push to GitHub

Phase 3 — BUILD
  Step 8:  Build
  Step 9:  Compile / Package  (desktop)  |  Docker Build (cloud)
  Step 10: CI Validation

Phase 4 — SHIP
  Step 11: Release Version (tag + GitHub release)
  Step 12: Deploy to Production
  Step 13: Post-Deploy Verification & Rollback Gate

Phase 5 — DOCUMENT
  Step 14: Update Project Documents (.md)
  Step 15: Update & Optimize Claude Docs (.md)

Phase 6 — RECLAIM
  Step 16: Cleanup — local + VPS junk, dangling images (backup retention enforced)
```

**Ordering rationale.** Backup (Step 0) precedes everything because Steps 12 and 16 are the two irreversible actions. Verify precedes Integrate so nothing blocking enters history. Merge/push precede Build so CI validates exactly what was pushed. Docs precede Reclaim so the record is written while the release context is still live. Reclaim is last and is gated on Step 0's backup still existing.

## Versioning Scheme

This project uses **Calendar Versioning (CalVer)**: `vYYYY.MM.DD`

- Version is the release date: `v2026.04.04`
- Multiple releases on the same day: append a suffix: `v2026.04.04.2`
- `package.json` version field stores: `2026.04.04`
- Git tags use: `v2026.04.04`

---

# Phase 0 — SAFEGUARD

## Step 0: Failsafe Backup & Retention Proof

Runs first, always, on both variants. **The pipeline must not proceed if this step cannot prove a restorable copy exists.**

```bash
set -euo pipefail
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.backups/$(basename "$PWD")}"
mkdir -p "$BACKUP_ROOT"

# 1. Code: the git bundle is a complete, restorable repo in one file
git bundle create "$BACKUP_ROOT/repo-$STAMP.bundle" --all
git bundle verify "$BACKUP_ROOT/repo-$STAMP.bundle"   # must exit 0

# 2. Untracked-but-needed local state (env files, local config) — never committed
tar -czf "$BACKUP_ROOT/local-state-$STAMP.tar.gz" \
  $(git ls-files --others --exclude-standard | grep -E '\.env|config/local' || true) 2>/dev/null || true

# 3. Production database, before any deploy touches it
# pg_dump  "$DATABASE_URL" | gzip > "$BACKUP_ROOT/db-$STAMP.sql.gz"
# mysqldump --single-transaction "$DB" | gzip > "$BACKUP_ROOT/db-$STAMP.sql.gz"

# 4. Currently-deployed artifact, so rollback has a target
# docker image save "app:$(cat .last-deployed-version)" | gzip > "$BACKUP_ROOT/image-rollback-$STAMP.tar.gz"
```

**Retention rule — the failsafe invariant:**

> At least **one** verified backup must exist at all times. Cleanup (Step 16) prunes *older* backups only, and only after confirming a newer verified one is present. If exactly one backup exists, it is never deleted, regardless of age.

```bash
# Prove the invariant before continuing
BACKUP_COUNT=$(find "$BACKUP_ROOT" -name 'repo-*.bundle' | wc -l)
[ "$BACKUP_COUNT" -ge 1 ] || { echo "ABORT: no verified backup present"; exit 1; }
echo "Failsafe OK: $BACKUP_COUNT backup(s), newest repo-$STAMP.bundle (verified)"
```

**Gate rule:** a failed `git bundle verify`, an unwritable `$BACKUP_ROOT`, or a zero-byte dump **halts the pipeline**. Never proceed to Phase 4 or 6 on an unverified backup.

**Restore drill** (know this works *before* you need it):

```bash
git clone "$BACKUP_ROOT/repo-$STAMP.bundle" /tmp/restore-check && rm -rf /tmp/restore-check
```

---

# Phase 1 — VERIFY

## Step 1: Quality Gate

```
/pipeline-quality
```

Runs stack detection, lint, type check, Semgrep SAST, tests, the **happy / non-happy / edge case coverage matrix**, dead code detection, and dependency audit.

**Gate rule:** all checks must pass. Any Semgrep ERROR-severity finding, or any changed behavior lacking a non-happy-path or edge case test, blocks the pipeline. Cheap and fails fast — this is why it precedes the reasoning passes.

## Step 2: Code Simplify

```
/pipeline-review          # Pass 1
```

Behavior-preserving cleanup across five lenses: reuse, simplification, efficiency, altitude, naming. Minimal edits only — no reformatting untouched code, no renames for taste, no public API changes.

**Gate rule:** the test suite must still pass after simplification. A simplification that changes behavior is a defect, not a cleanup.

## Step 3: Code Review

```
/pipeline-review          # Pass 2
```

Delegated to the **`code-reviewer`** agent, which routes deep findings to `cyber-sentinel` and `performance-optimizer`. Six dimensions: correctness, security, error handling, performance, maintainability, test adequacy.

**Gate rule:** any 🔴 Critical or 🟠 High finding fails the phase. 🟡 Medium and 🟢 Low are recorded as follow-ups and do not block.

---

# Phase 2 — INTEGRATE

## Step 4: Version Bump

```bash
current=$(node -p "require('./package.json').version" 2>/dev/null || echo "0.0.0")
new=$(date +%Y.%m.%d)

# Same-day re-release: append a suffix rather than overwriting a shipped tag
git rev-parse "v$new" >/dev/null 2>&1 && new="$new.$(( $(git tag -l "v$(date +%Y.%m.%d)*" | wc -l) + 1 ))"
echo "Version: $current -> $new"

npm version "$new" --no-git-tag-version --allow-same-version
[ -f "pyproject.toml" ] && sed -i "s/^version = \".*\"/version = \"$new\"/" pyproject.toml
[ -f "Cargo.toml" ]     && sed -i "s/^version = \".*\"/version = \"$new\"/" Cargo.toml
```

## Step 5: Commit

```
/pipeline-review          # Pass 3
```

Conventional Commits format, deliberate staging, secret scan on the staged set, and a hard rule against committing directly to the default branch.

```bash
git add package.json pyproject.toml Cargo.toml 2>/dev/null || true
git commit -m "release: v$new"
```

**Gate rule:** never commit over unresolved 🔴/🟠 findings from Step 3.

## Step 6: Merge to main

```bash
BRANCH=$(git branch --show-current)
git fetch origin --prune

# Rebase onto the latest main first so the merge is a fast-forward and CI
# validates the code as it will actually exist on main
git rebase origin/main || { echo "ABORT: resolve rebase conflicts, then re-run"; exit 1; }

# Re-run the gate after rebasing — a clean merge can still be a broken build
/pipeline-quality || { echo "ABORT: gate failed post-rebase"; exit 1; }

git checkout main
git merge --no-ff "$BRANCH" -m "merge: $BRANCH into main (v$new)"
```

**Gate rule:** re-run the quality gate **after** the rebase. Semantic conflicts — two independently-correct changes that break when combined — pass `git merge` and fail the build. This is the most commonly skipped gate in the chain.

Prefer a PR-based merge where branch protection is configured:

```bash
gh pr create --fill --base main
gh pr checks --watch                      # wait for CI to go green
gh pr merge --merge --delete-branch
```

## Step 7: Push to GitHub

```bash
git push origin main
git push origin --tags 2>/dev/null || true

# Confirm the remote actually has what we think it has
git fetch origin
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] \
  || { echo "ABORT: local and origin/main diverged after push"; exit 1; }
```

**Gate rule:** verify the push landed. A rejected non-fast-forward push that scrolls past in the log is how a "released" version ends up never leaving the laptop.

---

# Phase 3 — BUILD

## Step 8: Build

### Desktop Variant (Electron + Python)

```bash
npx tsc                                    # TypeScript compilation
npm run build                              # Electron main + renderer
# Or: npx electron-vite build
[ -f "pyproject.toml" ] && python -m build # Python backend (if hybrid)
```

### Cloud Variant (Web/API)

```bash
npm run build || npx vite build            # Frontend
[ -f "pyproject.toml" ] && python -m build
[ -f "go.mod" ]        && go build ./...
[ -f "Cargo.toml" ]    && cargo build --release
```

## Step 9: Compile / Package (desktop) | Docker Build (cloud)

### Desktop Variant

```bash
# Bundle
npx electron-builder --config electron-builder.yml

# Platform-specific packaging
npx electron-builder --win   --config electron-builder.yml   # NSIS installer
npx electron-builder --mac   --config electron-builder.yml   # DMG
npx electron-builder --linux --config electron-builder.yml   # AppImage/deb

ls -la dist/
```

### Cloud Variant

```bash
docker build -t "app:$new" .
docker images "app:$new" --format "{{.Size}}"

# Security-scan the image before it can reach a registry
docker scout cves "app:$new" || trivy image --exit-code 1 --severity HIGH,CRITICAL "app:$new"
```

**Gate rule (cloud):** a HIGH or CRITICAL CVE in the built image blocks the release. Scanning after deploy is not a gate, it is a notification.

## Step 10: CI Validation

### Desktop Variant

```bash
ls dist/*.exe      >/dev/null 2>&1 && echo "Windows package: OK"
ls dist/*.dmg      >/dev/null 2>&1 && echo "macOS package: OK"
ls dist/*.AppImage >/dev/null 2>&1 && echo "Linux package: OK"

# Checksums travel with the release so users can verify downloads
( cd dist && sha256sum * > SHA256SUMS )
```

### Cloud Variant

```bash
gh run watch "$(gh run list --branch main --limit 1 --json databaseId -q '.[0].databaseId')" --exit-status
curl -f http://localhost:8080/health || exit 1
npm run test:smoke || pytest tests/smoke/
```

---

# Phase 4 — SHIP

## Step 11: Release Version

```bash
git tag -a "v$new" -m "Release v$new"
git push origin "v$new"

# Desktop: attach artifacts + checksums
gh release create "v$new" \
  --title "v$new" \
  --notes "$(sed -n "/## v$new/,/^## /p" CHANGELOG.md 2>/dev/null || echo 'See CHANGELOG.md')" \
  dist/* 2>/dev/null

# Cloud: let GitHub generate notes from merged PRs
gh release create "v$new" --title "v$new" --generate-notes
```

**Gate rule:** tag only a commit that is already on `origin/main` and green in CI. Tagging local work produces a release nobody else can reproduce.

## Step 12: Deploy to Production

The first irreversible step. Step 0's backup is its safety net — confirm it before proceeding.

```bash
# Refuse to deploy without a verified backup
[ -f "$BACKUP_ROOT/repo-$STAMP.bundle" ] || { echo "ABORT: no failsafe backup"; exit 1; }

# Record what is currently live, so rollback has an exact target
echo "$(cat .last-deployed-version 2>/dev/null || echo none)" > .previous-deployed-version
```

### Cloud Variant

```bash
docker tag  "app:$new" "registry.example.com/app:$new"
docker push "registry.example.com/app:$new"

# Kubernetes — rolling deploy, wait for it, roll back automatically on failure
if [ -d "k8s/" ]; then
  kubectl set image deployment/app "app=registry.example.com/app:$new"
  kubectl rollout status deployment/app --timeout=5m \
    || { kubectl rollout undo deployment/app; echo "ROLLED BACK"; exit 1; }
fi

# Terraform — plan is reviewed, never blind-applied
if [ -d "terraform/" ]; then
  ( cd terraform && terraform plan -out=tfplan && terraform apply tfplan )
fi

# VPS / systemd
# ssh "$VPS" "cd /srv/app && docker compose pull && docker compose up -d --remove-orphans"

echo "$new" > .last-deployed-version
```

### Desktop Variant

"Production" is the distribution channel: publish the release, push the auto-update feed, and stage the store submissions.

```bash
npx electron-builder --publish always
# Verify the update feed actually serves the new version
curl -fsSL "https://updates.example.com/latest.yml" | grep -q "$new" \
  || echo "WARNING: update feed has not picked up v$new yet"
```

**Gate rule:** deploy behind a rollout that can be reversed by a single command (`kubectl rollout undo`, previous image tag, prior release channel). If rollback requires a rebuild, the deploy is not production-ready.

## Step 13: Post-Deploy Verification & Rollback Gate

```bash
# Health and version — confirm the thing that is live is the thing you shipped
curl -f  "https://app.example.com/health"
curl -fs "https://app.example.com/version" | grep -q "$new" \
  || { echo "ABORT: live version is not $new"; exit 1; }

# Production smoke tests: happy path AND the critical non-happy paths
npm run test:smoke:prod || pytest tests/smoke/ --base-url=https://app.example.com

# Watch error rate against the pre-deploy baseline before declaring success
# (Sentry / Datadog / CloudWatch — 5-15 min soak)
```

**Gate rule:** if health checks fail, the version endpoint disagrees, or the error rate exceeds the pre-deploy baseline, **roll back immediately** and stop the pipeline. Phases 5 and 6 do not run on a failed deploy — in particular, Step 16 must never delete images the rollback still needs.

---

# Phase 5 — DOCUMENT

## Step 14: Update Project Documents (.md)

Written while the release context is fresh, and before anything is cleaned up.

| Document | Update |
|----------|--------|
| `CHANGELOG.md` | New `## v$new — YYYY-MM-DD` section: Added / Changed / Fixed / Removed / Security |
| `README.md` | Version badge, install commands, any changed prerequisites or screenshots |
| `docs/**/*.md` | Behavior that changed this release; delete instructions for removed features |
| `API.md` / `openapi.yaml` | New, changed, or deprecated endpoints and fields |
| `MIGRATION.md` | Required steps for breaking changes — write this even when you think nobody hit them |
| `PLAN.md` | Tick off shipped items; carry the 🟡/🟢 review follow-ups forward |

```bash
{ echo "## v$new - $(date +%Y-%m-%d)"; echo; git log "v$current..v$new" --pretty='- %s' --no-merges; echo; cat CHANGELOG.md; } > CHANGELOG.tmp && mv CHANGELOG.tmp CHANGELOG.md

# Docs that reference a version must not be left stale
grep -rn "$current" --include='*.md' . | grep -v CHANGELOG.md
```

**Gate rule:** no doc may describe behavior this release removed. A stale doc is a support ticket with a delay fuse.

## Step 15: Update & Optimize Claude Docs (.md)

The agent-facing memory layer. Distinct from Step 14: those docs are for humans, these steer every future agent run.

| File | Update | Optimize for |
|------|--------|-------------|
| `CLAUDE.md` | Identity, rule index, version-specific notes | **Brevity** — loaded every session; every token is rent |
| `docs/rules/*.md` | Domain canon changed by this release | Load-on-demand, so depth is fine here — move detail *out* of `CLAUDE.md` and *into* these |
| `.claude/agents/*.md` | Frontmatter (`model`, `skills`, `maxTurns`), capability text | Accuracy — a stale agent description causes silent misrouting |
| `skills/*/SKILL.md` | Steps changed by this release | Progressive disclosure: name + description do the routing, body carries the detail |
| `.claude/settings.json` | Hooks, permissions, env | Least privilege |

**Optimization pass** — not just "is it current" but "is it earning its place":

1. **Deduplicate** — the same fact in `CLAUDE.md` and a rule file will drift apart. Keep one copy, link to it.
2. **Demote** — detail that only matters in one domain moves out of always-loaded `CLAUDE.md` into an on-demand rule file.
3. **Prune** — delete guidance for removed features, superseded model versions, and retired agents.
4. **Sharpen descriptions** — skill and agent `description:` fields are the routing signal. Vague descriptions cause wrong-agent selection far more often than weak bodies do.
5. **Verify references** — every file path, agent name, and skill name mentioned must still exist.

```bash
# Broken cross-references in the memory layer
grep -rhoE '\]\(([^)]+\.md)\)' CLAUDE.md docs/rules/*.md | sed -E 's/.*\((.*)\)/\1/' \
  | while read -r f; do [ -e "$f" ] || echo "BROKEN LINK: $f"; done

# Agent/skill names referenced but not present
grep -rhoE '`[a-z0-9-]+`' CLAUDE.md | tr -d '`' | sort -u \
  | while read -r n; do
      grep -rqs "^name: $n" agents/ skills/ || true
    done

# Always-loaded budget: CLAUDE.md should stay lean
wc -w CLAUDE.md
```

**Gate rule:** every agent, skill, and file path named in `CLAUDE.md` or `docs/rules/*.md` must resolve. A broken reference in the memory layer degrades every subsequent agent run, silently.

---

# Phase 6 — RECLAIM

## Step 16: Cleanup — local + VPS junk, dangling images

Last, and **only** after Step 13 confirmed the deploy is healthy. Everything here is scoped, and the failsafe invariant is re-proved before a single deletion.

```bash
# ── Precondition: the failsafe must still hold ───────────────────────────────
BACKUPS=$(find "$BACKUP_ROOT" -name 'repo-*.bundle' | wc -l)
[ "$BACKUPS" -ge 1 ] || { echo "ABORT: cleanup would leave zero backups"; exit 1; }
git bundle verify "$(ls -t "$BACKUP_ROOT"/repo-*.bundle | head -1)" >/dev/null \
  || { echo "ABORT: newest backup fails verification"; exit 1; }
```

### Local cleanup

```bash
# Build output and caches — regenerable, safe to drop
rm -rf dist/ build/ .next/ .turbo/ .vite/ coverage/ .pytest_cache/ .mypy_cache/ .ruff_cache/
find . -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
find . -type f -name '*.pyc' -delete

# Git housekeeping (never --prune=now: it drops the reflog safety net)
git gc --auto
git remote prune origin
git branch --merged main | grep -vE '^\*|main|master|develop' | xargs -r git branch -d

# Package manager caches
npm cache verify
pip cache purge 2>/dev/null || true
```

### Docker: dangling images and unused resources

```bash
# Dangling images = untagged layers orphaned by rebuilds. Always safe.
docker image prune -f

# Stopped containers, unused networks, build cache older than the release
docker container prune -f
docker network   prune -f
docker builder   prune -f --filter 'until=168h'

# Tagged images: keep the current release AND the rollback target
KEEP_CURRENT=$(cat .last-deployed-version)
KEEP_PREV=$(cat .previous-deployed-version 2>/dev/null || echo "")
docker images 'app' --format '{{.Tag}}' \
  | grep -vE "^(${KEEP_CURRENT}|${KEEP_PREV:-__none__}|latest)$" \
  | while read -r tag; do echo "removing app:$tag"; docker rmi "app:$tag" || true; done

# Volumes are DATA. Never blanket-prune them.
docker volume ls -qf dangling=true    # review this list by hand before removing anything
```

**Never run** `docker system prune -a --volumes` in this pipeline. It removes the rollback image and every unreferenced volume — the two things Step 13 may still need.

### VPS cleanup

```bash
ssh "$VPS" bash -s <<'REMOTE'
set -euo pipefail

# Same rule remotely: dangling only, keep current + previous release
docker image prune -f
docker container prune -f
docker builder prune -f --filter 'until=168h'

# Rotate logs rather than deleting them
journalctl --vacuum-time=14d
find /var/log -name '*.gz' -mtime +30 -delete
find /var/log -name '*.log.[0-9]*' -mtime +30 -delete

# Release directories: keep the newest 3 deployments
ls -1dt /srv/app/releases/* 2>/dev/null | tail -n +4 | xargs -r rm -rf

# Package manager cache
apt-get clean 2>/dev/null || true

df -h /
REMOTE
```

### Backup retention — the failsafe rule

```bash
# Keep the 5 newest verified backups. If fewer than 2 exist, delete nothing.
cd "$BACKUP_ROOT"
TOTAL=$(ls -1 repo-*.bundle 2>/dev/null | wc -l)
if [ "$TOTAL" -gt 5 ]; then
  ls -t repo-*.bundle | tail -n +6 | while read -r old; do
    # Re-check the invariant before each individual deletion
    [ "$(ls -1 repo-*.bundle | wc -l)" -gt 1 ] && rm -f "$old" && echo "pruned $old"
  done
else
  echo "Retention: $TOTAL backup(s) — below threshold, nothing pruned"
fi

# Final assertion: at least one verified copy survives
[ "$(ls -1 repo-*.bundle | wc -l)" -ge 1 ] || { echo "FAILSAFE VIOLATED"; exit 1; }
```

**Gate rule:** cleanup is scoped and reversible-by-design. It deletes only regenerable artifacts (build output, caches, dangling layers), rotated logs, and *surplus* backups. It never touches the current release, the rollback target, Docker volumes, or the last remaining backup.

---

## Output Format

```markdown
## Full Build Report - v[version]

| Phase | Step | Status | Duration | Details |
|-------|------|--------|----------|---------|
| 0 Safeguard | Failsafe Backup | DONE | 8s | repo-20260726.bundle verified, 3 backups retained |
| 1 Verify | Quality Gate | PASS | 45s | 8 checks; test matrix 12/12 behaviors covered |
| 1 Verify | Code Simplify | PASS | 20s | 4 simplifications, tests still green |
| 1 Verify | Code Review | PASS | 60s | 0 blocking, 3 medium, 2 low |
| 2 Integrate | Version Bump | DONE | 2s | v2026.07.25 -> v2026.07.26 |
| 2 Integrate | Commit | DONE | 3s | abc1234 release: v2026.07.26 |
| 2 Integrate | Merge to main | PASS | 30s | --no-ff; gate re-run post-rebase |
| 2 Integrate | Push to GitHub | DONE | 5s | origin/main == HEAD verified |
| 3 Build | Build | PASS | 30s | TypeScript + Vite compiled |
| 3 Build | Package / Docker | PASS | 120s | NSIS 85MB; image scan 0 HIGH/CRITICAL |
| 3 Build | CI Validation | PASS | 15s | SHA256SUMS written; CI green |
| 4 Ship | Release Version | DONE | 10s | GitHub release v2026.07.26 |
| 4 Ship | Deploy to Prod | DONE | 90s | rollout complete; rollback target app:2026.07.25 |
| 4 Ship | Post-Deploy Verify | PASS | 300s | health OK, version match, error rate nominal |
| 5 Document | Project Docs | DONE | 25s | CHANGELOG, README, API.md updated |
| 5 Document | Claude Docs | DONE | 30s | CLAUDE.md -180 words; 0 broken refs |
| 6 Reclaim | Cleanup | DONE | 40s | 6 dangling images, 2.1GB reclaimed; 3 backups kept |

### Artifacts
- `dist/app-2026.07.26-setup.exe` (85MB)
- GitHub Release: https://github.com/owner/repo/releases/tag/v2026.07.26

### Failsafe Status
- Backups retained: 3 (newest verified)
- Rollback target: `app:2026.07.25` (present locally and in registry)

### Follow-ups (non-blocking)
- 🟡 N+1 on roles — db/users.ts:30

### Total Pipeline Duration: 14m 03s
```

## CI/CD Template (GitHub Actions)

```yaml
name: Full Build
on:
  push:
    tags: ['v*']

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Failsafe Backup
        run: git bundle create /tmp/repo.bundle --all && git bundle verify /tmp/repo.bundle
      - name: Quality Gate
        run: |  # Lint + types + Semgrep + tests + test matrix + dead code + audit

  build:
    needs: verify
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: npm run build
      - name: Package
        run: npx electron-builder
      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: dist-${{ matrix.os }}
          path: dist/

  release:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          files: dist/*

  deploy:
    needs: release
    environment: production        # requires manual approval
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: |  # kubectl set image / docker compose up -d
      - name: Post-Deploy Verify
        run: |  # health + version + smoke; roll back on failure

  reclaim:
    needs: deploy
    if: success()                  # never clean up after a failed deploy
    runs-on: ubuntu-latest
    steps:
      - name: Prune dangling images
        run: docker image prune -f
```

## Relationship to Other Skills

| Skill | Role in this pipeline |
|-------|----------------------|
| `/pipeline-quality` | Step 1 — the deterministic gate, including the test case matrix |
| `/pipeline-review` | Steps 2, 3, 5 — simplify, review, commit |
| `/feature-workflow` | Upstream: produces the branch this pipeline releases |
| `/pr-ready` | Lighter alternative when merging a PR without a release |
