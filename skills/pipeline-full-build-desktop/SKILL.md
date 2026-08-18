---
name: pipeline-full-build-desktop
description: Complete standalone release chain for installable desktop apps - preflight, failsafe backup, the full quality gate, commit/merge/push, local compilation including native module rebuilds against the Electron ABI, code signing and notarization, packaged-binary E2E and launch smoke, GitHub release, staged update-feed publish with a clean-VM install smoke, documentation, worker purge and cleanup.
---

# Pipeline Full Build — Desktop

A complete, standalone release chain for Electron (and Electron + Python hybrid) desktop applications — installable, signed binaries that run on end users' own machines rather than infrastructure you operate. This skill references no parent skill: it runs preflight through cleanup on its own, Steps 0–15.

The core difference from a server release: a cloud deploy ships to infrastructure you control and can be reverted in one command; a desktop release ships to N machines you do not control, and once the update feed has served a build to a client, that client cannot be forced back — the only remedy is a superseding release. That asymmetry shapes everything from packaging through distribution below.

## When to Use This Skill

- Releasing an Electron desktop app (Windows / macOS / Linux)
- Releasing an Electron + Python hybrid (bundled interpreter or sidecar)
- Any build whose output is a **signed installer that runs on an end user's machine**

## Target Agents

- `devops-engineer` — Primary pipeline operator
- `qa-engineer` — Packaged-binary, first-run, offline, and clean-VM validation
- `cyber-sentinel` — Code signing, notarization, and supply chain verification
- `chief-operations-orchestrator` — Release coordination
- `documentation-specialist` — Project and Claude doc updates

## Configuration

These environment variables are assumed throughout. Set them per app before
running the chain — never hardcode one app's values into a shared skill.

| Var | Meaning | Example |
|-----|---------|---------|
| `BACKUP_ROOT` | Where Step 1 writes the failsafe bundle. Defaults to `$HOME/.backups/$(basename $PWD)` | `~/.backups/myapp` |
| `UPDATE_FEED_URL` | Base URL `electron-updater` clients poll for `latest*.yml` | `https://updates.example.com` |
| `CLEAN_VM_WIN` | SSH target for a **fresh** Windows VM used by the Step 11 install smoke. Must have none of the build box's prerequisites installed | `runner@win-clean.local` |
| `CLEAN_VM_MAC` | SSH target for a fresh macOS VM (same purpose) | `runner@mac-clean.local` |
| `CLEAN_VM_LINUX` | SSH target for a fresh Linux VM (same purpose) | `runner@linux-clean.local` |
| `CSC_LINK`, `CSC_KEY_PASSWORD` | Windows/macOS code-signing certificate and its password (Step 8) | — |
| `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID` | Notarization credentials (Step 8) | — |
| `GH_TOKEN` | Token `electron-builder --publish` and `gh release` use | — |

**Why this table exists.** The clean-VM smoke is the only step that can catch a
missing runtime dependency before users do, and it is worthless if it runs
against the build box. `CLEAN_VM_*` must point at machines that have never
built this app.

## Stack Detection

Routes here when any of these are present:

```bash
[ -f "electron-builder.yml" ] || [ -f "electron-builder.json" ] && echo "DESKTOP"
[ -f "electron.vite.config.ts" ] || [ -f "electron.vite.config.js" ] && echo "DESKTOP"
grep -qs '"electron"' package.json && echo "DESKTOP"
[ -f "forge.config.js" ] && echo "DESKTOP"
[ -f "tauri.conf.json" ] && echo "DESKTOP (Tauri — adapt the compile step)"
```

## Pipeline Overview

Seven phases, sixteen steps (0–15). Same safety contract as any release chain: nothing is deleted before it is backed up, nothing ships before it is verified, and nothing is reclaimed before the release is confirmed healthy.

