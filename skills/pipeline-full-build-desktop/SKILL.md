---
name: pipeline-full-build-desktop
description: Desktop release variant for Electron + Python apps - local compilation including native module rebuilds against the Electron ABI, code signing and notarization, installer integrity validation, packaged-binary launch smoke tests, offline/first-run testing, and auto-update feed verification. Supplies Phase 3 and Step 12 of pipeline-full-build.
---

# Pipeline Full Build — Desktop Variant

The **desktop** half of `/pipeline-full-build`. Supplies the build, test, validation, and distribution steps for Electron (and Electron + Python hybrid) applications.

Desktop and cloud diverge far more than the shared spine suggests. A cloud build produces one artifact that runs on infrastructure you control; a desktop build produces **N platform-specific artifacts that run on machines you do not control**, each needing its own compilation, signing, and launch validation. That difference is concentrated in the steps below.

## Division of Labor

| Skill | Owns |
|-------|------|
| `pipeline-full-build` | The shared spine — Steps 0–7, 11, 13–16 (backup, verify, integrate, release, docs, reclaim) |
| **`pipeline-full-build-desktop`** (this) | **Steps 8–10 and 12 for Electron/desktop, plus the desktop-specific gate additions** |
| `pipeline-full-build-cloud` | The same steps for containerized web/API targets |

Invoke `/pipeline-full-build` and it routes here on stack detection. Invoke this directly when you already know the target is desktop.

## When to Use This Skill

- Releasing an Electron desktop app (Windows / macOS / Linux)
- Releasing an Electron + Python hybrid (bundled interpreter or sidecar)
- Any build whose output is a **signed installer that runs on an end user's machine**

## Target Agents

- `devops-engineer` - Primary pipeline operator
- `qa-engineer` - Packaged-binary and first-run validation
- `cyber-sentinel` - Code signing and supply chain verification
- `chief-operations-orchestrator` - Release coordination

## Stack Detection

Routes here when any of these are present:

```bash
[ -f "electron-builder.yml" ] || [ -f "electron-builder.json" ] && echo "DESKTOP"
[ -f "electron.vite.config.ts" ] || [ -f "electron.vite.config.js" ] && echo "DESKTOP"
grep -qs '"electron"' package.json && echo "DESKTOP"
[ -f "forge.config.js" ] && echo "DESKTOP"
[ -f "tauri.conf.json" ] && echo "DESKTOP (Tauri — adapt the compile step)"
```

---

## Desktop Additions to Step 1 (Quality Gate)

`/pipeline-quality` runs the universal gate. Desktop adds checks that only matter when code ships to someone else's machine:

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

# Phase 3 — BUILD (desktop)

## Step 8: Local Compilation

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

## Step 9: Package & Sign

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

## Step 10: Packaged-Artifact Validation

The step with no cloud equivalent. Everything so far validated *source*; this validates the **artifact a user actually downloads**. Dev-mode passing tells you nothing here — packaging changes module resolution, asset paths, and process privileges.

### 10a — Installer integrity

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

### 10b — Launch smoke test of the packaged binary

```bash
# Launch the BUILT app headless and assert it reaches ready state.
# This catches missing runtime deps, broken asar paths, and native module
# failures that every source-level test suite passes straight over.
xvfb-run -a ./dist/linux-unpacked/app --smoke-test --exit-after-ready \
  || { echo "ABORT: packaged binary fails to launch"; exit 1; }

# End-to-end against the packaged build, not the dev server
npx playwright test --config=e2e/packaged.config.ts
```

### 10c — First-run and offline behavior

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

### 10d — Cross-platform matrix

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

---

# Phase 4 — SHIP (desktop Step 12)

## Step 12: Distribution & Auto-Update

"Production" for desktop is the **distribution channel**. There is no rollout to reverse — once an update feed serves a bad version, clients pull it. That makes staged rollout and feed verification the safety mechanism.

