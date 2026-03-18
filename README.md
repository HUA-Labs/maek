# maek (脈) — Autonomous Implementation Loop

> Context flows like a pulse — autonomous orchestration where state lives in files, not memory.

maek turns a GitHub issue or PRD into working code through an autonomous loop: decompose → execute → verify → detect stuck → rotate context.

**No infrastructure required.** Just skills, agents, and a bash script.

## Supported Platforms

| Platform | Directory | Approach |
|----------|-----------|----------|
| [Claude Code](./claude/) | `claude/` | 1 skill + 3 agents + external bash loop |
| [Codex](./codex/) | `codex/` | 4 separate skills + guides |

Both versions share the same philosophy but differ in architecture. See each directory's README for setup and usage.

## Why Two Versions?

The Claude and Codex versions solve the same problem — context loss and autonomous execution — but from opposite angles.

| | Claude | Codex |
|---|--------|-------|
| **Methodology** | Lean/Agile | Structured/Waterfall |
| **PDCA cycle** | Micro × many (5-min loops) | Macro × 1 (project-level) |
| **Context shape** | Wide — monorepo structure, cross-package deps, session history | Deep — intent, consumer impact, release risk |
| **Strength** | Fast iteration, stuck recovery | Judgment, verification, risk assessment |
| **Weak spot** | Can drift in long sessions | Slower to start producing code |

The Claude version runs many tiny Plan→Do→Check→Act cycles at the task level — stuck detection is essentially an automated Check→Act. The Codex version maps its four skills directly to one big PDCA cycle: bootstrap (Plan) → loop (Do) → consumer-qa (Check) → release (Act).

Wide context enables speed. Deep context enables safety. A project benefits from both — use the Claude version for rapid implementation, the Codex version for release gates and consumer validation.

## Why maek?

AI coding agents are powerful, but long sessions degrade. Complex tasks stall when the agent hits the same error repeatedly. And there's no built-in way to break a large task into verified, committed chunks.

maek solves this with three ideas:

- **File-based state** — Progress lives in `progress.md`, not the context window. Sessions can restart without losing work.
- **Stuck detection** — If the same error appears 3 times, maek switches strategy instead of brute-forcing.
- **Task-level verification** — Every completed task gets a build check and its own commit. Broken builds don't compound.

## Quick Start

### Claude Code

```bash
curl -fsSL https://raw.githubusercontent.com/HUA-Labs/maek/main/install.sh | bash
```

Then in Claude Code:
```
/maek https://github.com/.../issues/123
```

See [claude/README.md](./claude/) for full setup.

### Codex

Copy the skills from `codex/skills/` into your Codex skills directory. See [codex/README.md](./codex/) for details.

## How It Works

```
┌──────────────────────────────────────────────────────┐
│  maek.sh (external loop — context rotation)          │
│  ┌────────────────────────────────────────────────┐  │
│  │  AI Agent Session                              │  │
│  │  ┌──────────────────────────────────────────┐  │  │
│  │  │  maek skill (orchestrator)               │  │  │
│  │  │                                          │  │  │
│  │  │  1. Decompose task into units            │  │  │
│  │  │  2. Execute (sequential or parallel)     │  │  │
│  │  │  3. Verify build after each unit         │  │  │
│  │  │  4. Detect stuck → switch strategy       │  │  │
│  │  │  5. Commit each completed unit           │  │  │
│  │  └──────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────┘  │
│            ▲                    │                     │
│            │    .maek/          ▼                     │
│            └──  progress.md (file-based state)       │
└──────────────────────────────────────────────────────┘
```

The key insight: **the agent's memory is the filesystem, not the context window.** This enables context rotation — start fresh sessions without losing work.

## Configuration

### `.maek/config`

```bash
# Required: how to verify the build
verify=npm run typecheck && npm run build

# Optional
max_stuck_retries=3      # Retries before stuck verdict (default: 3)
parallel_threshold=2     # Independent tasks needed for parallel execution (default: 2)
auto_commit=true         # Commit after each task (default: true)
```

### Examples

See [`examples/`](./examples/) for project-specific configs:

- [Next.js / TypeScript](./examples/config-nextjs)
- [Python](./examples/config-python)
- [Rust](./examples/config-rust)
- [Go](./examples/config-go)

## Stuck Detection

maek doesn't brute-force failures. It detects when it's stuck and adapts:

| Condition | Action |
|-----------|--------|
| Same build error 3x | Switch to a different approach |
| Same file edit→revert 2x | Stop, re-analyze the problem |
| Agent failure 3x | Ask the user for help |
| progress.md unchanged 3 iterations | External loop annotates + rotates |

**Escalation order:**
1. Try a different approach based on the error
2. Read more surrounding code for context
3. Search official docs via web
4. Ask the user

## Design Principles

1. **File over memory** — State in files survives context rotation
2. **Verify everything** — Build check after every task, not just at the end
3. **Fail fast, rotate** — Stuck? Don't brute-force. Switch strategy or start fresh.
4. **Task-level commits** — Each completed task = one commit = easy rollback
5. **Platform-agnostic core** — Same philosophy, adapted to each AI platform's strengths

## Anti-Patterns

| Don't | Why |
|-------|-----|
| Skip verification between tasks | Broken builds compound; debugging becomes exponentially harder |
| Repeat the same approach when stuck | If it failed 3x, try something different |
| One giant commit for everything | Can't rollback individual tasks |
| Forget to update progress.md | Next session won't know what's done |
| Mix unrelated changes in one task | Keep tasks focused for clean commits and easy review |

## Requirements

- An AI coding agent ([Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [Codex](https://openai.com/codex))
- [GitHub CLI](https://cli.github.com/) (`gh`) — only for issue-based workflows
- Bash shell (macOS/Linux native, Windows via Git Bash or WSL)
- Git

## Inspiration

maek synthesizes ideas from:
- **Ralph Loop** by Geoffrey Huntley — The insight that an agent's memory should be the filesystem, enabling context rotation without state loss
- **Symphony** by OpenAI — The pattern of polling issues, isolating workspaces, and verifying builds as an orchestration pipeline

Neither is used directly. maek takes these concepts and implements them as lightweight skills with stuck detection and parallel execution.

## Credits

Built by [HUA Labs](https://github.com/HUA-Labs).

## License

MIT
