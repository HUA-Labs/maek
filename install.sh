#!/bin/bash
# maek installer — copies skill + external loop into your project
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/HUA-Labs/maek/main/install.sh | bash
#
# Or run locally:
#   bash install.sh

set -euo pipefail

REPO="HUA-Labs/maek"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[maek]${NC} $1"; }
warn()  { echo -e "${YELLOW}[maek]${NC} $1"; }

# ── Check prerequisites ──────────────────────────────────
if ! command -v claude &>/dev/null; then
  warn "Claude Code CLI not found. Install it first:"
  warn "  https://docs.anthropic.com/en/docs/claude-code"
  warn ""
  warn "Continuing anyway (skill files will be installed)..."
fi

# ── Install skill ─────────────────────────────────────────
info "Installing maek skill..."
mkdir -p .claude/skills/maek

FETCH=""
if command -v curl &>/dev/null; then
  FETCH="curl -fsSL"
elif command -v wget &>/dev/null; then
  FETCH="wget -q -O -"
else
  echo "Error: curl or wget required"
  exit 1
fi

$FETCH "${BASE_URL}/skill/SKILL.md" > .claude/skills/maek/SKILL.md
info "Installed .claude/skills/maek/SKILL.md"

# ── Install agents ────────────────────────────────────────
info "Installing custom agents..."
mkdir -p .claude/agents

for agent in auto-impl parallel-impl fix-issue; do
  $FETCH "${BASE_URL}/agents/${agent}.md" > ".claude/agents/${agent}.md"
  info "Installed .claude/agents/${agent}.md"
done

# ── Install external loop (optional) ─────────────────────
info "Installing external loop..."
mkdir -p scripts

$FETCH "${BASE_URL}/maek.sh" > scripts/maek.sh
chmod +x scripts/maek.sh
info "Installed scripts/maek.sh"

# ── Create config if not exists ───────────────────────────
if [[ ! -f .maek/config ]]; then
  mkdir -p .maek
  info "Creating .maek/config..."
  echo "# maek config — edit the verify command for your project" > .maek/config
  echo "verify=npm run typecheck && npm run build" >> .maek/config
  warn "Edit .maek/config to match your project's build command"
fi

# ── Remind about .gitignore ──────────────────────────────
if [[ -f .gitignore ]]; then
  if ! grep -q '.maek/progress.md' .gitignore 2>/dev/null; then
    warn "Add to .gitignore:"
    warn "  .maek/progress.md"
    warn "  .maek/loop.log"
  fi
fi

# ── Done ──────────────────────────────────────────────────
echo ""
info "Done! Usage:"
info "  Interactive:  /maek (inside Claude Code)"
info "  External:     ./scripts/maek.sh --issue 123"
info ""
info "Docs: https://github.com/${REPO}"
