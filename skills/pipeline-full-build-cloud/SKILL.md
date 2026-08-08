---
name: pipeline-full-build-cloud
description: Cloud release variant for web/API apps - container build with SBOM and CVE gate, migration dry-run, staging deploy with contract and load validation, canary/rolling production deploy, live health and version assertion, and one-command rollback. Supplies Phase 3 and Step 12 of pipeline-full-build.
---

# Pipeline Full Build — Cloud Variant

The **cloud** half of `/pipeline-full-build`. Supplies the build, test, validation, and deploy steps for containerized web and API services.

Where the desktop variant validates an artifact that will run on machines you do not control, the cloud variant validates a service **you do control but that is live for everyone at once**. The consequence: cloud gets a staging environment and a reversible rollout, and in exchange it must validate things desktop never faces — schema migrations, contract compatibility with existing clients, and behavior under load.

## Division of Labor

| Skill | Owns |
|-------|------|
| `pipeline-full-build` | The shared spine — Steps 0–7, 11, 13–16 (backup, verify, integrate, release, docs, reclaim) |
| **`pipeline-full-build-cloud`** (this) | **Steps 8–10 and 12 for web/API, plus the cloud-specific gate additions** |
| `pipeline-full-build-desktop` | The same steps for Electron/desktop targets |

## When to Use This Skill

- Releasing a web app, API, or background service to a container platform
- Any build whose output is an **image deployed to infrastructure you operate**
- Serverless and PaaS targets (adapt Step 12; Steps 8–10 apply unchanged)

## Target Agents

- `devops-engineer` - Primary pipeline operator
- `sre-specialist` - Deploy, rollout strategy, rollback gate
- `cloud-architect` - Infrastructure changes
- `cyber-sentinel` - Image CVE gate and SBOM review
- `qa-engineer` - Staging validation and contract tests

## Stack Detection

```bash
[ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] && echo "CLOUD"
[ -d "k8s/" ] || [ -f "helm/Chart.yaml" ]          && echo "CLOUD"
[ -d "terraform/" ]                                 && echo "CLOUD"
[ -f "vercel.json" ] || [ -f "fly.toml" ] || [ -f "render.yaml" ] && echo "CLOUD (PaaS)"
[ -f "serverless.yml" ] || [ -f "template.yaml" ]  && echo "CLOUD (serverless)"
```

---

## Cloud Additions to Step 1 (Quality Gate)

`/pipeline-quality` runs the universal gate. Cloud adds checks for things that only exist once a service is deployed:

```bash
# Infrastructure is code and gets the same gate
terraform validate && terraform fmt -check
kubectl apply --dry-run=server -f k8s/     # server-side catches admission failures client-side misses
helm lint helm/ && helm template helm/ | kubeconform -strict

# Dockerfile lint — non-root user, pinned base, no secrets in layers
hadolint Dockerfile
grep -qE '^USER ' Dockerfile || echo "BLOCK: container runs as root"
grep -nE '^(ENV|ARG).*(SECRET|PASSWORD|TOKEN|KEY)=' Dockerfile && echo "BLOCK: secret baked into image"

# API contract: the new spec must not break existing clients
npx @redocly/cli lint openapi.yaml
oasdiff breaking openapi.base.yaml openapi.yaml \
  && { echo "BLOCK: breaking API change without a version bump"; exit 1; }

# Migrations must be reversible and non-locking
ls migrations/*.sql | while read -r m; do
  grep -qi "down\|rollback" "$m" || echo "WARNING: $m has no down migration"
done
```

**Gate rule:** a container running as root, a secret baked into an image layer, or a breaking API change without a version bump blocks the release.

### Multi-tenant scope check (cloud-specific)

A hosted service answers several tenants from one fleet, so the highest-impact vulnerability class here is not injection — it is a request authorized against one tenant and answered with another's data. Step 4c (`/security-review`) is where this gets caught; give it the shape to look for:

```bash
# Routes taking a tenant id in the PATH. Each must query the tenant it AUTHORIZED, not the
# one the URL names. Middleware resolving the tenant from a header while the handler reads
# req.params is the canonical form of this bug — and it type-checks, lints and tests clean.
grep -rnE "params\.(workspaceId|tenantId|orgId|accountId)" \
  --include='*.ts' --include='*.py' --include='*.go' src/ app/ 2>/dev/null
```

Every hit needs one answer: **which value proved authorization, and which value reaches the `WHERE` clause?** If they can differ, that is a cross-tenant read.

**Gate rule:** any route where the authorizing and querying identifiers can diverge blocks the release until they are reconciled — preferably in shared middleware, because a check each handler has to remember is a check that eventually is not run.

---

# Phase 3 — BUILD (cloud)

## Step 8: Build

```bash
set -euo pipefail

# Frontend
npm run build || npx vite build

# Backend
[ -f "pyproject.toml" ] && python -m build
[ -f "go.mod" ]        && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" ./...
[ -f "Cargo.toml" ]    && cargo build --release

# Reproducibility: the same commit must produce the same artifact, or you
# cannot reason about what is actually running in production
export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)
```

