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

check() {  # label, actual, expected
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
