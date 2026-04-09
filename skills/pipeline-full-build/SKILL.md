---
name: pipeline-full-build
description: Universal full build pipeline - version bump, quality gate, build, compile, package, CI, and release. Desktop and cloud variants.
---

# Pipeline Full Build

End-to-end build pipeline from version bump to release. Runs the quality gate first, then proceeds through build, packaging, and release steps.

## When to Use This Skill

- Preparing a release build
- Running the full CI/CD pipeline locally
- Before tagging a version or creating a GitHub release
- After completing a milestone or sprint

## Target Agents

- `devops-engineer` - Primary pipeline operator
- `chief-operations-orchestrator` - Release coordination
- `code-reviewer` - Pre-release quality gate
- `cyber-sentinel` - Pre-release security scan

## Pipeline Overview

```
Step 1: Version Bump
Step 2: Quality Gate (/pipeline-quality)
Step 3: Build
Step 4: Compile / Bundle
Step 5: Package
Step 6: CI Validation
Step 7: Release
Step 8: Post-Release
```

## Versioning Scheme

This project uses **Calendar Versioning (CalVer)**: `vYYYY.MM.DD`

- Version is the release date: `v2026.04.04`
- Multiple releases on the same day: append a suffix: `v2026.04.04.2`
- `package.json` version field stores: `2026.04.04`
- Git tags use: `v2026.04.04`

## Desktop Variant (Electron + Python)

### Step 1: Version Bump

```bash
# CalVer: version = today's date
current=$(node -p "require('./package.json').version")
new=$(date +%Y.%m.%d)
echo "Current version: $current -> New version: $new"

# Update package.json
npm version "$new" --no-git-tag-version --allow-same-version

# Sync Python version if hybrid
[ -f "pyproject.toml" ] && sed -i "s/version = \".*\"/version = \"$new\"/" pyproject.toml
```

### Step 2: Quality Gate

Run the full quality gate pipeline:

```
/pipeline-quality
```

All checks must pass before proceeding.

### Step 3: Build

```bash
# TypeScript compilation
npx tsc

# Electron main + renderer build
npm run build
# Or: npx electron-vite build

# Python backend (if hybrid)
[ -f "pyproject.toml" ] && python -m build
```

### Step 4: Compile

```bash
# Bundle with electron-builder
npx electron-builder --config electron-builder.yml

# Verify output
ls -la dist/
```

### Step 5: Package

```bash
# Platform-specific packaging
# Windows: NSIS installer
npx electron-builder --win --config electron-builder.yml

# macOS: DMG
npx electron-builder --mac --config electron-builder.yml

# Linux: AppImage/deb
npx electron-builder --linux --config electron-builder.yml
```

### Step 6: CI Validation

```bash
# Verify package integrity
[ -f "dist/*.exe" ] && echo "Windows package: OK"
[ -f "dist/*.dmg" ] && echo "macOS package: OK"
[ -f "dist/*.AppImage" ] && echo "Linux package: OK"

# Smoke test (if applicable)
# npx electron dist/app --smoke-test
```

### Step 7: Release

```bash
# Git tag
git add -A
git commit -m "release: v$new"
git tag -a "v$new" -m "Release v$new"
git push origin main --tags

# GitHub release
gh release create "v$new" \
  --title "v$new" \
  --notes "$(cat <<'EOF'
## What's Changed
- [Changes from CHANGELOG.md]

**Full Changelog**: https://github.com/OWNER/REPO/compare/v$current...v$new
EOF
)" \
  dist/*.exe dist/*.dmg dist/*.AppImage 2>/dev/null || true
```

### Step 8: Post-Release

```bash
# Update CHANGELOG.md
echo "## v$new - $(date +%Y-%m-%d)" >> CHANGELOG.md

# Bump to next dev version
npm version prepatch --no-git-tag-version --preid=dev
```

## Cloud Variant (Web/API)

### Step 1: Version Bump

```bash
# CalVer: version = today's date
current=$(node -p "require('./package.json').version")
new=$(date +%Y.%m.%d)
echo "Current version: $current -> New version: $new"
npm version "$new" --no-git-tag-version --allow-same-version
```

### Step 2: Quality Gate

```
/pipeline-quality
```

### Step 3: Build

```bash
# Frontend
npm run build || npx vite build

# Backend
[ -f "pyproject.toml" ] && python -m build
[ -f "go.mod" ] && go build ./...
[ -f "Cargo.toml" ] && cargo build --release
```

### Step 4: Docker Build

```bash
# Build container image
docker build -t app:$new .

# Multi-stage build verification
docker images app:$new --format "{{.Size}}"

# Security scan the image
docker scout cves app:$new 2>/dev/null || trivy image app:$new
```

### Step 5: Deploy

```bash
# Push to registry
docker tag app:$new registry.example.com/app:$new
docker push registry.example.com/app:$new

# Kubernetes deployment
[ -d "k8s/" ] && kubectl set image deployment/app app=registry.example.com/app:$new

# Or Terraform
[ -d "terraform/" ] && cd terraform && terraform apply -auto-approve
```

### Step 6: CI Validation

```bash
# Health check
curl -f http://localhost:8080/health || exit 1

# Smoke tests
npm run test:smoke || pytest tests/smoke/
```

### Step 7: Release

```bash
# Git operations (same as desktop)
git tag -a "v$new" -m "Release v$new"
git push origin main --tags
gh release create "v$new" --title "v$new" --generate-notes
```

### Step 8: Post-Release

```bash
# Notify (Slack, email, etc.)
# Monitor dashboards for errors
# Update status page
```

## Output Format

```markdown
## Full Build Report - v[version]

| Step | Status | Duration | Details |
|------|--------|----------|---------|
| Version Bump | DONE | 2s | v1.2.3 -> v1.2.4 |
| Quality Gate | PASS | 45s | All 6 checks passed |
| Build | PASS | 30s | TypeScript + Vite compiled |
| Compile | PASS | 120s | electron-builder completed |
| Package | PASS | 90s | Windows NSIS installer (85MB) |
| CI Validation | PASS | 15s | Package integrity verified |
| Release | DONE | 10s | GitHub release v1.2.4 created |
| Post-Release | DONE | 5s | CHANGELOG updated |

### Artifacts
- `dist/app-1.2.4-setup.exe` (85MB)
- `dist/app-1.2.4.dmg` (92MB)
- GitHub Release: https://github.com/owner/repo/releases/tag/v1.2.4

### Total Pipeline Duration: 5m 17s
```

## CI/CD Template (GitHub Actions)

```yaml
name: Full Build
on:
  push:
    tags: ['v*']

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Quality Gate
        run: |  # Lint + Semgrep + Tests + Audit
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
```