```bash
# Publish artifacts and the update metadata
npx electron-builder --publish always

# ── Verify the update feed BEFORE announcing ────────────────────────────────
for f in latest.yml latest-mac.yml latest-linux.yml; do
  curl -fsSL "https://updates.example.com/$f" | grep -q "$new" \
    || { echo "ABORT: $f does not serve v$new"; exit 1; }
done

# The feed's declared checksum must match the published artifact, or every
# client will download and then reject the update
FEED_SHA=$(curl -fsSL https://updates.example.com/latest.yml | grep -oP 'sha512:\s*\K\S+')
LOCAL_SHA=$(openssl dgst -sha512 -binary dist/*.exe | openssl base64 -A)
[ "$FEED_SHA" = "$LOCAL_SHA" ] || { echo "ABORT: feed checksum mismatch"; exit 1; }

# ── Staged rollout: desktop's only real rollback ────────────────────────────
# Serve to a percentage first, watch crash telemetry, then widen.
# electron-updater honours a `stagingPercentage` field in latest.yml
sed -i 's/^stagingPercentage:.*/stagingPercentage: 10/' dist/latest.yml

# ── Store channels (submission, not instant release) ────────────────────────
# Microsoft Store:  msstore submit dist/*.msix
# Mac App Store:    xcrun altool --upload-app -f dist/App.pkg
# Snap:             snapcraft upload dist/*.snap --release=stable
# Homebrew cask / winget: open the manifest PR
```

**Rollback path** — the previous version stays published so the feed can be reverted:

```bash
# Revert the feed to the prior release; clients stop pulling the bad build
aws s3 cp "s3://updates/archive/latest-$current.yml" "s3://updates/latest.yml"
gh release edit "v$new" --prerelease     # de-list without deleting artifacts
```

**Gate rule:** never delete the previous release's artifacts — the update feed revert depends on them. This is why `pipeline-full-build` Step 16 keeps the rollback target.

---

## Desktop Additions to Step 13 (Post-Deploy Verification)

Cloud verifies a live endpoint. Desktop has no endpoint — verification is **telemetry-based and lags by hours**, because it depends on users actually updating.

```bash
# Crash-free session rate against the pre-release baseline (Sentry/Crashpad)
# A desktop regression shows up as a crash rate delta, not a failing health check.

# Update adoption: is the feed reaching clients at all?
curl -fsSL https://updates.example.com/metrics | grep "$new"
```

| Signal | Healthy | Act |
|--------|---------|-----|
| Crash-free sessions | ≥ pre-release baseline | Drop >1% → revert feed, halt rollout |
| Update adoption (24h) | rising | Flat → feed or signature problem, not user behavior |
| First-run failures | ~0 | Spike → packaging regression, revert immediately |

**Gate rule:** hold the staged rollout at 10% for at least one full telemetry cycle before widening. Desktop cannot be rolled back from the server side — only the *next* update can fix a bad one, and only for users who still get updates.

---

## Output Format

```markdown
## Desktop Build Report - v[version]

| Step | Status | Duration | Details |
|------|--------|----------|---------|
| 8 Local Compile | PASS | 95s | tsc main+renderer; 3 native modules rebuilt (ABI 125); Python frozen |
| 9 Package & Sign | PASS | 180s | win/mac/linux; signed + notarized + stapled |
| 10a Integrity | PASS | 10s | 85MB / 92MB / 88MB; no dev files in asar |
| 10b Launch Smoke | PASS | 25s | packaged binary reached ready |
| 10c First-run/Offline | PASS | 30s | clean profile OK; offline start OK |
| 10d Matrix | PARTIAL | 60s | win/mac OK; linux ARM64 held back (see below) |
| 12 Distribution | DONE | 45s | feed serves v[x], checksum match, rollout 10% |

### Artifacts
- `dist/app-2026.07.26-setup.exe` (85MB) — signed, SHA256SUMS.asc
- `dist/app-2026.07.26.dmg` (92MB) — notarized + stapled
- `dist/app-2026.07.26.AppImage` (88MB) — GPG detached signature

### Held Back
- linux ARM64: native module `better-sqlite3` has no prebuilt ARM binary

### Rollback
- Previous release v[prev] artifacts retained; feed revert tested
```

## Relationship to Other Skills

| Skill | Role |
|-------|------|
| `/pipeline-full-build` | Parent — owns Steps 0–7, 11, 13–16 and routes here |
| `/pipeline-full-build-cloud` | Sibling — same steps for containerized targets |
| `/pipeline-quality` | Step 1 gate; this skill adds the Electron-specific checks above |
| `/pipeline-review` | Steps 2, 3, 5 — simplify, review, commit |
