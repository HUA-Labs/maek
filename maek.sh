#!/bin/bash
# maek.sh — Autonomous implementation loop for Claude Code
# Context rotation: each iteration launches a fresh Claude Code session.
# State persists in .maek/progress.md (file-based, not memory-based).
#
# Usage:
#   ./maek.sh                              # From .maek/PRD.md
#   ./maek.sh --issue 123                  # From GitHub issue
#   ./maek.sh --prd path/to/requirements   # From specific file
#   ./maek.sh --max-iterations 10          # Limit iterations (default: 20)
#   ./maek.sh --max-turns 80               # Turns per session (default: 50)
#   ./maek.sh --verify "cargo test"        # Override verify command

set -euo pipefail

# ── defaults ──────────────────────────────────────────────
MAX_ITERATIONS=20
MAX_TURNS=50
MODEL=""
ISSUE=""
PRD=""
VERIFY_OVERRIDE=""
PROGRESS_FILE=".maek/progress.md"
CONFIG_FILE=".maek/config"
LOG_FILE=".maek/loop.log"

# ── parse args ────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue)          ISSUE="$2"; shift 2 ;;
    --prd)            PRD="$2"; shift 2 ;;
    --model)          MODEL="$2"; shift 2 ;;
    --max-iterations) MAX_ITERATIONS="$2"; shift 2 ;;
    --max-turns)      MAX_TURNS="$2"; shift 2 ;;
    --verify)         VERIFY_OVERRIDE="$2"; shift 2 ;;
    --help|-h)
      cat <<'HELP'
maek — Autonomous implementation loop for Claude Code

Usage:
  ./maek.sh                              # From .maek/PRD.md
  ./maek.sh --issue 123                  # From GitHub issue
  ./maek.sh --prd path/to/requirements   # From specific file

Options:
  --issue N            GitHub issue number
  --prd FILE           Path to PRD or requirements file
  --verify CMD         Override verify command (default: from .maek/config)
  --model MODEL        Claude model (e.g., sonnet, opus, haiku)
  --max-iterations N   Max loop iterations (default: 20)
  --max-turns N        Claude Code turns per session (default: 50)
  --help, -h           Show this help

Config:
  Create .maek/config with key=value pairs:
    verify=npm run typecheck && npm run build
    max_stuck_retries=3
    parallel_threshold=2
    auto_commit=true

State files (.gitignore these):
  .maek/progress.md    Task tracker (auto-generated)
  .maek/loop.log       Execution log
HELP
      exit 0
      ;;
    *) echo "Unknown option: $1 (use --help for usage)"; exit 1 ;;
  esac
done

# ── setup ─────────────────────────────────────────────────
mkdir -p .maek
touch "$LOG_FILE"

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo "$msg" | tee -a "$LOG_FILE"
}

# ── read config ───────────────────────────────────────────
read_config() {
  local key="$1"
  local default="$2"
  if [[ -f "$CONFIG_FILE" ]]; then
    local value
    value=$(grep "^${key}=" "$CONFIG_FILE" 2>/dev/null | head -1 | cut -d'=' -f2-)
    if [[ -n "$value" ]]; then
      echo "$value"
      return
    fi
  fi
  echo "$default"
}

VERIFY_CMD="${VERIFY_OVERRIDE:-$(read_config "verify" "")}"

if [[ -z "$VERIFY_CMD" ]]; then
  echo "Error: No verify command configured."
  echo ""
  echo "Create .maek/config with:"
  echo '  verify=npm run typecheck && npm run build'
  echo ""
  echo "Or pass --verify flag:"
  echo '  ./maek.sh --verify "npm run typecheck && npm run build"'
  exit 1
fi

# ── build prompt ──────────────────────────────────────────
# Inlines the full protocol so Claude doesn't need to Read a file first.
build_prompt() {
  local source_info=""

  if [[ -n "$ISSUE" ]]; then
    local repo
    repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
    if [[ -n "$repo" ]]; then
      source_info="GitHub issue: https://github.com/${repo}/issues/${ISSUE}"
    else
      source_info="GitHub issue #${ISSUE}"
    fi
  elif [[ -n "$PRD" ]]; then
    source_info="PRD file: ${PRD}"
  else
    source_info=".maek/PRD.md"
  fi

  cat <<PROMPT
You are running the maek (脈) autonomous implementation loop.

RULES:
- ALWAYS run verify after each task: ${VERIFY_CMD}
- ALWAYS update .maek/progress.md after completing a task
- Same build error 3x → SWITCH STRATEGY, do not repeat
- Same file edit→revert 2x → STOP and re-analyze
- 1 task = 1 commit

TASK SOURCE: ${source_info}
VERIFY COMMAND: ${VERIFY_CMD}

PROTOCOL:
1. LOAD — Read the task source above. If ${source_info} is a GitHub issue URL, use: gh issue view --json title,body. Check .maek/progress.md for previous progress (resume if exists, skip completed tasks).

2. DECOMPOSE — Break into tasks, write .maek/progress.md:
   - [ ] T1: [description] (files: ~N)
   - [ ] T2: [description] (depends: T1)

3. EXECUTE — For each task:
   - Single task → Agent(subagent_type="auto-impl") or implement directly
   - 2+ independent → Agent(subagent_type="parallel-impl") or multiple Agent() calls
   - Bug fix → Agent(subagent_type="fix-issue")
   - Need context → Agent(subagent_type="Explore")

4. VERIFY — Run: ${VERIFY_CMD}

5. STUCK? — Same error 3x: switch approach. Edit→revert 2x: re-analyze. Agent fail 3x: log and skip.
   Escalate: different approach → read more code → WebSearch docs → skip task.
   Log stuck events in progress.md Stuck Log section.

6. COMMIT — Verify passes → mark [x] in progress.md → git commit (Conventional Commits).

7. REPEAT — Next incomplete task. When all done, update progress.md with final status.
PROMPT
}