```
Phase 0 — SAFEGUARD
  Step 0:  Preflight
  Step 1:  Failsafe Backup & Retention Proof (code + local state + previous release artifacts)

Phase 1 — VERIFY
  Step 2:  Quality Gate            → /pipeline-quality (Steps 0–14; simplify + review included) + desktop additions

Phase 2 — INTEGRATE
  Step 3:  Version Bump
  Step 4:  Commit
  Step 5:  Merge to main (post-rebase gate re-run)
  Step 6:  Push to GitHub

Phase 3 — BUILD & RELEASE
  Step 7:  Local Compilation (native module rebuilds against the Electron ABI, Python sidecar freeze)
  Step 8:  Package & Sign (per-platform installers, code signing, notarization)
  Step 9:  Packaged-Artifact Validation (integrity, launch smoke, packaged E2E, first-run/offline, cross-platform matrix)
  Step 10: Release Version

Phase 4 — SHIP
  Step 11: Distribution & Auto-Update (staged publish + clean-VM install smoke)
  Step 12: Post-Publish Verification & Rollback Gate

Phase 5 — DOCUMENT
  Step 13: Documentation (project docs, then Claude docs)

Phase 6 — RECLAIM
  Step 14: Purge CPU-Eating Workers (local only)
  Step 15: Cleanup — local, app-scoped (backup retention enforced)
```

## Versioning Scheme

CalVer: `vYYYY.MM.DD`. `package.json` stores `2026.04.04`; the git tag is `v2026.04.04`. A same-day re-release appends a suffix: `v2026.04.04.2`. This is a valid semver-shaped version (`major.minor.patch`), which is what `electron-updater` requires to compare releases and decide whether a client should update.

## Block Preamble — every fenced block is a separate shell

Nothing assigned in one fenced block is in scope in the next: each block is
executed as its own shell. A block that consumes `STAMP`, `new`, `current`,
`BRANCH` or `BACKUP_ROOT` **must re-derive it at the top**, or it silently runs
with an empty value — `git log "v..v"` kills CHANGELOG generation, and `cd ""`
is a no-op returning 0 that leaves a destructive block running in the project
directory, deleting `repo-*.bundle` there and then reporting `FAILSAFE
VIOLATED` on a perfectly healthy backup set.

Copy the lines you need:

```bash
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.backups/$(basename "$PWD")}"
STAMP=$(ls -t "$BACKUP_ROOT"/repo-*.bundle 2>/dev/null | head -1 | sed -E 's/.*repo-(.*)\.bundle$/\1/')
new=$(node -p "require('./package.json').version")          # post-Step 3
current=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')   # pre-tag
# after Step 10 has tagged v$new, `current` is the tag BEFORE it:
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

# 2. Untracked-but-needed local state (env files, local config, signing
#    entitlements) — never committed
tar -czf "$BACKUP_ROOT/local-state-$STAMP.tar.gz" \
  $(git ls-files --others --exclude-standard | grep -E '\.env|config/local' || true) 2>/dev/null || true

# 3. Previously published artifacts — there is no VPS and no remote database
#    to dump in this path. What desktop needs preserved instead is the
#    PRIOR release's installers: they are the only thing a feed halt
#    (Step 12) can point at when it stops further installs, so losing them
#    removes even that partial mitigation.
PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$PREV_TAG" ]; then
  gh release download "$PREV_TAG" --dir "$BACKUP_ROOT/prev-release-$STAMP" --clobber \
    || echo "WARNING: could not fetch previous release artifacts — recorded, does not block"
fi
```

**Retention rule — the failsafe invariant:**

> At least **one** verified backup must exist at all times. Cleanup (Step 15) prunes *older* backups only, and only after confirming a newer verified one is present. If exactly one backup exists, it is never deleted, regardless of age.

```bash
BACKUP_COUNT=$(find "$BACKUP_ROOT" -name 'repo-*.bundle' | wc -l)
[ "$BACKUP_COUNT" -ge 1 ] || { echo "ABORT: no verified backup present"; exit 1; }
echo "Failsafe OK: $BACKUP_COUNT backup(s), newest repo-$STAMP.bundle (verified)"
```

