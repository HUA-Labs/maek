# maek (脈) — Autonomous Implementation Loop for Claude Code

> Context flows like a pulse — autonomous orchestration where state lives in files, not memory.

maek combines ideas from Ralph Loop (file-based state, context rotation) and Symphony (issue → isolate → verify orchestration) into a lightweight system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

**No infrastructure required.** Just a Claude Code skill + a bash script.

## Why maek?

Claude Code is powerful, but long sessions degrade. Complex tasks stall when the agent hits the same error repeatedly. And there's no built-in way to break a large task into verified, committed chunks.

maek solves this with three ideas:

- **File-based state** — Progress lives in `progress.md`, not the context window. Sessions can restart without losing work.
- **Stuck detection** — If the same error appears 3 times, maek switches strategy instead of brute-forcing.
- **Task-level verification** — Every completed task gets a build check and its own commit. Broken builds don't compound.

## What It Does

maek turns a GitHub issue or PRD into working code through an autonomous loop:

1. **Decompose** — Break the task into independent units
2. **Execute** — Implement each task (parallel when possible, using included custom agents)
3. **Verify** — Run your build/test commands after each task
4. **Detect stuck** — Same error 3x? Switch strategy. Same edit→revert 2x? Re-analyze.
5. **Rotate context** — When the session gets long, start fresh. State lives in files, not memory.

## Quick Start

### 1. Install

```bash
# Clone the repo
git clone https://github.com/HUA-Labs/maek.git
cd maek

# Copy into your project
cd /path/to/your/project
mkdir -p .claude/skills/maek .claude/agents
cp /path/to/maek/skill/SKILL.md .claude/skills/maek/SKILL.md
cp /path/to/maek/agents/*.md .claude/agents/

# Copy the external loop (optional, for long-running tasks)
cp /path/to/maek/maek.sh scripts/maek.sh
chmod +x scripts/maek.sh
```

**One-liner install** (copies skill + script into current project):

```bash
curl -fsSL https://raw.githubusercontent.com/HUA-Labs/maek/main/install.sh | bash
```

### 2. Configure

```bash
mkdir -p .maek
echo 'verify=npm run typecheck && npm run build' > .maek/config
```

Add to `.gitignore`:
```
.maek/progress.md
.maek/loop.log
```

### 3. Use

**Inside Claude Code** (interactive):
```
/maek                                    # From .maek/PRD.md
/maek https://github.com/.../issues/123  # From GitHub issue
/maek path/to/requirements.md            # From any file
```

**External loop** (headless, for long-running tasks):
```bash
./scripts/maek.sh                        # From .maek/PRD.md
./scripts/maek.sh --issue 123            # From GitHub issue
./scripts/maek.sh --max-iterations 10    # Limit iterations
```

## How It Works

### Architecture

```
┌──────────────────────────────────────────────────────┐
│  maek.sh (external loop — context rotation)          │
│  ┌────────────────────────────────────────────────┐  │
│  │  Claude Code Session                           │  │
│  │  ┌──────────────────────────────────────────┐  │  │
│  │  │  /maek skill (orchestrator)              │  │  │
│  │  │                                          │  │  │
│  │  │  ┌────────────┐  ┌────────────────────┐  │  │  │
│  │  │  │ auto-impl  │  │ parallel-impl      │  │  │  │
│  │  │  │ (single    │  │ (split + parallel  │  │  │  │
│  │  │  │  task)     │  │  tasks)            │  │  │  │
│  │  │  └────────────┘  └────────────────────┘  │  │  │
│  │  │  ┌────────────┐  ┌────────────────────┐  │  │  │
│  │  │  │ fix-issue  │  │ Explore (built-in) │  │  │  │
│  │  │  │ (bug fix)  │  │ (codebase search)  │  │  │  │
│  │  │  └────────────┘  └────────────────────┘  │  │  │
│  │  └──────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────┘  │
│            ▲                    │                     │
│            │    .maek/          ▼                     │
│            │  ┌──────────────────────┐               │
│            └──│  progress.md (state) │               │
│               └──────────────────────┘               │
└──────────────────────────────────────────────────────┘
```

### Included Agents