## Step 9: Container Build, SBOM & CVE Gate

```bash
# ── Build with provenance ───────────────────────────────────────────────────
docker build \
  --build-arg VCS_REF="$(git rev-parse HEAD)" \
  --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
  --label "org.opencontainers.image.version=$new" \
  -t "app:$new" .

# Multi-arch where clients need it
# docker buildx build --platform linux/amd64,linux/arm64 -t "app:$new" .

# ── Size and layer hygiene ──────────────────────────────────────────────────
docker images "app:$new" --format "{{.Size}}"
docker history "app:$new" --no-trunc | grep -iE 'SECRET|PASSWORD|TOKEN' \
  && { echo "ABORT: credential visible in image history"; exit 1; }

# ── SBOM: you cannot respond to a CVE disclosure without one ────────────────
syft "app:$new" -o spdx-json > "dist/sbom-$new.spdx.json"

# ── CVE gate ────────────────────────────────────────────────────────────────
trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed "app:$new" \
  || { echo "ABORT: HIGH/CRITICAL CVE in image"; exit 1; }
docker scout cves "app:$new" || true

# ── Sign the image so the cluster can verify provenance ─────────────────────
cosign sign --yes "registry.example.com/app:$new"
```

**Gate rule:** a HIGH or CRITICAL fixable CVE blocks the release. Scanning *after* deploy is a notification, not a gate. `--ignore-unfixed` is deliberate — blocking on vulnerabilities with no available patch stalls releases without improving security.

## Step 10: Staging Validation

Cloud's equivalent of desktop's packaged-binary testing: run the **real image** in a **real environment** before production sees it.

### 10a — Container smoke

```bash
# The image must start standalone, become healthy, and shut down cleanly
docker run -d --name smoke -p 8080:8080 --env-file .env.staging "app:$new"
timeout 60 bash -c 'until curl -fs localhost:8080/health >/dev/null; do sleep 2; done' \
  || { docker logs smoke; echo "ABORT: container never became healthy"; exit 1; }

curl -fs localhost:8080/ready    # readiness must be distinct from liveness
curl -fs localhost:8080/version | grep -q "$new"

# SIGTERM handling — a container that ignores it drops in-flight requests
# on every rolling deploy, forever
docker stop --time=30 smoke
[ "$(docker inspect -f '{{.State.ExitCode}}' smoke)" = "0" ] \
  || echo "WARNING: unclean shutdown — in-flight requests will be dropped on deploy"
docker rm -f smoke
```

### 10b — Migration dry-run

```bash
# Run migrations against a restored copy of production, never against a
# synthetic schema. Drift between the two is exactly what breaks deploys.
pg_restore -d staging_db "$BACKUP_ROOT/db-$STAMP.sql.gz"
npm run migrate:up   || { echo "ABORT: migration fails on production schema"; exit 1; }
npm run migrate:down || { echo "ABORT: migration is not reversible"; exit 1; }
npm run migrate:up

# Lock check: a migration that locks a large table takes the service down
psql staging_db -c "SELECT relname, mode FROM pg_locks l JOIN pg_class c ON c.oid=l.relation WHERE mode LIKE '%Exclusive%';"
```

### 10c — Deploy to staging and validate

```bash
kubectl --context staging set image deployment/app "app=registry.example.com/app:$new"
kubectl --context staging rollout status deployment/app --timeout=5m

# Smoke: happy path AND the critical non-happy paths
npm run test:smoke -- --base-url=https://staging.example.com

# Contract tests — existing clients must keep working
npx pact-broker can-i-deploy --pacticipant app --version "$new" --to-environment production

# Load sanity: not a full perf suite, just "did this release fall off a cliff"
k6 run --vus 50 --duration 2m load/smoke.js \
  --threshold 'http_req_duration{p(95)}<500' \
  --threshold 'http_req_failed<0.01'
```

**Gate rule:** production deploy is blocked until the image runs healthy standalone, migrations apply *and* reverse against a production-shaped schema, contract tests pass, and p95 latency plus error rate hold against the previous release.

---

# Phase 4 — SHIP (cloud Step 12)

## Step 12: Production Deploy

Unlike desktop, this **is** reversible — and the entire strategy is built around keeping it that way.

**Security precondition.** Restate the Step 4 outcome before pushing the image — Semgrep, `/security-review`, and `security-guidance` readiness, each PASS or NOT RUN. A HIGH finding blocks. A `NOT RUN` ships only as a named decision, never as an unnoticed gap: a fleet deploy reaches every tenant at once, so an absent check is at its most expensive right here.

```bash
# Refuse to deploy without the Step 0 failsafe
[ -f "$BACKUP_ROOT/repo-$STAMP.bundle" ] || { echo "ABORT: no failsafe backup"; exit 1; }

# Record the rollback target explicitly
kubectl get deployment/app -o jsonpath='{.spec.template.spec.containers[0].image}' \
  > .previous-deployed-version
echo "Rollback target: $(cat .previous-deployed-version)"

# Push the signed image
docker tag  "app:$new" "registry.example.com/app:$new"
docker push "registry.example.com/app:$new"
```