**Gate rule:** a failed `git bundle verify` or an unwritable `$BACKUP_ROOT` **halts the pipeline**. Never proceed to Phase 4 or 6 on an unverified backup.

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

### Desktop additions to the quality gate

Electron and a Python sidecar carry failure modes the universal gate has no reason to know about. These run on top of Step 2 above, not instead of it.

```bash
# Build config must be valid BEFORE a 3-minute package run discovers it isn't
npx electron-builder --config electron-builder.yml --dir --publish never

# Full type check across BOTH processes — main and renderer have different
# tsconfigs and different globals; checking one hides errors in the other
npx tsc -p tsconfig.node.json --noEmit      # main process
npx tsc -p tsconfig.web.json  --noEmit      # renderer

# Renderer security posture: these three settings are the difference between
# a sandboxed renderer and arbitrary code execution from remote content
grep -rn "nodeIntegration\s*:\s*true"      src/ && echo "BLOCK: nodeIntegration enabled"
grep -rn "contextIsolation\s*:\s*false"    src/ && echo "BLOCK: contextIsolation disabled"
grep -rn "webSecurity\s*:\s*false"         src/ && echo "BLOCK: webSecurity disabled"

# Python side of a hybrid
[ -f "pyproject.toml" ] && ruff check . && mypy . && pytest -x --tb=short
```

**Gate rule:** `nodeIntegration: true`, `contextIsolation: false`, or `webSecurity: false` in a production build blocks the release. These are the top three Electron RCE vectors and no packaging step will catch them.

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

## Step 7: Local Compilation

Desktop compilation is genuinely local and multi-target. Native modules are compiled against **Electron's V8 ABI, not the system Node's** — mismatched ABI is the single most common cause of "works in dev, crashes in the packaged app."

```bash
set -euo pipefail

# ── TypeScript: main + preload + renderer ───────────────────────────────────
npx tsc -p tsconfig.node.json          # main process
npx tsc -p tsconfig.web.json           # renderer
npm run build || npx electron-vite build

# ── Native modules: rebuild against the Electron ABI ────────────────────────
ELECTRON_VER=$(node -p "require('electron/package.json').version")
echo "Electron $ELECTRON_VER — ABI $(node -p "process.versions.modules")"
npx electron-rebuild -f -w .                  # or: npm rebuild --runtime=electron

# Verify each .node binary actually loads under Electron, not just under Node
find . -name '*.node' -not -path './node_modules/.cache/*' | while read -r m; do
  npx electron -e "try{require('$PWD/$m');console.log('OK  $m')}catch(e){console.error('FAIL $m',e.message);process.exit(1)}" \
    || { echo "ABORT: native module fails under Electron ABI"; exit 1; }
done

# ── Python sidecar / bundled interpreter (hybrid apps) ──────────────────────
if [ -f "pyproject.toml" ]; then
  python -m build
  # Freeze to a standalone binary so the user needs no Python installed
  pyinstaller --onefile --noconfirm backend/main.py --distpath dist/python
  ./dist/python/main --version || { echo "ABORT: frozen Python binary won't run"; exit 1; }
fi
```

**Gate rule:** every `.node` native module must load under the Electron runtime, and any frozen Python binary must execute standalone. Both fail *silently* in dev — where the system Node and a system Python are available — and only surface on a clean end-user machine.

## Step 8: Package & Sign

