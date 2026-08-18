---
name: pipeline-full-build-cloud
description: Complete standalone release chain for web/API apps deployed to a VPS or container platform - preflight, failsafe backup including a remote database dump, the full quality gate, commit/merge/push, container or compose build, GitHub release, deploy over SSH with an image-ID rollback target, production Playwright smoke with temporary accounts, post-deploy verification, documentation, worker purge and app-scoped cleanup.
---

# Pipeline Full Build — Cloud

A complete, standalone release chain for web/API apps and background services deployed to infrastructure you operate — a VPS running `docker compose` over SSH, or (as a documented secondary path) a Kubernetes cluster. This skill references no parent skill: it runs preflight through cleanup on its own, Steps 0–13.

**Primary deploy target: a VPS reached over SSH, running `docker compose`.** That is the operator's real environment — not a cluster. Kubernetes is supported as a secondary branch inside Step 8, but every default command in this skill assumes compose-over-SSH. Every destructive or resource-claiming command in this skill is scoped to *this app*; host-wide commands (`docker system prune -a`, any `--volumes` prune, `pkill -f node`) are forbidden throughout, because the target box is shared with other applications' containers, volumes, and nginx config.

## When to Use This Skill

- Releasing a web app, API, or background service to a container platform
- Any build whose output is an image deployed to infrastructure you operate
- Shipping to a shared multi-app VPS via `docker compose`, or a Kubernetes cluster as the secondary path
- Serverless and PaaS targets (adapt Step 8's deploy mechanics; the rest applies unchanged)

## Target Agents

- `devops-engineer` — Primary pipeline operator
- `sre-specialist` — Deploy, rollback gate, post-deploy verification
- `cloud-architect` — Infrastructure changes
- `cyber-sentinel` — Image CVE gate and SBOM review
- `qa-engineer` — Staging and production E2E validation
- `documentation-specialist` — Project and Claude doc updates

## Configuration

These environment variables are assumed throughout. Set them per app before running the chain — never hardcode one app's values into a shared skill.

| Var | Meaning | Example |
|-----|---------|---------|
| `VPS_HOST` | SSH target for the production box | `deploy@72.60.115.212` |
| `REMOTE_APP_DIR` | This app's directory on the VPS | `/srv/clearpath` |
| `COMPOSE_FILE` | Compose file for this app | `docker-compose.prod.yml` |
| `APP_CONTAINER` | Running container name for this app | `clearpath-api` |
| `APP_IMAGE` | Image repo:tag base for this app | `registry.example.com/clearpath` |
| `APP_PREFIX` | Container-name prefix that scopes this app on a shared box | `clearpath-` |
| `COMPOSE_PROJECT` | Compose project name; scopes the Step 13 image prune by label. Defaults to `basename $REMOTE_APP_DIR` | `clearpath` |
| `APP_VERSION` | **Lives in `$REMOTE_APP_DIR/.env` on the VPS, not in your shell.** The compose file must resolve `image: ${APP_IMAGE}:${APP_VERSION}`; deploy rewrites it forward, rollback rewrites it back. This is what makes the rollback real | `2026.07.26` |
| `DB_CONTAINER`, `DB_USER`, `DB_NAME` | Postgres container and credentials for the remote dump | `clearpath-db`, `clearpath`, `clearpath_prod` |
| `DOMAIN` | Public hostname for health checks and production E2E | `app.example.com` |
| `STAGING_HOST` | SSH target for the staging box (Step 7d); may equal `VPS_HOST` | `deploy@72.60.115.213` |
| `STAGING_COMPOSE_FILE` | Compose file for the staging stack | `docker-compose.staging.yml` |
| `STAGING_DB` | Local database Step 7d restores the production dump into | `staging_db` |
| `E2E_ADMIN_TOKEN` | Teardown credential for production E2E accounts; absent → that step records `NOT RUN` | — |

**Why this table exists.** A real Hostinger VPS running this pattern hosts several unrelated apps behind one nginx — clearpath, resumeflex, and others each get their own `APP_CONTAINER`/`APP_PREFIX`/`REMOTE_APP_DIR`. Every scoped command below depends on these being set correctly for *this* app; an unset or wrong `APP_PREFIX` is how a cleanup step reaches into a neighbor.

## Stack Detection

```bash
[ -f "docker-compose.yml" ] || [ -f "docker-compose.prod.yml" ] && echo "CLOUD (compose — primary path)"
[ -f "Dockerfile" ]                                             && echo "CLOUD (container)"
[ -d "k8s/" ] || [ -f "helm/Chart.yaml" ]                        && echo "CLOUD (Kubernetes — secondary path)"
[ -d "terraform/" ]                                              && echo "CLOUD (Terraform-managed infra)"
[ -f "vercel.json" ] || [ -f "fly.toml" ] || [ -f "render.yaml" ] && echo "CLOUD (PaaS)"
```

## Pipeline Overview

Seven phases, fourteen steps (0–13). Same safety contract as any release chain: nothing is deleted before it is backed up, nothing ships before it is verified, and nothing is reclaimed before the release is confirmed healthy.

```
Phase 0 — SAFEGUARD
  Step 0:  Preflight
  Step 1:  Failsafe Backup & Retention Proof (+ remote database dump)

Phase 1 — VERIFY
  Step 2:  Quality Gate            → /pipeline-quality (Steps 0–14; simplify + review included)

Phase 2 — INTEGRATE
  Step 3:  Version Bump
  Step 4:  Commit
  Step 5:  Merge to main (post-rebase gate re-run)
  Step 6:  Push to GitHub

Phase 3 — BUILD & RELEASE
  Step 7:  Build, Container Image, SBOM/CVE Gate, Staging Validation, Release Version

Phase 4 — SHIP
  Step 8:  Deploy to Production (VPS + docker compose; Kubernetes secondary)
  Step 9:  Production E2E (critical path only)
  Step 10: Post-Deploy Verification & Rollback Gate

Phase 5 — DOCUMENT
  Step 11: Documentation (project docs, then Claude docs)

Phase 6 — RECLAIM
  Step 12: Purge CPU-Eating Workers (local + VPS)
  Step 13: Cleanup — app-scoped (backup retention enforced)
```

## Versioning Scheme

CalVer: `vYYYY.MM.DD`. `package.json` stores `2026.04.04`; the git tag is `v2026.04.04`. A same-day re-release appends a suffix: `v2026.04.04.2`.

## Block Preamble — every fenced block is a separate shell

Nothing assigned in one fenced block is in scope in the next: each block is
executed as its own shell. A block that consumes `STAMP`, `new`, `current`,
`BRANCH` or `BACKUP_ROOT` **must re-derive it at the top**, or it silently runs
with an empty value — `pg_restore … "db-.dump"`, a false `ABORT: no failsafe
backup`, `git log "v..v"`, and worst, `cd ""` which is a no-op returning 0 that
leaves a destructive block running in the project directory.

Copy the lines you need:

```bash
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.backups/$(basename "$PWD")}"
STAMP=$(ls -t "$BACKUP_ROOT"/repo-*.bundle 2>/dev/null | head -1 | sed -E 's/.*repo-(.*)\.bundle$/\1/')
new=$(node -p "require('./package.json').version")          # post-Step 3
current=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')   # pre-tag
# after Step 7e has tagged v$new, `current` is the tag BEFORE it:
# current=$(git describe --tags --abbrev=0 "v$new^" 2>/dev/null | sed 's/^v//')
BRANCH=$(git branch --show-current)
```

**Two rules that follow from this, applied throughout:**

1. Every `cd` carries `|| exit 1`. `cd ""` succeeds and changes nothing.
2. Every re-derived value that a destructive command depends on is asserted
   non-empty before that command runs.


---

# Phase 0 — SAFEGUARD

## Step 0: Preflight

Refuse to start on a dirty tree or a branch behind origin. A release built from a tree that does not match the remote is unreproducible.

```bash
[ -z "$(git status --porcelain)" ] || { echo "ABORT: uncommitted changes"; exit 1; }
git fetch origin --quiet
behind=$(git rev-list --count HEAD..origin/main)
[ "$behind" = "0" ] || { echo "ABORT: $behind commits behind origin/main"; exit 1; }
```

## Step 1: Failsafe Backup & Retention Proof

Runs first, always. **The pipeline must not proceed if this step cannot prove a restorable copy exists.**

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

# 3. Production database — dumped from the VPS itself, before any deploy touches it.
#    Cloud runs against a live shared database; unlike the desktop variant, this
#    dump is not optional and is not commented out.
ssh "$VPS_HOST" "docker exec $DB_CONTAINER pg_dump -U $DB_USER -Fc $DB_NAME" \
  > "$BACKUP_ROOT/db-$STAMP.dump"
[ -s "$BACKUP_ROOT/db-$STAMP.dump" ] || { echo "ABORT: empty database dump"; exit 1; }
```

**Retention rule — the failsafe invariant:**

> At least **one** verified backup must exist at all times. Cleanup (Step 13) prunes *older* backups only, and only after confirming a newer verified one is present. If exactly one backup exists, it is never deleted, regardless of age.

```bash
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

## Step 2: Quality Gate

```
/pipeline-quality
```

Runs stack detection, lint, type check, build, the three-part security gate, tests, the happy/non-happy/edge case matrix, local E2E, dead code detection, dependency audit, and the reasoning phase (parallel simplification + severity-rated review with remediation) — Steps 0–14 of that skill, in full. This step does not inline any of those checks; it consumes the PASS/FAIL result.

**Gate rule:** any 🔴 Critical or 🟠 High finding, any Semgrep ERROR, any HIGH `/security-review` finding, or any changed behavior missing a non-happy-path or edge case test blocks the pipeline. `NOT RUN` is recorded and carried forward — it is never treated as a pass.

---

# Phase 2 — INTEGRATE

## Step 3: Version Bump

```bash
current=$(node -p "require('./package.json').version" 2>/dev/null || echo "0.0.0")
new=$(date +%Y.%m.%d)

git rev-parse "v$new" >/dev/null 2>&1 && new="$new.$(( $(git tag -l "v$(date +%Y.%m.%d)*" | wc -l) + 1 ))"
echo "Version: $current -> $new"

npm version "$new" --no-git-tag-version --allow-same-version
```

## Step 4: Commit

Conventional Commits, deliberate staging, a secret scan on the staged set, and a hard rule against committing directly to the default branch.

```bash
# Never `git add -A` blind: inspect what is about to enter history
git status --short
git diff --stat

# Stage deliberately — exclude build output, local config, and secrets
git add package.json 2>/dev/null || true

# Refuse to commit if a secret slipped into the staged set
git diff --cached | grep -nEi '(api[_-]?key|secret|password|token|BEGIN [A-Z ]*PRIVATE KEY)\s*[=:]' \
  && { echo "BLOCKED: possible secret staged"; exit 1; }
```

**Message format** — Conventional Commits, imperative mood, *why* over *what*:

```
<type>(<scope>): <subject>

<body: the problem this solves and any non-obvious decision>

<footer: Refs #123 / BREAKING CHANGE: ...>
```

**Gate rule:** never commit directly on `main`/`master`. If `git branch --show-current` returns the default branch, branch first. Never commit over unresolved 🔴/🟠 findings from Step 2.

```bash
new=$(node -p "require('./package.json').version")   # re-derived: separate shell

[ "$(git branch --show-current)" = "main" ] && git checkout -b "release/v$new"
git commit -m "release: v$new"
```

## Step 5: Merge to main

```bash
BRANCH=$(git branch --show-current)
new=$(node -p "require('./package.json').version")   # re-derived: separate shell
git fetch origin --prune

# Rebase onto the latest main first so the merge is a fast-forward and CI
# validates the code as it will actually exist on main
git rebase origin/main || { echo "ABORT: resolve rebase conflicts, then re-run"; exit 1; }

# Re-run the gate after rebasing — a clean merge can still be a broken build.
# Semantic conflicts (two independently-correct changes that break combined)
# pass `git merge` and fail the build; this is the most commonly skipped gate.
/pipeline-quality || { echo "ABORT: gate failed post-rebase"; exit 1; }

git checkout main
git merge --no-ff "$BRANCH" -m "merge: $BRANCH into main (v$new)"
```

Prefer a PR-based merge where branch protection is configured:

```bash
gh pr create --fill --base main
gh pr checks --watch
gh pr merge --merge --delete-branch
```

## Step 6: Push to GitHub

```bash
git push origin main

git fetch origin
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] \
  || { echo "ABORT: local and origin/main diverged after push"; exit 1; }
```

**Gate rule:** verify the push landed. A rejected non-fast-forward push that scrolls past in the log is how a "released" version ends up never leaving the laptop.

---

# Phase 3 — BUILD & RELEASE

## Step 7: Build, Container Image, SBOM/CVE Gate, Staging Validation, Release

### 7a — Application Build

```bash
set -euo pipefail
npm run build || npx vite build
[ -f "pyproject.toml" ] && python -m build
[ -f "go.mod" ]        && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" ./...
[ -f "Cargo.toml" ]    && cargo build --release

# Reproducibility: the same commit must produce the same artifact
export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)
```

### 7b — Container & Infra Hygiene

Checks specific to a containerized/compose deploy that the universal quality gate has no reason to know about.

```bash
# Dockerfile lint — non-root user, pinned base, no secrets in layers
hadolint Dockerfile
grep -qE '^USER ' Dockerfile || echo "BLOCK: container runs as root"
grep -nE '^(ENV|ARG).*(SECRET|PASSWORD|TOKEN|KEY)=' Dockerfile && echo "BLOCK: secret baked into image"

# Compose file sanity for the target that actually ships this
docker compose -f "$COMPOSE_FILE" config -q || { echo "ABORT: invalid compose file"; exit 1; }

# Migrations must be reversible and non-locking
ls migrations/*.sql 2>/dev/null | while read -r m; do
  grep -qi "down\|rollback" "$m" || echo "WARNING: $m has no down migration"
done

# Kubernetes secondary path only
[ -d "k8s/" ] && kubectl apply --dry-run=server -f k8s/
[ -f "helm/Chart.yaml" ] && { helm lint helm/ && helm template helm/ | kubeconform -strict; }
```

**Gate rule:** a container running as root, a secret baked into an image layer, or an invalid compose file blocks the release.

### 7c — Container Build, SBOM & CVE Gate

```bash
set -euo pipefail
new=$(node -p "require('./package.json').version")   # re-derived: separate shell

docker build \
  --build-arg VCS_REF="$(git rev-parse HEAD)" \
  --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
  --label "org.opencontainers.image.version=$new" \
  -t "$APP_IMAGE:$new" .

docker images "$APP_IMAGE:$new" --format "{{.Size}}"
docker history "$APP_IMAGE:$new" --no-trunc | grep -iE 'SECRET|PASSWORD|TOKEN' \
  && { echo "ABORT: credential visible in image history"; exit 1; }

mkdir -p dist   # syft cannot create the redirect target itself
syft "$APP_IMAGE:$new" -o spdx-json > "dist/sbom-$new.spdx.json"

trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed "$APP_IMAGE:$new" \
  || { echo "ABORT: HIGH/CRITICAL CVE in image"; exit 1; }

cosign sign --yes "$APP_IMAGE:$new" 2>/dev/null || echo "NOT RUN: cosign unavailable — recorded, not a pass"
```

**Gate rule:** a HIGH or CRITICAL fixable CVE blocks the release. `--ignore-unfixed` is deliberate — blocking on vulnerabilities with no available patch stalls releases without improving security.

### 7d — Staging Validation

Run the **real image** in a **real environment** before production sees it.

```bash
set -euo pipefail
# Re-derived: each fenced block is a separate shell (see Block Preamble).
new=$(node -p "require('./package.json').version")
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.backups/$(basename "$PWD")}"
STAMP=$(ls -t "$BACKUP_ROOT"/repo-*.bundle 2>/dev/null | head -1 | sed -E 's/.*repo-(.*)\.bundle$/\1/')
[ -n "$STAMP" ] || { echo "ABORT: no Step 1 backup found — cannot restore a production schema"; exit 1; }

# Container smoke — must start standalone, become healthy, shut down cleanly
docker run -d --name smoke -p 8080:8080 --env-file .env.staging "$APP_IMAGE:$new"
timeout 60 bash -c 'until curl -fs localhost:8080/health >/dev/null; do sleep 2; done' \
  || { docker logs smoke; echo "ABORT: container never became healthy"; exit 1; }
curl -fs localhost:8080/ready
curl -fs localhost:8080/version | grep -q "$new"
docker stop --time=30 smoke
[ "$(docker inspect -f '{{.State.ExitCode}}' smoke)" = "0" ] \
  || echo "WARNING: unclean shutdown — in-flight requests will be dropped on deploy"
docker rm -f smoke

# Migration dry-run against a RESTORED copy of production — never a synthetic schema
[ -s "$BACKUP_ROOT/db-$STAMP.dump" ] || { echo "ABORT: Step 1 database dump missing or empty"; exit 1; }
pg_restore -d "$STAGING_DB" "$BACKUP_ROOT/db-$STAMP.dump"
npm run migrate:up   || { echo "ABORT: migration fails on production schema"; exit 1; }
npm run migrate:down || { echo "ABORT: migration is not reversible"; exit 1; }
npm run migrate:up
psql "$STAGING_DB" -c "SELECT relname, mode FROM pg_locks l JOIN pg_class c ON c.oid=l.relation WHERE mode LIKE '%Exclusive%';"

# Deploy to staging over the same SSH+compose path used for production, then validate
ssh "$STAGING_HOST" "cd '$REMOTE_APP_DIR' || exit 1; docker compose -f $STAGING_COMPOSE_FILE pull && docker compose -f $STAGING_COMPOSE_FILE up -d"
npm run test:smoke -- --base-url="https://staging.$DOMAIN"
npx pact-broker can-i-deploy --pacticipant app --version "$new" --to-environment production 2>/dev/null || echo "NOT RUN: no contract broker configured"
k6 run --vus 50 --duration 2m load/smoke.js \
  --threshold 'http_req_duration{p(95)}<500' --threshold 'http_req_failed<0.01'
```

**Gate rule:** production deploy is blocked until the image runs healthy standalone, migrations apply *and* reverse against a production-shaped schema, contract tests pass (or are named `NOT RUN`), and p95 latency plus error rate hold against the previous release.

### 7e — Release Version

Tag only a commit that already passed staging validation above — that ordering is what makes the release trustworthy.

```bash
new=$(node -p "require('./package.json').version")   # re-derived: separate shell

git tag -a "v$new" -m "Release v$new"
git push origin "v$new"
gh release create "v$new" --title "v$new" --generate-notes
```

**Gate rule:** tag only a commit that is already on `origin/main` and green through 7a–7d. Tagging local or unvalidated work produces a release nobody else can reproduce.

---

# Phase 4 — SHIP

## Step 8: Deploy to Production (VPS + docker compose)

The first irreversible-feeling step — irreversible only if the rollback target is captured wrong. This is a recorded failure mode, not a hypothetical: `resumeflex/deploy-cloud.sh` carries a comment recording a real incident on 2026-07-30 where a cleanup pass counted image *rows* (`docker images`, one row per tag) instead of image *IDs*, and deleted its own rollback target because a repository with three tags pointing at two images made the third row look like a distinct, disposable image. Capturing and cleaning up **by image ID**, not by tag, is not a style preference — it is the fix for that incident.

**Reversibility is a property of the compose file, not of the rollback command.**
Retagging an image name the compose file never references and running `up -d`
is a no-op that exits 0 — the deploy looks rolled back and production keeps
serving the broken build. So this skill pins the deploy to an explicit version
the compose file actually resolves, and asserts that at *deploy* time:

```yaml
# $REMOTE_APP_DIR/$COMPOSE_FILE — the app service MUST resolve its image this way
services:
  app:
    image: ${APP_IMAGE}:${APP_VERSION}    # APP_VERSION comes from $REMOTE_APP_DIR/.env
    build: .                              # optional; only for deploy shape (a)
```

```bash
set -euo pipefail

# Re-derive: each fenced block is a separate shell (see Block Preamble).
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.backups/$(basename "$PWD")}"
STAMP=$(ls -t "$BACKUP_ROOT"/repo-*.bundle 2>/dev/null | head -1 | sed -E 's/.*repo-(.*)\.bundle$/\1/')
new=$(node -p "require('./package.json').version")

# ── Precondition 1: the deploy must be reversible AT ALL ────────────────────
# Fail loudly here rather than silently at rollback time.
ssh "$VPS_HOST" "grep -qE 'image:[[:space:]]*\\\$\\{?APP_IMAGE\\}?:\\\$\\{?APP_VERSION\\}?' '$REMOTE_APP_DIR/$COMPOSE_FILE'" \
  || { echo "ABORT: $COMPOSE_FILE does not resolve its image from \${APP_IMAGE}:\${APP_VERSION} — this deploy would not be reversible"; exit 1; }

# ── Precondition 2: a verified failsafe backup exists ───────────────────────
[ -n "$STAMP" ] && [ -f "$BACKUP_ROOT/repo-$STAMP.bundle" ] \
  || { echo "ABORT: no failsafe backup in $BACKUP_ROOT"; exit 1; }

# ── Capture the rollback target: BOTH the version pin and the image ID ──────
# The version pin is what rollback rewrites; the image ID is what keeps Step 13
# from pruning the image that pin resolves to.
PREV_VERSION=$(ssh "$VPS_HOST" "grep -E '^APP_VERSION=' '$REMOTE_APP_DIR/.env' | head -1 | cut -d= -f2-")
[ -n "$PREV_VERSION" ] || { echo "ABORT: no APP_VERSION in remote .env — nothing to roll back to"; exit 1; }
ROLLBACK_ID=$(ssh "$VPS_HOST" "docker inspect --format='{{.Image}}' $APP_CONTAINER")
ssh "$VPS_HOST" "docker tag $ROLLBACK_ID $APP_IMAGE:rollback-previous"
printf '%s\n' "$PREV_VERSION" > .previous-deployed-version      # the rollback TARGET
printf '%s\n' "$ROLLBACK_ID"  > .previous-deployed-image-id     # retention key for Step 13

# ── Guard the destructive sync ──────────────────────────────────────────────
# With REMOTE_APP_DIR empty the target degrades to "$VPS_HOST:/" and --delete
# runs at the filesystem root of a box shared with sibling apps.
case "${REMOTE_APP_DIR:-}" in
  ""|"/"|*..*) echo "ABORT: refusing to rsync --delete into '${REMOTE_APP_DIR:-<empty>}'"; exit 1 ;;
  /*/*) : ;;                       # absolute and at least two segments deep — OK
  *) echo "ABORT: REMOTE_APP_DIR must be an absolute path at least two segments deep, got '$REMOTE_APP_DIR'"; exit 1 ;;
esac

# RSYNC_EXCLUDES must be DEFINED, here, next to the command that uses it. An
# undefined array expands to nothing under `set -u` in bash >= 4.4 without
# erroring, degrading this into an unfiltered destructive sync that deletes the
# remote .env, uploads/ and releases/ — none of which Step 1 backs up.
RSYNC_EXCLUDES=(
  --exclude='.env' --exclude='.env.*'      # the version pin lives here
  --exclude='uploads/' --exclude='storage/' --exclude='data/' --exclude='media/'
  --exclude='releases/'                    # the same dir Step 13 prunes
  --exclude='node_modules/' --exclude='.git/'
  --exclude='*.dump' --exclude='*.sqlite' --exclude='*.sqlite3'
)
[ "${#RSYNC_EXCLUDES[@]}" -ge 6 ] || { echo "ABORT: RSYNC_EXCLUDES not populated"; exit 1; }

# Sync and bring up. Two shapes, both supported — pick one per app:
#   a) rsync source, build on the VPS (compose's `image:` key tags the build)
rsync -avz --delete "${RSYNC_EXCLUDES[@]}" ./ "$VPS_HOST:$REMOTE_APP_DIR/"
ssh "$VPS_HOST" "cd '$REMOTE_APP_DIR' || exit 1; \
  sed -i 's/^APP_VERSION=.*/APP_VERSION=$new/' .env && grep -qx 'APP_VERSION=$new' .env \
  && docker compose -f $COMPOSE_FILE up -d --build"
#   b) build locally, push to a registry, pull remotely
#      docker push "$APP_IMAGE:$new"
#      ssh "$VPS_HOST" "cd '$REMOTE_APP_DIR' || exit 1; \
#        sed -i 's/^APP_VERSION=.*/APP_VERSION=$new/' .env && grep -qx 'APP_VERSION=$new' .env \
#        && docker compose -f $COMPOSE_FILE pull && docker compose -f $COMPOSE_FILE up -d"

# Health-gate before declaring success
timeout 120 bash -c "until [ \"\$(ssh $VPS_HOST \"docker inspect -f '{{.State.Health.Status}}' $APP_CONTAINER\")\" = healthy ]; do sleep 5; done" \
  || { echo "ABORT: container never became healthy"; exit 1; }
```

**Rollback — one command, and it is real because it rewrites the pin the
compose file resolves, not a tag nothing references:**

```bash
PREV_VERSION=$(cat .previous-deployed-version)
[ -n "$PREV_VERSION" ] || { echo "ABORT: no rollback target recorded — Step 8 never ran"; exit 1; }
ssh "$VPS_HOST" "cd '$REMOTE_APP_DIR' || exit 1; \
  sed -i 's/^APP_VERSION=.*/APP_VERSION=$PREV_VERSION/' .env \
  && grep -qx 'APP_VERSION=$PREV_VERSION' .env \
  && docker compose -f $COMPOSE_FILE up -d --no-build"
timeout 120 bash -c "until [ \"\$(ssh $VPS_HOST \"docker inspect -f '{{.State.Health.Status}}' $APP_CONTAINER\")\" = healthy ]; do sleep 5; done" \
  || { echo "ABORT: rollback to $PREV_VERSION did not become healthy — manual intervention"; exit 1; }
echo "rolled back to $PREV_VERSION"
```

**Security precondition.** Restate the Step 2 outcome before deploying — Semgrep, `/security-review`, and `security-guidance` readiness, each PASS or `NOT RUN`. A HIGH finding blocks. A `NOT RUN` ships only as a named decision, never as an unnoticed gap.

**Kubernetes (secondary).** Where the target is a cluster rather than a VPS, substitute `kubectl set image` / `kubectl rollout status` / `kubectl rollout undo` for the compose commands above, staged through a canary before the full rollout. The gate rules are unchanged; only the transport differs — and the reversibility precondition still applies, it is just satisfied differently: a Deployment's `.spec.template.spec.containers[].image` must name an explicit tag (never `:latest`) so `kubectl rollout undo` has a distinct previous revision to return to. Assert that before deploying, the same way Precondition 1 asserts it for compose.

## Step 9: Production E2E (critical path only)

This is **not** a re-run of Step 2's local E2E. **Admission rule: a spec earns a place here only if it can fail in production while passing locally.** Everything else stays local. Local tests cannot observe real TLS termination, the real `X-Forwarded-For` chain, the real database, or real email dispatch — the class of bug this step exists to catch.

Scope: login, one authenticated write, one authenticated read, logout. Nothing more.

```bash
RUN_ID=$(git rev-parse --short HEAD)
export E2E_ACCOUNT="e2e+${RUN_ID}@example.com"

# Refuse to start without teardown credentials. Creating accounts you cannot
# remove is worse than skipping the check. `exit 0` here would end the WHOLE
# release chain with a success status before Steps 10-13 ever run — skip the
# step with a conditional instead.
if [ -z "${E2E_ADMIN_TOKEN:-}" ]; then
  echo "9. Production E2E: NOT RUN — no teardown credentials (E2E_ADMIN_TOKEN unset)"
else
  # Sweep orphans from earlier failed runs BEFORE creating new ones
  npm run e2e:sweep-orphans -- --pattern 'e2e+*@example.com' --older-than 1h

  trap 'npm run e2e:teardown -- --account "$E2E_ACCOUNT"' EXIT

  npx playwright test --config playwright.prod.config.ts \
    --grep @critical-path \
    --base-url "https://$DOMAIN"
fi
```

All test traffic carries an analytics-exclusion header so the run does not pollute production metrics.

**Gate rule:** a failure here triggers the rollback gate below. It cannot block in the ordinary sense, because the tag and release from Step 7e already exist — instead of deleting the published tag (which would break anyone who already fetched it), the release is marked **SUPERSEDED**:

```bash
new=$(node -p "require('./package.json').version")

# Roll back by rewriting the version pin the compose file resolves (Step 8).
PREV_VERSION=$(cat .previous-deployed-version)
[ -n "$PREV_VERSION" ] || { echo "ABORT: no rollback target recorded"; exit 1; }
ssh "$VPS_HOST" "cd '$REMOTE_APP_DIR' || exit 1; \
  sed -i 's/^APP_VERSION=.*/APP_VERSION=$PREV_VERSION/' .env \
  && grep -qx 'APP_VERSION=$PREV_VERSION' .env \
  && docker compose -f $COMPOSE_FILE up -d --no-build"

gh release edit "v$new" --title "v$new (SUPERSEDED $(date -u +%FT%TZ))" \
  --notes "$(gh release view "v$new" --json body -q .body)

⚠️ Superseded: production E2E failed post-deploy. Rolled back to $(cat .previous-deployed-version)."
```

---

## Step 10: Post-Deploy Verification & Rollback Gate

Verification is immediate here — and so is the rollback.

```bash
curl -f  "https://$DOMAIN/health"
curl -fs "https://$DOMAIN/version" | grep -q "$new" \
  || { PREV_VERSION=$(cat .previous-deployed-version); \
       ssh "$VPS_HOST" "cd '$REMOTE_APP_DIR' || exit 1; sed -i 's/^APP_VERSION=.*/APP_VERSION=$PREV_VERSION/' .env && grep -qx 'APP_VERSION=$PREV_VERSION' .env && docker compose -f $COMPOSE_FILE up -d --no-build"; \
       echo "ABORT: live version mismatch — rolled back to $PREV_VERSION"; exit 1; }

# Match `(unhealthy)` explicitly. `grep -v healthy` fires on every container
# that simply has NO healthcheck — the warning would then be permanently on.
ssh "$VPS_HOST" "docker ps --filter name=$APP_PREFIX --format '{{.Names}}\t{{.Status}}'" \
  | grep -F '(unhealthy)' && echo "WARNING: unhealthy sibling container under this app's prefix"
ssh "$VPS_HOST" "docker ps --filter name=$APP_PREFIX --format '{{.Names}}\t{{.Status}}'" \
  | grep -vF '(healthy)' | grep -vF '(unhealthy)' \
  | while read -r line; do echo "NOTE: no healthcheck defined — health unknown for: $line"; done
```

| Signal | Healthy | Act |
|--------|---------|-----|
| 5xx rate | ≤ pre-deploy baseline | Above → run the Step 8 rollback command |
| p95 latency | within 20% of baseline | Sustained regression → roll back |
| Container health | `healthy`, 0 restarts after settling | Unhealthy/restarting → roll back, read `docker logs` |
| Disk / memory on the VPS | below limits | At limit → the new build regressed resource use |

**Gate rule:** soak for 15 minutes against the pre-deploy baseline before declaring success. Phases 5 and 6 do not run on a failed deploy — Step 13 must never prune the image the rollback needs.

---

# Phase 5 — DOCUMENT

## Step 11: Documentation

Written while the release context is fresh, and before anything is cleaned up.

### 11a — Project Documents

| Document | Update |
|----------|--------|
| `CHANGELOG.md` | New `## v$new — YYYY-MM-DD` section: Added / Changed / Fixed / Removed / Security |
| `README.md` | Version badge, install commands, any changed prerequisites |
| `docs/**/*.md` | Behavior that changed this release; delete instructions for removed features |
| `API.md` / `openapi.yaml` | New, changed, or deprecated endpoints and fields |
| `MIGRATION.md` | Required steps for breaking changes |
| `PLAN.md` | Tick off shipped items; carry the 🟡/🟢 review follow-ups forward |

```bash
# Re-derived: separate shell. By this step v$new is already tagged (Step 7e),
# so `new` is the newest tag and `current` is the one before it. An empty
# `$current` would produce `git log "v..v$new"` and kill CHANGELOG generation.
new=$(node -p "require('./package.json').version")
# `git tag --sort=-creatordate | sed -n 2p` is NOT reliable here: lightweight
# tags sort by commit date, so two tags on same-second commits tie and fall
# back to name order. Ask git for the nearest tag before this release instead.
current=$(git describe --tags --abbrev=0 "v$new^" 2>/dev/null | sed 's/^v//')
[ -n "$new" ] || { echo "ABORT: cannot read version from package.json"; exit 1; }
if [ -n "$current" ]; then RANGE="v$current..v$new"; else RANGE="v$new"; fi

{ echo "## v$new - $(date +%Y-%m-%d)"; echo; git log "$RANGE" --pretty='- %s' --no-merges; echo; cat CHANGELOG.md; } > CHANGELOG.tmp && mv CHANGELOG.tmp CHANGELOG.md
if [ -n "$current" ]; then grep -rn "$current" --include='*.md' . | grep -v CHANGELOG.md || true; fi
```

**Gate rule:** no doc may describe behavior this release removed.

### 11b — Claude Docs

The agent-facing memory layer.

| File | Update | Optimize for |
|------|--------|-------------|
| `CLAUDE.md` | Identity, rule index, version-specific notes | Brevity — loaded every session |
| `docs/rules/*.md` | Domain canon changed by this release | Depth is fine; move detail out of `CLAUDE.md` and into these |
| `.claude/agents/*.md` | Frontmatter, capability text | Accuracy — a stale description causes silent misrouting |
| `skills/*/SKILL.md` | Steps changed by this release | Progressive disclosure |

```bash
grep -rhoE '\]\(([^)]+\.md)\)' CLAUDE.md docs/rules/*.md 2>/dev/null | sed -E 's/.*\((.*)\)/\1/' \
  | while read -r f; do [ -e "$f" ] || echo "BROKEN LINK: $f"; done
wc -w CLAUDE.md
```

**Gate rule:** every agent, skill, and file path named in `CLAUDE.md` or `docs/rules/*.md` must resolve.

---

# Phase 6 — RECLAIM

## Step 12: Purge CPU-Eating Workers (local + VPS)

```bash
# Local — scope by WORKING DIRECTORY. A CPU threshold alone lists sibling
# projects' processes, and "kill by PID" on that list kills someone else's work.
proc_cwd() {   # pid -> working directory (Linux /proc, macOS lsof fallback)
  readlink -e "/proc/$1/cwd" 2>/dev/null \
    || lsof -a -p "$1" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -1
}

PROJ=$(pwd -P)
ps -eo pid,pcpu,args --sort=-pcpu | awk 'NR>1 && $2>50 {print $1}' | while read -r pid; do
  cwd=$(proc_cwd "$pid"); [ -n "$cwd" ] || continue
  case "$cwd" in "$PROJ"|"$PROJ"/*) ps -p "$pid" -o pid=,pcpu=,args= ;; esac
done | head -20

# VPS — scope to THIS app's containers. The box is multi-app.
ssh "$VPS_HOST" "docker stats --no-stream --format '{{.Name}}\t{{.CPUPerc}}' \
  | grep '^${APP_PREFIX}'"
```

**Gate rule:** identify, then kill by PID or container name within this app's scope. Never `pkill -f node`, never a host-wide sweep — sibling apps share this machine.

## Step 13: Cleanup — app-scoped

Runs **only** after Step 10 confirmed the deploy is healthy. Everything here is scoped by app, and the failsafe invariant is re-proved before a single deletion.

```bash
# ── Precondition: the failsafe must still hold ───────────────────────────────
BACKUPS=$(find "$BACKUP_ROOT" -name 'repo-*.bundle' | wc -l)
[ "$BACKUPS" -ge 1 ] || { echo "ABORT: cleanup would leave zero backups"; exit 1; }
git bundle verify "$(ls -t "$BACKUP_ROOT"/repo-*.bundle | head -1)" >/dev/null \
  || { echo "ABORT: newest backup fails verification"; exit 1; }

# ── Dangling layers — SCOPED TO THIS APP'S COMPOSE PROJECT ──────────────────
# A bare `docker image prune -f` is host-wide. On a shared box that deletes a
# sibling app's dangling images — including a rollback target it captured by
# image ID without tagging it, which is the exact technique Step 8 teaches.
# `docker builder prune` has no equivalent project scope, so it is NOT run
# here; it lives under the honestly-labelled host-level section below.
COMPOSE_PROJECT="${COMPOSE_PROJECT:-$(basename "$REMOTE_APP_DIR")}"
ssh "$VPS_HOST" "docker image prune -f --filter 'label=com.docker.compose.project=$COMPOSE_PROJECT'"

# ── Tagged images: keep current AND rollback, matched by image ID ────────────
# Matched by ID, not by tag row — see Step 8 for why a row-count is unsafe.
KEEP_IDS=$(ssh "$VPS_HOST" "docker inspect --format='{{.Image}}' $APP_CONTAINER; \
                            docker images -q $APP_IMAGE:rollback-previous" | grep -v '^$' || true)
# An empty KEEP_IDS is the state after a FAILED deploy (container not running,
# rollback-previous absent). `echo "" | grep -q "$id"` returns 1 for every row,
# so the loop below would rmi every tag — rollback target included — with
# `|| true` swallowing the evidence. Refuse to proceed instead.
[ -n "$KEEP_IDS" ] || { echo "ABORT: cannot identify images to keep — refusing to prune"; exit 1; }

ssh "$VPS_HOST" "docker images '$APP_IMAGE' --format '{{.ID}} {{.Tag}}'" \
  | while read -r id tag; do
      [ -n "$id" ] || continue
      echo "$KEEP_IDS" | grep -qF "$id" || ssh "$VPS_HOST" "docker rmi ${APP_IMAGE}:${tag}" || true
    done
```

**Never run** `docker system prune -a` or any `--volumes` prune. Volumes hold the database and uploads, and a host-wide prune reaches every sibling app on the box — clearpath, resumeflex, and anything else sharing this VPS.

### VPS housekeeping (host-level, non-destructive to app data)

```bash
ssh "$VPS_HOST" bash -s <<'REMOTE'
journalctl --vacuum-time=14d
find /var/log -name '*.gz' -mtime +30 -delete
# Host-wide by design: the BuildKit cache has no per-app scope. It is
# regenerable, but it is shared — run it knowing it slows every app's next
# build on this box, not just this one's.
docker builder prune -f --filter 'until=168h'
REMOTE

# This app's release directories only — keep the newest 3
ssh "$VPS_HOST" "ls -1dt ${REMOTE_APP_DIR}/releases/* 2>/dev/null | tail -n +4 | xargs -r rm -rf"
```

### Backup retention — the failsafe rule

```bash
# Re-derived: separate shell. An unset BACKUP_ROOT makes `cd ""` a NO-OP that
# returns 0, after which this block prunes repo-*.bundle in the PROJECT
# directory and reports FAILSAFE VIOLATED on a perfectly healthy backup set.
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.backups/$(basename "$PWD")}"
[ -n "$BACKUP_ROOT" ] && [ -d "$BACKUP_ROOT" ] || { echo "ABORT: BACKUP_ROOT '$BACKUP_ROOT' is not a directory"; exit 1; }
cd "$BACKUP_ROOT" || exit 1

TOTAL=$(ls -1 repo-*.bundle 2>/dev/null | wc -l)
if [ "$TOTAL" -gt 5 ]; then
  ls -t repo-*.bundle | tail -n +6 | while read -r old; do
    [ "$(ls -1 repo-*.bundle | wc -l)" -gt 1 ] && rm -f "$old" && echo "pruned $old"
  done
else
  echo "Retention: $TOTAL backup(s) — below threshold, nothing pruned"
fi
[ "$(ls -1 repo-*.bundle | wc -l)" -ge 1 ] || { echo "FAILSAFE VIOLATED"; exit 1; }
```

**Gate rule:** cleanup deletes only regenerable artifacts (dangling layers, rotated logs, surplus backups) and this app's own superseded images. It never touches the current release, the rollback target, Docker volumes, another app's containers/images, or the last remaining backup.

---

## Output Format

```markdown
## Cloud Build Report - v[version]

| Step | Status | Duration | Details |
|------|--------|----------|---------|
| 0 Preflight | PASS | 2s | clean tree, up to date with origin/main |
| 1 Failsafe Backup | DONE | 12s | repo bundle + db dump verified |
| 2 Quality Gate | PASS | 210s | /pipeline-quality Steps 0–14 clean |
| 3 Version Bump | DONE | 1s | v2026.07.25 -> v2026.07.26 |
| 4 Commit | DONE | 3s | abc1234 release: v2026.07.26 |
| 5 Merge to main | PASS | 30s | --no-ff; gate re-run post-rebase |
| 6 Push to GitHub | DONE | 5s | origin/main == HEAD verified |
| 7 Build/Image/SBOM/CVE/Staging/Release | PASS | 420s | 0 HIGH/CRITICAL CVE; staging p95 310ms err 0.2%; v2026.07.26 tagged |
| 8 Deploy to Prod | DONE | 90s | compose up -d --build; rollback target image ID a1b2c3d |
| 9 Production E2E | PASS | 45s | login/write/read/logout via temp account, torn down |
| 10 Post-Deploy Verify | PASS | 900s | health OK, version match, 5xx nominal |
| 11 Documentation | DONE | 25s | CHANGELOG, README, CLAUDE.md updated |
| 12 Worker Purge | DONE | 5s | 0 stale workers in clearpath- scope |
| 13 Cleanup | DONE | 20s | 2 dangling layers pruned, 3 backups kept |

### Artifacts
- `registry.example.com/app:2026.07.26` (142MB, signed)
- `dist/sbom-2026.07.26.spdx.json`

### Rollback
- One command: rewrite `APP_VERSION` in `$REMOTE_APP_DIR/.env` to the recorded previous version and `docker compose up -d --no-build` on `$VPS_HOST`
- Reversibility asserted at deploy time: `$COMPOSE_FILE` must resolve `image: ${APP_IMAGE}:${APP_VERSION}`
- Rollback target recorded twice: the version pin (what rollback rewrites) and the image ID (what keeps Step 13 from pruning it)
```

## Relationship to Other Skills

| Skill | Role |
|-------|------|
| `/pipeline-quality` | Step 2 gate — deterministic checks plus simplify/review; this skill adds no duplicate checks |
| `/pipeline-full-build-desktop` | Sibling — same phase order; its Steps 7–12 diverge (local compile, sign/notarize, packaged-binary validation, release, update-feed publish, telemetry gate) where this skill's Steps 7–10 do the containerized equivalent |
| `/kubernetes-deployment`, `/terraform-patterns` | Deeper reference for the Kubernetes secondary path in Step 8 |