### Migrations first, and backward-compatible

```bash
# Expand/contract: this release only ever ADDS. Columns and tables the old
# code still reads stay until the NEXT release removes them. That is what
# makes the rollback below actually safe.
npm run migrate:up
```

### Canary → rolling

```bash
# Canary: 10% of traffic, watched, before the fleet moves
kubectl set image deployment/app-canary "app=registry.example.com/app:$new"
kubectl rollout status deployment/app-canary --timeout=5m
sleep 300   # one telemetry cycle

CANARY_ERR=$(curl -fsS "$PROM/api/v1/query?query=rate(http_requests_total{job='app-canary',status=~'5..'}[5m])" | jq -r '.data.result[0].value[1] // 0')
awk -v e="$CANARY_ERR" 'BEGIN{exit !(e>0.01)}' && { kubectl rollout undo deployment/app-canary; echo "ABORT: canary error rate"; exit 1; }

# Full rollout with automatic revert
kubectl set image deployment/app "app=registry.example.com/app:$new"
kubectl rollout status deployment/app --timeout=10m \
  || { kubectl rollout undo deployment/app; echo "ROLLED BACK"; exit 1; }

echo "$new" > .last-deployed-version
```

### Terraform / PaaS

```bash
# Plan is reviewed, never blind-applied
( cd terraform && terraform plan -out=tfplan && terraform show tfplan && terraform apply tfplan )

# VPS via compose
# ssh "$VPS" "cd /srv/app && docker compose pull && docker compose up -d --remove-orphans"
```

**Rollback** — one command, and it works because migrations only expanded:

```bash
kubectl rollout undo deployment/app
# or pin explicitly:
kubectl set image deployment/app "app=$(cat .previous-deployed-version)"
```

**Gate rule:** if rollback requires a rebuild, a migration reversal, or more than one command, the deploy is not production-ready. Migrations must be backward-compatible with the previous release — that is the precondition that makes the rollback real rather than theoretical.

---

## Cloud Additions to Step 13 (Post-Deploy Verification)

Unlike desktop's hours-long telemetry lag, cloud verification is immediate — and so is the rollback.

```bash
curl -f  "https://app.example.com/health"
curl -fs "https://app.example.com/version" | grep -q "$new" \
  || { kubectl rollout undo deployment/app; echo "ABORT: live version mismatch"; exit 1; }

npm run test:smoke:prod -- --base-url=https://app.example.com
kubectl get pods -l app=app --field-selector=status.phase!=Running
```

| Signal | Healthy | Act |
|--------|---------|-----|
| 5xx rate | ≤ pre-deploy baseline | Above → `kubectl rollout undo` |
| p95 latency | within 20% of baseline | Sustained regression → roll back |
| Pod restarts | 0 after rollout settles | CrashLoopBackOff → roll back, read logs |
| Saturation (CPU/mem) | below limits | At limit → the new build regressed resource use |

**Gate rule:** soak for 15 minutes against the pre-deploy baseline before declaring success. Phases 5 and 6 do not run on a failed deploy — Step 16 must never prune the image the rollback needs.

---

## Output Format

```markdown
## Cloud Build Report - v[version]

| Step | Status | Duration | Details |
|------|--------|----------|---------|
| 8 Build | PASS | 40s | Vite + Go binary, reproducible |
| 9 Image/SBOM/CVE | PASS | 85s | 142MB, SBOM written, 0 HIGH/CRITICAL, cosign signed |
| 10a Container Smoke | PASS | 35s | healthy in 8s, clean SIGTERM |
| 10b Migration | PASS | 50s | up/down/up on restored prod schema, no exclusive locks |
| 10c Staging | PASS | 240s | smoke + contract OK; p95 310ms, err 0.2% |
| 12 Prod Deploy | DONE | 420s | canary 10% 5min, then rolling; rollback target app:2026.07.25 |
| 13 Verify | PASS | 900s | health OK, version match, 5xx nominal |

### Artifacts
- `registry.example.com/app:2026.07.26` (142MB, signed)
- `dist/sbom-2026.07.26.spdx.json`

### Rollback
- `kubectl rollout undo deployment/app` → app:2026.07.25 (image retained)
- Migrations expand-only; previous release runs against current schema
```

## Relationship to Other Skills

| Skill | Role |
|-------|------|
| `/pipeline-full-build` | Parent — owns Steps 0–7, 11, 13–16 and routes here |
| `/pipeline-full-build-desktop` | Sibling — same steps for Electron/desktop targets |
| `/pipeline-quality` | Step 1 gate; this skill adds the infra/container checks above |
| `/pipeline-review` | Steps 2, 3, 5 — simplify, review, commit |
| `/kubernetes-deployment`, `/terraform-patterns` | Deeper reference for Step 12 targets |
