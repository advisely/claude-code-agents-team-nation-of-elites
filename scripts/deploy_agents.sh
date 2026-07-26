#!/usr/bin/env bash
set -euo pipefail

# Nation of Elites - Agents Deployment Script
# End-to-end: clone/pull → sanitize → deploy → validate
#
# Usage:
#   bash scripts/deploy_agents.sh [--repo-url <url>] [--repo-dir <dir>] [--force-wipe]
#
# Defaults:
#   --repo-url  https://github.com/advisely/claude-code-agents-team-nation-of-elites.git
#   --repo-dir  "$HOME/.cache/nation-of-elites"
#
# Notes:
# - Data-safe by design: ~/.claude/projects (Claude Code memory + session
#   transcripts), settings.json, commands/, plugins/, and credentials are NEVER
#   touched. The Claude Code binary/install is never touched either.
# - Deletion is MANIFEST-SCOPED: the deploy records every file it installs in
#   ~/.claude/.noe-manifest-agents and ~/.claude/.noe-manifest-skills, and only
#   ever removes paths it previously installed itself. Agents and skills you
#   authored yourself, and Anthropic's official skills, are never deleted.
# - Every destructive step takes a timestamped backup under ~/.claude/backups
#   first, so an unexpected removal is always recoverable.
# - Use --force-wipe to force-refresh deployed content: it removes only the
#   agents and skills THIS deploy manages, then redeploys.
# - WSL2 Windows Explorer path to validate: \\wsl.localhost\Ubuntu\home\<USER>\.claude

REPO_URL_DEFAULT="https://github.com/advisely/claude-code-agents-team-nation-of-elites.git"
REPO_DIR_DEFAULT="$HOME/.cache/nation-of-elites"

REPO_URL="$REPO_URL_DEFAULT"
REPO_DIR="$REPO_DIR_DEFAULT"
FORCE_WIPE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-url)
      REPO_URL="${2:-}"; shift 2;;
    --repo-dir)
      REPO_DIR="${2:-}"; shift 2;;
    --force-wipe)
      FORCE_WIPE=true; shift;;
    -h|--help)
      sed -n '1,80p' "$0"; exit 0;;
    *)
      echo "Unknown argument: $1" >&2; exit 1;;
  esac
done

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
require git
require rsync

CLAUDE_DIR="$HOME/.claude"
AGENTS_SRC="${REPO_DIR}/agents"
AGENTS_DST="$CLAUDE_DIR/agents"
SKILLS_SRC="${REPO_DIR}/skills"
SKILLS_DST="$CLAUDE_DIR/skills"
# Manifests record exactly what this deploy installed, so a later run can purge
# its own stale output without guessing at — or deleting — anything the user
# put there. Kept outside agents/ and skills/ so they are never mirrored away.
MANIFEST_AGENTS="$CLAUDE_DIR/.noe-manifest-agents"
MANIFEST_SKILLS="$CLAUDE_DIR/.noe-manifest-skills"
BACKUP_ROOT="$CLAUDE_DIR/backups"
# Note: ~/.claude/projects (memory + session transcripts) is intentionally NOT
# referenced here — the deploy never touches user data.

