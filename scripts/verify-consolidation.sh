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

# AC2 — no live references to the deleted skills (CHANGELOG, specs/plans, and the
# gitignored SDD workspace are records of the work, not references from the product)
refs=$(grep -rln 'pipeline-review\|pipeline-full-build[^-]' \
        --include='*.md' --include='*.json' . 2>/dev/null \
        | grep -v node_modules | grep -v CHANGELOG.md | grep -v docs/superpowers/ \
        | grep -v '\.superpowers/' || true)
[ -z "$refs" ] && note ok "AC2 no live refs to deleted skills" \
  || { note FAIL "AC2 live refs remain in: $(echo "$refs" | tr '\n' ' ')"; fail=1; }

# AC3 — in the two files that discuss nothing but skills and agents, every
# backticked kebab-case name must resolve to a real skill, a real agent, or a
# documented external built-in. Anything else is a phantom reference.
AGENTS=$(grep -rhoE '^name: [a-z0-9-]+' agents/ 2>/dev/null | sed 's/^name: //' | sort -u)
# Template placeholder tokens used as generic examples in docs, not real names.
PLACEHOLDERS='skill-name|agent-name|display-name|default-enabled'
missing=""
for f in CONTRIBUTING.md docs/rules/skills-integration.md; do
  [ -f "$f" ] || continue
  for n in $(grep -ohE '`[a-z0-9]+(-[a-z0-9]+)+`' "$f" | tr -d '`' | sort -u); do
    [ -d "skills/$n" ]                  && continue
    grep -qx "$n" <<<"$AGENTS"          && continue
    grep -qE "^($EXTERNAL)$" <<<"$n"    && continue
    grep -qE "^($PLACEHOLDERS)$" <<<"$n" && continue
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
    case "$n" in *:*) continue ;; esac  # plugin:skill form, not a local skills/ dir
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
