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

  # 4) Print WSL2 path hint
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
  validate_install
  banner "🍽️ Dinner Is Served — Installation Complete"
}

main "$@"