maek ships with custom [Claude Code agents](https://docs.anthropic.com/en/docs/claude-code/agents) that the orchestrator delegates work to:

| Agent | Role | What It Does |
|-------|------|-------------|
| `auto-impl` | Single task implementer | Implements a feature, auto-fixes errors, iterates until build passes (max 5 rounds) |
| `parallel-impl` | Parallel task splitter | Splits complex features into independent areas, implements concurrently, integrates |
| `fix-issue` | Issue fixer | Analyzes a GitHub issue, finds relevant code, fixes it, prepares a commit |

These are installed to `.claude/agents/` and automatically available to the `/maek` skill via the Agent tool.

### File-Based State

All state lives in `.maek/`:

```
.maek/
├── config          # Your project settings (verify command, etc.)
├── PRD.md          # Task definition (optional input)
├── progress.md     # Auto-generated task tracker (gitignored)
└── loop.log        # External loop execution log (gitignored)
```

### Stuck Detection

maek doesn't brute-force failures. It detects when it's stuck and adapts:

| Condition | Verdict | Action |
|-----------|---------|--------|
| Same build error 3x | stuck | Switch to a different approach |
| Same file edit→revert 2x | thrashing | Stop, re-analyze the problem |
| Subagent failure 3x | escalate | Ask the user for help |
| progress.md unchanged 3 iterations | stall | External loop annotates + rotates |

**Escalation order when stuck:**
1. Try a different approach based on the error
2. Read more surrounding code for context
3. Search official docs via web
4. Ask the user

### Context Rotation

The external loop (`maek.sh`) solves context window degradation:

- Each iteration = fresh Claude Code session with full context budget
- `progress.md` carries state between sessions
- Stuck detection triggers strategy changes across rotations

This is the key insight from Ralph Loop: **the agent's memory is the filesystem, not the context window**.

## Configuration

### `.maek/config`

Simple key=value format:

```bash
# Required: how to verify the build
verify=npm run typecheck && npm run build

# Optional
max_stuck_retries=3      # Retries before stuck verdict (default: 3)
parallel_threshold=2     # Independent tasks needed for parallel execution (default: 2)
auto_commit=true         # Commit after each task (default: true)
```

### `maek.sh` CLI options

```
--issue N            GitHub issue number
--prd FILE           Path to PRD/requirements file
--verify CMD         Override verify command from config
--model MODEL        Claude model (e.g., sonnet, opus, haiku)
--max-iterations N   Max loop iterations (default: 20)
--max-turns N        Claude Code turns per session (default: 50)
--help               Show help
```

## Examples

See [`examples/`](./examples/) for project-specific configs.

<details>
<summary><strong>Next.js / TypeScript</strong></summary>

```bash
# .maek/config
verify=npx tsc --noEmit && npm run build
```

</details>

<details>
<summary><strong>Python</strong></summary>

```bash
# .maek/config
verify=python -m mypy . && python -m pytest
```

</details>

<details>
<summary><strong>Rust</strong></summary>

```bash
# .maek/config
verify=cargo check && cargo test
```

</details>

<details>
<summary><strong>Go</strong></summary>

```bash
# .maek/config
verify=go vet ./... && go test ./...
```

</details>

## Writing a Good PRD

Create `.maek/PRD.md` with clear requirements:

```markdown
# Feature: User Dashboard

## Goal
One sentence describing the desired outcome.

## Requirements
- Specific, implementable items
- Each should map to ~1 task
- Include technical constraints

## Out of Scope
- Things explicitly NOT to do
- Prevents scope creep during autonomous execution
```

See [`examples/PRD-example.md`](./examples/PRD-example.md) for a full example.

## Design Principles

1. **File over memory** — State in files survives context rotation
2. **Reuse built-ins** — Ships custom agents (`auto-impl`, `parallel-impl`, `fix-issue`) that work with Claude Code's Agent tool
3. **Verify everything** — Build check after every task, not just at the end
4. **Fail fast, rotate** — Stuck? Don't brute-force. Switch strategy or start fresh.
5. **Task-level commits** — Each completed task = one commit = easy rollback

## Anti-Patterns

| Don't | Why |
|-------|-----|
| Skip verification between tasks | Broken builds compound; debugging becomes exponentially harder |
| Repeat the same approach when stuck | If it failed 3x, try something different |
| One giant commit for everything | Can't rollback individual tasks |
| Forget to update progress.md | Next session won't know what's done |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`claude` CLI)
- [GitHub CLI](https://cli.github.com/) (`gh`) — only for issue-based workflows
- Bash shell (macOS/Linux native, Windows via Git Bash or WSL)
- Git

### Windows

The `/maek` skill works natively in Claude Code on any platform. The external loop (`maek.sh`) requires a bash-compatible shell:

- **Git Bash** (bundled with [Git for Windows](https://gitforwindows.org/)) — recommended
- **WSL** (Windows Subsystem for Linux)
- **PowerShell alternative**: A `maek.ps1` is on the roadmap — contributions welcome

## Inspiration

maek synthesizes ideas from:
- **Ralph Loop** by Geoffrey Huntley — The insight that an agent's memory should be the filesystem, enabling context rotation without state loss
- **Symphony** by OpenAI — The pattern of polling issues, isolating workspaces, and verifying builds as an orchestration pipeline

Neither is used directly. maek takes these concepts and implements them as a lightweight Claude Code skill with stuck detection and parallel execution via the Agent tool.

## Credits

Built by [HUA Labs](https://github.com/HUA-Labs).

## License

MIT
