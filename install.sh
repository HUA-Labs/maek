#!/bin/bash
# maek installer — copies skill + agents + external loop into your project
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/HUA-Labs/maek/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/HUA-Labs/maek/main/install.sh | bash -s -- --codex
#
# Or run locally:
#   bash install.sh           # Claude Code (default)
#   bash install.sh --codex   # Codex

set -euo pipefail

REPO="HUA-Labs/maek"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
MODE="claude"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --codex) MODE="codex"; shift ;;
    *) shift ;;
  esac
done

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[maek]${NC} $1"; }
warn()  { echo -e "${YELLOW}[maek]${NC} $1"; }

FETCH=""
if command -v curl &>/dev/null; then
  FETCH="curl -fsSL"
elif command -v wget &>/dev/null; then
  FETCH="wget -q -O -"
else
  echo "Error: curl or wget required"
  exit 1
fi

if [[ "$MODE" == "codex" ]]; then
  # ── Codex install ────────────────────────────────────────
  info "Installing maek for Codex..."

  SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"
  mkdir -p "$SKILLS_DIR"

  for skill in maek-bootstrap maek-loop maek-consumer-qa maek-release; do
    mkdir -p "$SKILLS_DIR/$skill"
    $FETCH "${BASE_URL}/codex/skills/${skill}/SKILL.md" > "$SKILLS_DIR/$skill/SKILL.md"
    if $FETCH "${BASE_URL}/codex/skills/${skill}/agents/openai.yaml" > "$SKILLS_DIR/$skill/agents/openai.yaml" 2>/dev/null; then
      mkdir -p "$SKILLS_DIR/$skill/agents"
    fi
    info "Installed $skill"
  done

  echo ""
  info "Done! Codex skills installed to $SKILLS_DIR"
  info "Usage: mention \$maek-bootstrap in your Codex prompt"

else
  # ── Claude Code install ──────────────────────────────────
  if ! command -v claude &>/dev/null; then
    warn "Claude Code CLI not found. Install it first:"
    warn "  https://docs.anthropic.com/en/docs/claude-code"
    warn ""
    warn "Continuing anyway (skill files will be installed)..."
  fi

  # Install skill
  info "Installing maek skill..."
  mkdir -p .claude/skills/maek

  $FETCH "${BASE_URL}/claude/skill/SKILL.md" > .claude/skills/maek/SKILL.md
  info "Installed .claude/skills/maek/SKILL.md"

  # Install agents
  info "Installing custom agents..."
  mkdir -p .claude/agents

  for agent in auto-impl parallel-impl fix-issue; do
    $FETCH "${BASE_URL}/claude/agents/${agent}.md" > ".claude/agents/${agent}.md"
    info "Installed .claude/agents/${agent}.md"
  done

  # Install external loop
  info "Installing external loop..."
  mkdir -p scripts

  $FETCH "${BASE_URL}/maek.sh" > scripts/maek.sh
  chmod +x scripts/maek.sh
  info "Installed scripts/maek.sh"

  # Create config if not exists
  if [[ ! -f .maek/config ]]; then
    mkdir -p .maek
    info "Creating .maek/config..."
    echo "# maek config — edit the verify command for your project" > .maek/config
    echo "verify=npm run typecheck && npm run build" >> .maek/config
    warn "Edit .maek/config to match your project's build command"
  fi

  # Remind about .gitignore
  if [[ -f .gitignore ]]; then
    if ! grep -q '.maek/progress.md' .gitignore 2>/dev/null; then
      warn "Add to .gitignore:"
      warn "  .maek/progress.md"
      warn "  .maek/loop.log"
    fi
  fi

  echo ""
  info "Done! Usage:"
  info "  Interactive:  /maek (inside Claude Code)"
  info "  External:     ./scripts/maek.sh --issue 123"
fi

echo ""
info "Docs: https://github.com/${REPO}"