# Fancy colors (fallback to plain if not a TTY)
if [[ -t 1 ]]; then
  BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
  GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'; MAGENTA='\033[35m'; CYAN='\033[36m'
else
  BOLD=''; DIM=''; RESET=''; GREEN=''; YELLOW=''; BLUE=''; MAGENTA=''; CYAN=''
fi

banner() {
  local title="$1"
  printf "\n%s\n" "${MAGENTA}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
  printf "%s %s%s%s\n" "${MAGENTA}┃${RESET}" "${BOLD}${title}${RESET}" "${DIM}" ""
  printf "%s\n" "${MAGENTA}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
}

info() { printf "${CYAN}➤${RESET} %s\n" "$*"; }
success() { printf "${GREEN}✅${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}⚠️ ${RESET} %s\n" "$*"; }

# Guard against a mis-set --repo-dir wiping something important. The cache is
# disposable and gets rm -rf'd on corruption, so validate before we ever do.
assert_safe_cache_path() {
  # Callers use this in a command substitution, so stdout is the return channel.
  # Diagnostics must go to stderr or the user sees an exit code and nothing else.
  local path="$1"
  local resolved
  resolved="$(cd "$(dirname "$path")" 2>/dev/null && printf '%s/%s' "$(pwd -P)" "$(basename "$path")")" \
    || resolved="$path"
  resolved="${resolved%/}"
  case "$resolved" in
    ""|"/"|"$HOME"|"$HOME/"|"/root"|"/home")
      warn "Refusing to use '$resolved' as the repo cache directory." >&2
      exit 1
      ;;
    # Anywhere inside ~/.claude is off-limits, not just ~/.claude itself: the
    # cache gets rm -rf'd when it is corrupt, and a stray --repo-dir pointing at
    # e.g. ~/.claude/projects would take user memory with it.
    "$CLAUDE_DIR"|"$CLAUDE_DIR"/*)
      warn "Refusing to use '$resolved' as the repo cache directory (inside $CLAUDE_DIR)." >&2
      exit 1
      ;;
  esac
  printf '%s' "$resolved"
}

# Timestamped copy of anything we are about to delete from. Deletion in this
# script is manifest-scoped and should never surprise anyone — but "should
# never" is not a recovery plan, so keep one.
backup_path() {
  local src="$1" label="$2" dest
  [[ -e "$src" ]] || return 0
  dest="$BACKUP_ROOT/${label}-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_ROOT"
  if cp -a "$src" "$dest" 2>/dev/null; then
    info "🛟 Backup written: $dest"
  else
    warn "Could not back up $src — aborting rather than deleting unbacked data."
    exit 1
  fi
}

# Relative paths of every regular file under a directory, sorted.
list_files_rel() {
  local root="$1"
  [[ -d "$root" ]] || return 0
  ( cd "$root" && find . -type f -printf '%P\n' 2>/dev/null | LC_ALL=C sort )
}

# Top-level entry names under a directory, sorted.
list_dirs_rel() {
  local root="$1"
  [[ -d "$root" ]] || return 0
  ( cd "$root" && find . -mindepth 1 -maxdepth 1 -printf '%P\n' 2>/dev/null | LC_ALL=C sort )
}

clone_or_update_repo() {
  banner "📦 Grocery Run — Syncing Recipes (git)"
  REPO_DIR="$(assert_safe_cache_path "$REPO_DIR")"

  # A .git directory can exist yet be unusable — an interrupted clone, a
  # corrupted index, or a tree copied across filesystems. `[[ -d .git ]]` alone
  # is not enough; ask git whether it can actually resolve the repository.
  local need_clone=true
  if [[ -d "$REPO_DIR/.git" ]] && git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    info "🛒 Updating pantry at $REPO_DIR"
    if git -C "$REPO_DIR" fetch --all --prune >/dev/null 2>&1 \
       && git -C "$REPO_DIR" pull --ff-only >/dev/null 2>&1; then
      need_clone=false
    else
      # Diverged branch, shallow clone, detached HEAD, or offline. The cache is
      # disposable, so discard it rather than failing the deploy under `set -e`.
      warn "Update failed (diverged, shallow, or offline) — re-cloning"
    fi
  elif [[ -e "$REPO_DIR" ]]; then
    warn "Cache at $REPO_DIR is not a valid git clone — replacing it"
  fi

  if [[ "$need_clone" == true ]]; then
    rm -rf "$REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    info "🛒 Cloning fresh ingredients into $REPO_DIR"
    if ! git clone "$REPO_URL" "$REPO_DIR"; then
      warn "git clone failed. Check network access and that $REPO_URL is reachable."
      exit 1
    fi
  fi
  success "Pantry stocked"
}

sanitize_target() {
  banner "🧽 Kitchen Cleanup — Sanitizing Workspace (data-safe)"
  mkdir -p "$CLAUDE_DIR"

  if [[ "$FORCE_WIPE" != true ]]; then
    info "Non-destructive deploy: only Nation of Elites content is replaced"
    info "Preserving projects/, settings.json, commands/, plugins/, credentials, and anything you authored"
    success "No destructive cleanup needed"
    return
  fi

  warn "🔄 Force refresh: clearing only content this deploy previously installed"
  info "Preserving projects/ (memory + session history), settings.json, credentials,"
  info "your own agents/skills, and Anthropic's official skills"

  # Agents: drop the managed files, keep everything else. Falling back to the
  # whole tree when no manifest exists would delete user-authored agents, so we
  # deliberately do not — an unmanaged tree is left for the manifest seeding in
  # deploy_agents to adopt.
  if [[ -s "$MANIFEST_AGENTS" && -d "$AGENTS_DST" ]]; then
    backup_path "$AGENTS_DST" agents
    while IFS= read -r rel; do
      [[ -n "$rel" ]] && rm -f "$AGENTS_DST/$rel"
    done < "$MANIFEST_AGENTS"
    find "$AGENTS_DST" -type d -empty -delete 2>/dev/null || true
  fi

  # Skills: remove only the skill directories this deploy owns.
  if [[ -s "$MANIFEST_SKILLS" && -d "$SKILLS_DST" ]]; then
    backup_path "$SKILLS_DST" skills
    while IFS= read -r name; do
      [[ -n "$name" && "$name" != "." && "$name" != ".." && "$name" != */* ]] \
        && rm -rf "${SKILLS_DST:?}/$name"
    done < "$MANIFEST_SKILLS"
  fi

  success "Managed content cleared — user data untouched"
}