```bash
# ── Package per platform ────────────────────────────────────────────────────
npx electron-builder --win   --config electron-builder.yml --publish never   # NSIS / MSI
npx electron-builder --mac   --config electron-builder.yml --publish never   # DMG / PKG
npx electron-builder --linux --config electron-builder.yml --publish never   # AppImage / deb / rpm

# ── Code signing: unsigned desktop builds are quarantined or blocked ────────
# Windows — signtool, EV or OV certificate
signtool verify /pa /v dist/*.exe \
  || { echo "ABORT: Windows binary is unsigned or signature invalid"; exit 1; }

# macOS — signature, then hardened runtime, then notarization staple
codesign --verify --deep --strict --verbose=2 "dist/mac/App.app" \
  || { echo "ABORT: macOS signature invalid"; exit 1; }
codesign -d --entitlements - "dist/mac/App.app" | grep -q 'hardened-runtime' \
  || echo "WARNING: hardened runtime not enabled — notarization will reject"
xcrun stapler validate "dist/App.dmg" \
  || { echo "ABORT: notarization ticket not stapled — Gatekeeper will block"; exit 1; }

# Linux — detached signature for the AppImage
gpg --detach-sign --armor dist/*.AppImage

# ── Checksums travel with the release ───────────────────────────────────────
( cd dist && sha256sum * > SHA256SUMS && gpg --detach-sign --armor SHA256SUMS )
```

**Gate rule:** an unsigned or unnotarized artifact never ships. Windows SmartScreen and macOS Gatekeeper will block it on the user's machine, and by then the release is already public.

## Step 9: Packaged-Artifact Validation

The step with no cloud equivalent. Everything so far validated *source*; this validates the **artifact a user actually downloads**. Dev-mode passing tells you nothing here — packaging changes module resolution, asset paths, and process privileges.

### 9a — Installer integrity

```bash
# Size sanity: a sudden 3x jump means dev dependencies or source maps leaked in
for f in dist/*.exe dist/*.dmg dist/*.AppImage; do
  [ -e "$f" ] || continue
  printf '%s %s MB\n' "$f" "$(( $(stat -c%s "$f") / 1048576 ))"
done

# Confirm secrets and sources did not get bundled
npx asar list dist/win-unpacked/resources/app.asar | grep -iE '\.env|\.pem|\.key|/test/|\.map$' \
  && echo "BLOCK: sensitive or dev files inside the package"

# Confirm the app.asar is actually there and readable
npx asar extract-file dist/win-unpacked/resources/app.asar package.json >/dev/null \
  || { echo "ABORT: app.asar unreadable"; exit 1; }
```

### 9b — Launch smoke test and packaged E2E

Desktop runs E2E **twice, against two different artifacts, deliberately**:

| Run | Artifact | Catches |
|-----|----------|---------|
| `/pipeline-quality` Step 7 | Dev build | Logic regressions, fast and cheap |
| This step (9b) | Signed, packaged binary | Missing runtime deps, broken asar paths, native modules that load under Node but not under Electron |

Ordering makes this unavoidable: the quality gate (Step 2) runs before packaging exists, so it cannot test a binary that has not been built yet. The second run is not redundancy — the failures it catches appear nowhere else, and they appear only on a machine that is not the developer's.

```bash
# Launch the BUILT app headless and assert it reaches ready state.
# This catches missing runtime deps, broken asar paths, and native module
# failures that every source-level test suite passes straight over.
xvfb-run -a ./dist/linux-unpacked/app --smoke-test --exit-after-ready \
  || { echo "ABORT: packaged binary fails to launch"; exit 1; }

# End-to-end against the packaged build, not the dev server
npx playwright test --config=e2e/packaged.config.ts
```

### 9c — First-run and offline behavior

```bash
# First run on a machine with no prior state — clean profile, no config,
# no cached credentials. Where "works on my machine" goes to die.
rm -rf "$HOME/.config/YourApp" "$HOME/.local/share/YourApp"
xvfb-run -a ./dist/linux-unpacked/app --smoke-test --first-run

# Offline start: desktop apps must degrade, not hang on a network call
# (run with network namespace disabled, or a blocked egress firewall rule)
unshare -rn ./dist/linux-unpacked/app --smoke-test --offline \
  || echo "WARNING: app does not start cleanly without network"
```

