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
# - By default, we ONLY wipe ~/.claude/agents and ~/.claude/projects (safer).
# - Use --force-wipe to remove the entire ~/.claude directory (DANGEROUS), then recreate minimal structure.
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
PROJECTS_DST="$CLAUDE_DIR/projects"
SKILLS_SRC="${REPO_DIR}/skills"
SKILLS_DST="$CLAUDE_DIR/skills"

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

clone_or_update_repo() {
  banner "📦 Grocery Run — Syncing Recipes (git)"
  if [[ -d "$REPO_DIR/.git" ]]; then
    info "🛒 Updating pantry at $REPO_DIR"
    git -C "$REPO_DIR" fetch --all --prune
    git -C "$REPO_DIR" pull --ff-only
  else
    info "🛒 Cloning fresh ingredients into $REPO_DIR"
    mkdir -p "$REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
  fi
  success "Pantry stocked"
}

sanitize_target() {
  banner "🧽 Kitchen Cleanup — Sanitizing Workspace"
  if [[ "$FORCE_WIPE" == true ]]; then
    warn "🔥 Full kitchen reset: tossing the pantry ($CLAUDE_DIR)"
    rm -rf "$CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR"
    success "Fresh kitchen ready: $CLAUDE_DIR"
  else
    info "Wiping old dishes: removing agents/ and projects/ to avoid flavor conflicts"
    rm -rf "$AGENTS_DST" "$PROJECTS_DST"
    mkdir -p "$CLAUDE_DIR"
    success "Counters clean (agents/projects sanitized)"
  fi
}

deploy_agents() {
  banner "👩‍🍳 Cooking the Agents — Plating to ~/.claude/agents"
  if [[ ! -d "$AGENTS_SRC" ]]; then
    echo "Agents source not found at $AGENTS_SRC" >&2; exit 1
  fi
  info "Sautéing prompts and garnishing roles → $AGENTS_DST"
  rsync -a --delete "$AGENTS_SRC/" "$AGENTS_DST/"
  success "Plated beautifully at $AGENTS_DST"
}

deploy_skills() {
  banner "🎓 Loading Skills Library — Knowledge Transfer"

  # Deploy custom Nation of Elites skills if present
  if [[ -d "$SKILLS_SRC" ]]; then
    info "Installing custom Nation of Elites skills → $SKILLS_DST"
    mkdir -p "$SKILLS_DST"
    rsync -a "$SKILLS_SRC/" "$SKILLS_DST/"
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
  local -a PLUGINS=(
    "github:GitHub (issues, PRs, code search, actions)"
    "slack:Slack (messaging, channels, notifications)"
    "jira:Jira (tickets, sprints, boards)"
    "linear:Linear (issues, projects, cycles)"
    "figma:Figma (design files, components)"
    "sentry:Sentry (error tracking, performance)"
    "vercel:Vercel (deployments, preview URLs)"
    "firebase:Firebase (auth, Firestore, hosting)"
    "supabase:Supabase (Postgres, auth, storage)"
    "notion:Notion (docs, databases, wikis)"
    "confluence:Confluence (wiki, knowledge base)"
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

  if command -v semgrep >/dev/null 2>&1; then
    local sg_version
    sg_version=$(semgrep --version 2>/dev/null || echo "unknown")
    success "Semgrep installed: v$sg_version"

    # Check for Semgrep token
    if [[ -f "$HOME/.semgrep/settings.yml" ]]; then
      success "Semgrep token configured (~/.semgrep/settings.yml)"
    else
      warn "Semgrep token not found. Run 'semgrep login' to authenticate for full rule access."
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
  if [[ -f "$AGENTS_DST/07_Orchestrators/Tech_Lead_Orchestrator.md" ]]; then
    success "Chef's special present: Tech Lead Orchestrator (canonical)"
  else
    echo "Missing canonical Orchestrator at $AGENTS_DST/07_Orchestrators/Tech_Lead_Orchestrator.md" >&2
    missing=1
  fi

  # 2) No deprecated orchestrator
  if ! grep -R "tech-lead-orchestrator-deprecated" "$AGENTS_DST" -n >/dev/null 2>&1; then
    success "No stale leftovers: deprecated orchestrator not found"
  else
    echo "Found deprecated orchestrator entries in deployed agents" >&2
    missing=1
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