# ── check completion ──────────────────────────────────────
is_complete() {
  if [[ ! -f "$PROGRESS_FILE" ]]; then
    return 1
  fi

  local remaining
  remaining=$(grep -c '^\- \[ \]' "$PROGRESS_FILE" 2>/dev/null || true)

  if [[ "$remaining" -eq 0 ]]; then
    local total
    total=$(grep -c '^\- \[' "$PROGRESS_FILE" 2>/dev/null || true)
    if [[ "$total" -eq 0 ]]; then
      return 1
    fi
    return 0
  fi

  return 1
}

# ── check stuck (same state for 3 consecutive iterations) ─
LAST_HASH=""
SAME_HASH_COUNT=0

check_stuck() {
  if [[ ! -f "$PROGRESS_FILE" ]]; then
    return 1
  fi

  local current_hash
  if command -v md5sum &>/dev/null; then
    current_hash=$(md5sum "$PROGRESS_FILE" | cut -d' ' -f1)
  elif command -v md5 &>/dev/null; then
    current_hash=$(md5 -q "$PROGRESS_FILE")
  else
    # Fallback: use file size + modification time
    current_hash=$(stat -c '%s-%Y' "$PROGRESS_FILE" 2>/dev/null || stat -f '%z-%m' "$PROGRESS_FILE" 2>/dev/null || echo "unknown")
  fi

  if [[ "$current_hash" == "$LAST_HASH" ]]; then
    SAME_HASH_COUNT=$((SAME_HASH_COUNT + 1))
    if [[ "$SAME_HASH_COUNT" -ge 3 ]]; then
      return 0  # stuck
    fi
  else
    SAME_HASH_COUNT=0
    LAST_HASH="$current_hash"
  fi

  return 1
}

# ── verify build ──────────────────────────────────────────
verify_build() {
  log "Verifying: $VERIFY_CMD"
  if eval "$VERIFY_CMD" 2>&1 | tail -10; then
    log "Verification PASSED"
    return 0
  else
    log "Verification FAILED"
    return 1
  fi
}

# ── main loop ─────────────────────────────────────────────
PROMPT=$(build_prompt)

log "=== maek start ==="
log "Verify: $VERIFY_CMD"
log "Model: ${MODEL:-default}"
log "Max iterations: $MAX_ITERATIONS"
log "Max turns/session: $MAX_TURNS"
log ""

for i in $(seq 1 "$MAX_ITERATIONS"); do
  log "────── Iteration $i / $MAX_ITERATIONS ──────"

  # Check if all tasks are done
  if is_complete; then
    log "All tasks complete!"
    break
  fi

  # Check if stuck
  if check_stuck; then
    log "STUCK: progress unchanged for 3 consecutive iterations"
    echo "" >> "$PROGRESS_FILE"
    echo "### Loop Stuck (iteration $i)" >> "$PROGRESS_FILE"
    echo "- progress.md unchanged for 3 consecutive iterations" >> "$PROGRESS_FILE"
    echo "- Needs: manual intervention or different approach" >> "$PROGRESS_FILE"
    SAME_HASH_COUNT=0
  fi

  # Launch fresh Claude Code session
  log "Launching Claude Code session..."

  CLAUDE_ARGS=(
    --print
    --max-turns "$MAX_TURNS"
    --allowedTools "Read,Write,Edit,Bash,Glob,Grep,Agent"
  )

  if [[ -n "$MODEL" ]]; then
    CLAUDE_ARGS+=(--model "$MODEL")
  fi

  if echo "$PROMPT" | claude "${CLAUDE_ARGS[@]}" 2>&1 | tee -a "$LOG_FILE"; then
    log "Session $i completed normally"
  else
    log "Session $i exited with error (code: $?)"
  fi

  # Verify build after each session
  if ! verify_build; then
    log "Build broken after iteration $i — next iteration will attempt fix"
  fi

  log ""
done

# ── summary ───────────────────────────────────────────────
log "=== maek end ==="

if [[ -f "$PROGRESS_FILE" ]]; then
  completed=$(grep -c '^\- \[x\]' "$PROGRESS_FILE" 2>/dev/null || echo 0)
  remaining=$(grep -c '^\- \[ \]' "$PROGRESS_FILE" 2>/dev/null || echo 0)
  log "Completed: $completed tasks"
  log "Remaining: $remaining tasks"
fi

log "Full log: $LOG_FILE"