### 9d — Cross-platform matrix

| Platform | Minimum target | Validate |
|----------|---------------|----------|
| Windows | 10 x64, 11 ARM64 | Installer runs unelevated; uninstaller removes cleanly; SmartScreen reputation |
| macOS | 12 Monterey, Intel + Apple Silicon | Universal binary (`lipo -info`); Gatekeeper allows on first open |
| Linux | Ubuntu 22.04, Fedora latest | AppImage runs without FUSE prompt; `.deb` dependency graph resolves |

```bash
lipo -info "dist/mac/App.app/Contents/MacOS/App"   # expect: x86_64 arm64
dpkg-deb --info dist/*.deb | grep Depends
```

**Gate rule:** the packaged binary must launch, reach ready state, survive a clean first run, and start without network. Any platform in the shipping matrix that fails blocks that platform's artifact — ship the ones that pass and say plainly which were held back.

## Step 10: Release Version

Tag only a commit that already passed packaged-artifact validation above — that ordering is what makes the release trustworthy.

```bash
new=$(node -p "require('./package.json').version")   # re-derived: separate shell

git tag -a "v$new" -m "Release v$new"
git push origin "v$new"
gh release create "v$new" --title "v$new" --generate-notes \
  dist/*.exe dist/*.dmg dist/*.AppImage dist/*.deb dist/*.rpm dist/SHA256SUMS dist/SHA256SUMS.asc
```

**Gate rule:** tag only a commit that is already on `origin/main` and green through Steps 7–9. Tagging local or unvalidated work — or a build that failed any platform in the Step 9d matrix — produces a release nobody else can reproduce, or ships a platform that was supposed to be held back.

---

# Phase 4 — SHIP

## Step 11: Distribution & Auto-Update

"Production" for desktop is the **distribution channel** — the update feed and store listings clients pull from, not a server you operate.

**Security precondition.** Before shipping, state the quality gate's step 4 outcome explicitly — Semgrep, `/security-review`, and `security-guidance` readiness, each as PASS or NOT RUN. An unresolved High finding blocks the release outright. A `NOT RUN` does not block, but it must be named in the release record: shipping past an absent check is a decision someone should make on purpose rather than inherit from a quiet log. A desktop release cannot be recalled — once the update feed serves it, the only remedy is another release.

```bash
set -euo pipefail
new=$(node -p "require('./package.json').version")   # re-derived: separate shell
UPDATE_FEED_URL="${UPDATE_FEED_URL:?set UPDATE_FEED_URL before publishing}"

# Publish artifacts and the update metadata
npx electron-builder --publish always

# ── Verify the update feed BEFORE announcing ────────────────────────────────
for f in latest.yml latest-mac.yml latest-linux.yml; do
  curl -fsSL "$UPDATE_FEED_URL/$f" | grep -q "$new" \
    || { echo "ABORT: $f does not serve v$new"; exit 1; }
done

# The feed's declared checksum must match the published artifact, or every
# client will download and then reject the update
FEED_SHA=$(curl -fsSL https://updates.example.com/latest.yml | grep -oP 'sha512:\s*\K\S+')
LOCAL_SHA=$(openssl dgst -sha512 -binary dist/*.exe | openssl base64 -A)
[ "$FEED_SHA" = "$LOCAL_SHA" ] || { echo "ABORT: feed checksum mismatch"; exit 1; }

# ── Staged rollout: the only mitigation available, because nothing shipped
#    here can be pulled back server-side once a client has installed it (see
#    Step 12). Serve to a percentage first, watch crash telemetry, then
#    widen — this bounds how many machines are exposed before a bad build
#    is caught. electron-updater honours `stagingPercentage` in latest.yml.
sed -i 's/^stagingPercentage:.*/stagingPercentage: 10/' dist/latest.yml

# ── Clean-VM install smoke — a fresh machine, not the build box ─────────────
# The build box already has every prerequisite installed; a fresh VM does
# not. This is the last chance to catch missing runtime dependencies
# (VC++ redistributables, WebView2, system libs) before real users do.
[ -n "${CLEAN_VM_WIN:-}" ] || { echo "ABORT: CLEAN_VM_WIN unset — the install smoke would run on the build box"; exit 1; }
ssh "$CLEAN_VM_WIN" 'powershell -c "Start-Process -Wait dist\app-setup.exe /S"'
ssh "$CLEAN_VM_WIN" 'powershell -c "& \"C:\Program Files\App\app.exe\" --smoke-test --exit-after-ready"' \
  || { echo "ABORT: clean-VM install smoke failed"; exit 1; }

# ── Store channels (submission, not instant release) ────────────────────────
# Microsoft Store:  msstore submit dist/*.msix
# Mac App Store:    xcrun altool --upload-app -f dist/App.pkg
# Snap:             snapcraft upload dist/*.snap --release=stable
# Homebrew cask / winget: open the manifest PR
```