deploy_agents() {
  banner "👩‍🍳 Cooking the Agents — Plating to ~/.claude/agents"
  if [[ ! -d "$AGENTS_SRC" ]]; then
    echo "Agents source not found at $AGENTS_SRC" >&2; exit 1
  fi
  local new_list
  new_list="$(list_files_rel "$AGENTS_SRC")"

  # First run under manifest-scoped deploys. We adopt ONLY the files this repo
  # currently ships — never the whole existing tree. An unrecognised agent is
  # assumed to be yours, so it is left in place rather than purged. The cost is
  # that agents retired before manifests existed need the explicit list below.
  if [[ ! -f "$MANIFEST_AGENTS" ]]; then
    info "No deploy manifest yet — adopting only Nation of Elites files; anything else is left untouched"
    printf '%s\n' "$new_list" > "$MANIFEST_AGENTS"
  fi

  # Agents retired before manifest tracking existed. Removed unconditionally
  # (with a backup) because leaving them shadows the canonical replacement.
  local -a LEGACY_RETIRED=(
    "07_Orchestrators/Tech_Lead_Orchestrator.md"
  )
  local legacy
  for legacy in "${LEGACY_RETIRED[@]}"; do
    if [[ -f "$AGENTS_DST/$legacy" ]]; then
      backup_path "$AGENTS_DST/$legacy" "agent-retired-$(basename "$legacy")"
      rm -f "$AGENTS_DST/$legacy"
      info "🗑️  Removed retired agent: $legacy"
    fi
  done

  # Purge only files we installed before and the repo no longer ships. Anything
  # you added yourself is not in the manifest, so it is never a deletion target.
  if [[ -d "$AGENTS_DST" ]]; then
    local stale
    stale="$(LC_ALL=C comm -23 <(LC_ALL=C sort "$MANIFEST_AGENTS") <(printf '%s\n' "$new_list"))"
    if [[ -n "$stale" ]]; then
      backup_path "$AGENTS_DST" agents
      while IFS= read -r rel; do
        [[ -n "$rel" ]] || continue
        rm -f "$AGENTS_DST/$rel"
        info "🗑️  Removed stale managed agent: $rel"
      done <<< "$stale"
      find "$AGENTS_DST" -type d -empty -delete 2>/dev/null || true
    fi
  fi

  info "Sautéing prompts and garnishing roles → $AGENTS_DST"
  mkdir -p "$AGENTS_DST"
  rsync -a "$AGENTS_SRC/" "$AGENTS_DST/"
  printf '%s\n' "$new_list" > "$MANIFEST_AGENTS"
  success "Plated beautifully at $AGENTS_DST"
}