**Gate rule:** the clean-VM install smoke must pass before the staged percentage is ever widened past its initial value. Never delete the previous release's artifacts — Step 12's only mitigation depends on them still being retrievable.

## Step 12: Post-Publish Verification & Rollback Gate

Cloud verifies a live endpoint and can roll back in one command. Desktop has neither: verification is **telemetry-based and lags by hours**, because it depends on users actually pulling the update, and there is **no server-side rollback** — once `electron-updater` installs a build on a client machine, that machine runs it until another update arrives. Halting the feed below stops *new* installs only; it cannot undo ones that already happened. That asymmetry is exactly why Step 11 staged the rollout at 10% instead of publishing to everyone at once: staging bounds the blast radius to whoever already installed by the time a problem surfaces, and the only real fix beyond that is shipping a superseding release.

```bash
# Crash-free session rate against the pre-release baseline (Sentry/Crashpad)
# A desktop regression shows up as a crash rate delta, not a failing health check.

# Update adoption: is the feed reaching clients at all?
new=$(node -p "require('./package.json').version")   # re-derived: separate shell
curl -fsSL "${UPDATE_FEED_URL:?}/metrics" | grep "$new"
```

| Signal | Healthy | Act |
|--------|---------|-----|
| Crash-free sessions | ≥ pre-release baseline | Drop >1% → halt the feed at current percentage, do not widen |
| Update adoption (24h) | rising | Flat → feed or signature problem, not user behavior |
| First-run failures | ~0 | Spike → packaging regression, halt the feed |

**Halt the feed** (stops new pulls only — already-updated clients are unaffected):

```bash
new=$(node -p "require('./package.json').version")   # re-derived: separate shell
sed -i 's/^stagingPercentage:.*/stagingPercentage: 0/' dist/latest.yml
gh release edit "v$new" --prerelease     # de-list without deleting artifacts
```

**Gate rule:** hold the staged rollout at its initial percentage for at least one full telemetry cycle before widening. If crash-free sessions regress at any point, halt rather than widen and prepare a superseding release — do not attempt to "roll back" a client that has already updated. Phases 5 and 6 do not run on a failed rollout.

---

# Phase 5 — DOCUMENT

## Step 13: Documentation

Written while the release context is fresh, and before anything is cleaned up.

### 13a — Project Documents

| Document | Update |
|----------|--------|
| `CHANGELOG.md` | New `## v$new — YYYY-MM-DD` section: Added / Changed / Fixed / Removed / Security |
| `README.md` | Version badge, install commands, any changed prerequisites |
| `docs/**/*.md` | Behavior that changed this release; delete instructions for removed features |
| `MIGRATION.md` | Required steps for breaking changes |
| `PLAN.md` | Tick off shipped items; carry the 🟡/🟢 review follow-ups forward |

```bash
# Re-derived: separate shell. By this step v$new is already tagged (Step 10),
# so `new` is the newest tag and `current` is the one before it. An empty
# `$current` would produce `git log "v..v$new"` and kill CHANGELOG generation.
# `git tag --sort=-creatordate | sed -n 2p` is not reliable — lightweight tags
# sort by commit date and tie on same-second commits.
new=$(node -p "require('./package.json').version")
current=$(git describe --tags --abbrev=0 "v$new^" 2>/dev/null | sed 's/^v//')
[ -n "$new" ] || { echo "ABORT: cannot read version from package.json"; exit 1; }
if [ -n "$current" ]; then RANGE="v$current..v$new"; else RANGE="v$new"; fi

{ echo "## v$new - $(date +%Y-%m-%d)"; echo; git log "$RANGE" --pretty='- %s' --no-merges; echo; cat CHANGELOG.md; } > CHANGELOG.tmp && mv CHANGELOG.tmp CHANGELOG.md
if [ -n "$current" ]; then grep -rn "$current" --include='*.md' . | grep -v CHANGELOG.md || true; fi
```

**Gate rule:** no doc may describe behavior this release removed.

### 13b — Claude Docs

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

## Step 14: Purge CPU-Eating Workers (local only)

```bash
# Scope by WORKING DIRECTORY. A CPU threshold alone lists sibling projects'
# processes, and "kill by PID" on that list kills someone else's work.
proc_cwd() {   # pid -> working directory (Linux /proc, macOS lsof fallback)
  readlink -e "/proc/$1/cwd" 2>/dev/null \
    || lsof -a -p "$1" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -1
}

PROJ=$(pwd -P)
ps -eo pid,pcpu,args --sort=-pcpu | awk 'NR>1 && $2>50 {print $1}' | while read -r pid; do
  cwd=$(proc_cwd "$pid"); [ -n "$cwd" ] || continue
  case "$cwd" in "$PROJ"|"$PROJ"/*) ps -p "$pid" -o pid=,pcpu=,args= ;; esac
done | head -20
```

**Gate rule:** identify, then kill by PID. Every PID the block prints has its
working directory inside this project — that scoping is what makes "kill by
PID" safe on a machine running sibling projects. There is no VPS in this path — nothing here reaches beyond the build machine.

## Step 15: Cleanup — local, app-scoped

Runs **only** after Step 12 confirms the staged rollout is healthy through at least one telemetry cycle. Everything here is local — there is no VPS to clean in this path — and the failsafe invariant is re-proved before a single deletion.

```bash
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.backups/$(basename "$PWD")}"   # re-derived: separate shell
[ -d "$BACKUP_ROOT" ] || { echo "ABORT: BACKUP_ROOT '$BACKUP_ROOT' is not a directory"; exit 1; }

# ── Precondition: the failsafe must still hold ───────────────────────────────
BACKUPS=$(find "$BACKUP_ROOT" -name 'repo-*.bundle' | wc -l)
[ "$BACKUPS" -ge 1 ] || { echo "ABORT: cleanup would leave zero backups"; exit 1; }
git bundle verify "$(ls -t "$BACKUP_ROOT"/repo-*.bundle | head -1)" >/dev/null \
  || { echo "ABORT: newest backup fails verification"; exit 1; }

# ── Build caches: safe, regenerable on the next compile ──────────────────────
rm -rf node_modules/.cache dist/win-unpacked dist/mac dist/linux-unpacked

# ── dist/ artifacts: keep the current release AND the previous one ───────────
# The previous release is what a feed halt (Step 12) leaves clients on —
# deleting it removes that mitigation.
new=$(node -p "require('./package.json').version")   # re-derived: separate shell
[ -n "$new" ] || { echo "ABORT: cannot read version — refusing to prune dist/"; exit 1; }
prev=$(git describe --tags --abbrev=0 "v$new^" 2>/dev/null | sed 's/^v//')
KEEP_VERSIONS="$new${prev:+ $prev}"
find dist -maxdepth 1 -type f \( -name '*.exe' -o -name '*.dmg' -o -name '*.AppImage' -o -name '*.deb' -o -name '*.rpm' -o -name '*.msi' \) \
  | while read -r f; do
      keep=false
      for v in $KEEP_VERSIONS; do [[ "$f" == *"$v"* ]] && keep=true; done
      $keep || { echo "removing superseded artifact: $f"; rm -f "$f"; }
    done
```