deploy_skills() {
  banner "🎓 Loading Skills Library — Knowledge Transfer"

  # Deploy custom Nation of Elites skills if present
  if [[ -d "$SKILLS_SRC" ]]; then
    local new_skills
    new_skills="$(list_dirs_rel "$SKILLS_SRC")"

    # Retire skills we shipped previously and no longer do. Scoped to the
    # manifest, so Anthropic's official skills and your own never qualify.
    if [[ -f "$MANIFEST_SKILLS" ]]; then
      local stale_skills
      stale_skills="$(LC_ALL=C comm -23 <(LC_ALL=C sort "$MANIFEST_SKILLS") <(printf '%s\n' "$new_skills"))"
      if [[ -n "$stale_skills" ]]; then
        backup_path "$SKILLS_DST" skills
        while IFS= read -r name; do
          [[ -n "$name" && "$name" != */* ]] || continue
          rm -rf "${SKILLS_DST:?}/$name"
          info "🗑️  Removed retired Nation of Elites skill: $name"
        done <<< "$stale_skills"
      fi
    fi

    info "Installing custom Nation of Elites skills → $SKILLS_DST"
    mkdir -p "$SKILLS_DST"
    rsync -a "$SKILLS_SRC/" "$SKILLS_DST/"
    printf '%s\n' "$new_skills" > "$MANIFEST_SKILLS"
    success "Custom skills installed"
  else
    info "No custom skills found (optional)"
  fi

  # Install Anthropic's official skills
  if [[ ! -d "$SKILLS_DST/pdf" ]] && [[ ! -d "$SKILLS_DST/docx" ]]; then
    info "Installing Anthropic's official skills..."
    local temp_skills="/tmp/anthropic-skills-$$"

    if git clone --depth 1 https://github.com/anthropics/skills.git "$temp_skills" 2>/dev/null; then
      mkdir -p "$SKILLS_DST"

      # Install document skills
      [[ -d "$temp_skills/document-skills" ]] && cp -r "$temp_skills/document-skills"/* "$SKILLS_DST/" 2>/dev/null || true

      # Install other useful skills
      for skill in mcp-builder webapp-testing skill-creator artifacts-builder canvas-design; do
        [[ -d "$temp_skills/$skill" ]] && cp -r "$temp_skills/$skill" "$SKILLS_DST/" 2>/dev/null || true
      done

      rm -rf "$temp_skills"
      success "Anthropic skills installed"
    else
      warn "Failed to clone Anthropic skills (network issue?). Skipping official skills installation."
      info "You can manually install later: git clone https://github.com/anthropics/skills.git ~/.claude/skills"
    fi
  else
    success "Anthropic skills already installed (skipping)"
  fi
}

configure_official_plugins() {
  banner "🔌 Official Plugins — Autoconfiguration"

  local MCP_FILE="$CLAUDE_DIR/.mcp.json"
  local SETTINGS_FILE="$CLAUDE_DIR/settings.json"

  # Check if Claude Code is installed
  if ! command -v claude >/dev/null 2>&1; then
    warn "Claude Code CLI not found. Skipping plugin autoconfiguration."
    info "Install Claude Code first, then re-run this script to configure plugins."
    return
  fi

  info "Detecting available official Anthropic plugins..."
  info "These plugins connect your agents to external services via MCP."
  echo ""

  # List of official plugins with descriptions
  # Names below are the actual official plugin ids in claude-plugins-official.
  # Note: Jira AND Confluence ship together in the single "atlassian" plugin.
  local -a PLUGINS=(
    "github:GitHub (issues, PRs, code search, actions)"
    "gitlab:GitLab (issues, MRs, pipelines)"
    "slack:Slack (messaging, channels, notifications)"
    "atlassian:Atlassian — Jira & Confluence (tickets, sprints, wiki)"
    "linear:Linear (issues, projects, cycles)"
    "figma:Figma (design files, components)"
    "sentry:Sentry (error tracking, performance)"
    "vercel:Vercel (deployments, preview URLs)"
    "firebase:Firebase (auth, Firestore, hosting)"
    "supabase:Supabase (Postgres, auth, storage)"
    "notion:Notion (docs, databases, wikis)"
    "asana:Asana (tasks, timelines, portfolios)"
  )

  echo "  Available plugins:"
  for entry in "${PLUGINS[@]}"; do
    local name="${entry%%:*}"
    local desc="${entry#*:}"
    printf "    ${CYAN}%-14s${RESET} %s\n" "$name" "$desc"
  done
  echo ""

  # Non-interactive mode: just inform
  if [[ ! -t 0 ]]; then
    info "Running in non-interactive mode. Install plugins manually with:"
    info "  /plugin install <name>@claude-plugins-official"
    return
  fi

  printf "  Install official plugins interactively? [y/N] "
  read -r answer
  if [[ "$answer" != [yY]* ]]; then
    info "Skipping plugin installation. Install later with: /plugin install <name>@claude-plugins-official"
    return
  fi

  local installed=0
  for entry in "${PLUGINS[@]}"; do
    local name="${entry%%:*}"
    local desc="${entry#*:}"
    printf "    Install ${BOLD}%s${RESET} (%s)? [y/N] " "$name" "$desc"
    read -r ans
    if [[ "$ans" == [yY]* ]]; then
      info "Run in Claude Code: /plugin install ${name}@claude-plugins-official"
      ((installed++))
    fi
  done

  if [[ "$installed" -gt 0 ]]; then
    success "$installed plugin(s) selected. Run the /plugin install commands in Claude Code to complete setup."
  else
    info "No plugins selected."
  fi
}

check_semgrep() {
  banner "🔍 Semgrep SAST — Checking Installation"

  # Semgrep is optional. A missing or broken binary must never fail the deploy —
  # the SAST skill ships regardless, and the MCP plugin works independently.
  if command -v semgrep >/dev/null 2>&1; then
    local sg_version=""
    sg_version=$(semgrep --version 2>/dev/null | grep -m1 '[0-9]' || true)
    if [[ -n "$sg_version" ]]; then
      success "Semgrep installed: v${sg_version}"

      # Check for Semgrep token
      if [[ -f "$HOME/.semgrep/settings.yml" ]]; then
        success "Semgrep token configured (~/.semgrep/settings.yml)"
      else
        warn "Semgrep token not found. Run 'semgrep login' to authenticate for full rule access."
      fi
    else
      # A shim resolves on PATH but the interpreter or package behind it is broken.
      warn "Semgrep found on PATH but not runnable. Reinstall with: pipx install --force semgrep"
      info "Skipping — the Semgrep SAST skill is deployed and unaffected."
    fi
  else
    warn "Semgrep not installed. Install with: pipx install semgrep"
    info "Semgrep SAST skill is deployed but CLI scanning requires the semgrep binary."
    info "The Semgrep MCP plugin (if enabled in Claude Code) works independently."
  fi
}

validate_install() {
  local missing=0
  banner "🧪 Taste Test — Freshness & Sanity Checks"

  # 1) Canonical orchestrator present
  if [[ -f "$AGENTS_DST/07_Orchestrators/Chief_Operations_Orchestrator.md" ]]; then
    success "Chef's special present: Chief Operations Orchestrator (canonical)"
  else
    echo "Missing canonical Orchestrator at $AGENTS_DST/07_Orchestrators/Chief_Operations_Orchestrator.md" >&2
    missing=1
  fi

  # 2) No deprecated orchestrator
  if [[ -f "$AGENTS_DST/07_Orchestrators/Tech_Lead_Orchestrator.md" ]]; then
    warn "Found old Tech_Lead_Orchestrator.md — the canonical file is now Chief_Operations_Orchestrator.md"
    missing=1
  else
    success "No stale leftovers: deprecated orchestrator not found"
  fi

  # 3) Basic count sanity (at least 25 agents)
  local count
  count=$(grep -R "^name:\s" "$AGENTS_DST" | wc -l | tr -d ' ')
  if [[ "$count" -ge 25 ]]; then
    success "Healthy spread detected: $count agent recipes"
  else
    warn "Sparse menu detected: $count (verify deployment)"
  fi

  # 4) Check skills installation
  if [[ -d "$SKILLS_DST" ]]; then
    local skills_count
    skills_count=$(find "$SKILLS_DST" -name "SKILL.md" | wc -l | tr -d ' ')
    if [[ "$skills_count" -ge 3 ]]; then
      success "Skills library detected: $skills_count skills available"
    else
      warn "Few skills detected: $skills_count (installation may be incomplete)"
    fi
  else
    info "No skills directory found (optional feature)"
  fi

  # 5) Verify Semgrep SAST skill deployed
  if [[ -f "$SKILLS_DST/semgrep-sast/SKILL.md" ]]; then
    success "Semgrep SAST skill deployed"
  else
    warn "Semgrep SAST skill not found at $SKILLS_DST/semgrep-sast/SKILL.md"
  fi

  # 6) Verify pipeline skills deployed
  if [[ -f "$SKILLS_DST/pipeline-quality/SKILL.md" ]] && [[ -f "$SKILLS_DST/pipeline-full-build/SKILL.md" ]]; then
    success "Pipeline skills deployed (quality + full-build)"
  else
    warn "Pipeline skills not fully deployed"
  fi

  # 7) Print WSL2 path hint
  if grep -qi microsoft /proc/version 2>/dev/null; then
    info "WSL2 detected. Peek into the dining room via Windows Explorer: \\wsl.localhost\\Ubuntu\\home\\$USER\\.claude"
  fi

  if [[ "$missing" -ne 0 ]]; then
    exit 2
  fi
  success "Taste test passed — everything's delicious"
}

main() {
  banner "🍳 Mise en Place — Prepping the Kitchen"
  clone_or_update_repo
  sanitize_target
  deploy_agents
  deploy_skills
  check_semgrep
  configure_official_plugins
  validate_install
  banner "🍽️ Dinner Is Served — Installation Complete"
}

main "$@"