**Never** delete the current or previous release's signed artifacts, and never prune below the last remaining backup — Step 12's feed halt depends on the previous release still existing, and the failsafe invariant depends on the last backup.

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

**Gate rule:** cleanup deletes only regenerable build caches, surplus backups, and this app's own superseded local artifacts. It never touches the current release, the previous release, or the last remaining backup.

---

## Output Format

```markdown
## Desktop Build Report - v[version]

| Step | Status | Duration | Details |
|------|--------|----------|---------|
| 0 Preflight | PASS | 2s | clean tree, up to date with origin/main |
| 1 Failsafe Backup | DONE | 12s | repo bundle + local state + prev release artifacts verified |
| 2 Quality Gate | PASS | 210s | /pipeline-quality Steps 0–14 clean; Electron additions clean |
| 3 Version Bump | DONE | 1s | v2026.07.25 -> v2026.07.26 |
| 4 Commit | DONE | 3s | abc1234 release: v2026.07.26 |
| 5 Merge to main | PASS | 30s | --no-ff; gate re-run post-rebase |
| 6 Push to GitHub | DONE | 5s | origin/main == HEAD verified |
| 7 Local Compile | PASS | 95s | tsc main+renderer; 3 native modules rebuilt (ABI 125); Python frozen |
| 8 Package & Sign | PASS | 180s | win/mac/linux; signed + notarized + stapled |
| 9a Integrity | PASS | 10s | 85MB / 92MB / 88MB; no dev files in asar |
| 9b Launch Smoke + Packaged E2E | PASS | 40s | packaged binary reached ready; e2e/packaged.config.ts green |
| 9c First-run/Offline | PASS | 30s | clean profile OK; offline start OK |
| 9d Matrix | PARTIAL | 60s | win/mac OK; linux ARM64 held back (see below) |
| 10 Release Version | DONE | 5s | v2026.07.26 tagged and pushed |
| 11 Distribution | DONE | 60s | feed serves v2026.07.26, checksum match, clean-VM smoke OK, rollout 10% |
| 12 Post-Publish Verify | PASS | 900s | crash-free sessions nominal, adoption rising |
| 13 Documentation | DONE | 25s | CHANGELOG, README, CLAUDE.md updated |
| 14 Worker Purge | DONE | 5s | 0 stale local workers |
| 15 Cleanup | DONE | 20s | build caches cleared, 2 surplus backups pruned, current+previous artifacts retained |

### Artifacts
- `dist/app-2026.07.26-setup.exe` (85MB) — signed, SHA256SUMS.asc
- `dist/app-2026.07.26.dmg` (92MB) — notarized + stapled
- `dist/app-2026.07.26.AppImage` (88MB) — GPG detached signature

### Held Back
- linux ARM64: native module `better-sqlite3` has no prebuilt ARM binary

### Rollback
- No server-side rollback. Staged at 10%; feed can be halted (Step 12) to stop further installs, but already-updated clients require a superseding release.
- Previous release v[prev] artifacts retained for that purpose.
```

## Relationship to Other Skills

| Skill | Role |
|-------|------|
| `/pipeline-quality` | Step 2 gate — deterministic checks plus simplify/review; this skill adds Electron/Python-specific checks on top |
| `/pipeline-full-build-cloud` | Sibling — same phase order; its Steps 7–10 diverge (container build, SBOM/CVE gate, staging validation, release, deploy, post-deploy rollback gate) where this skill's Steps 7–12 do the packaged-binary equivalent |
