# maek for Claude Code

Claude Code-oriented version of maek. This is the original implementation.

## Components

### Skill

`claude/skill/SKILL.md` — The `/maek` slash command. Orchestrates task decomposition, stuck detection, and context rotation.

Install to `.claude/skills/maek/SKILL.md` in your project.

### Agents

Custom [Claude Code agents](https://docs.anthropic.com/en/docs/claude-code/agents) that the `/maek` skill delegates work to:

| Agent | File | Role |
|-------|------|------|
| `auto-impl` | `claude/agents/auto-impl.md` | Implement a feature autonomously, iterate until build passes |
| `parallel-impl` | `claude/agents/parallel-impl.md` | Split complex work into independent areas, implement concurrently |
| `fix-issue` | `claude/agents/fix-issue.md` | Analyze a GitHub issue, find and fix the bug, prepare commit |

Install all to `.claude/agents/` in your project.

### External Loop

`maek.sh` (at repo root) — Headless loop for long-running tasks. Starts fresh Claude Code sessions with context rotation via `progress.md`.

## Install

```bash
cd /path/to/your/project
mkdir -p .claude/skills/maek .claude/agents

# Skill
cp /path/to/maek/claude/skill/SKILL.md .claude/skills/maek/SKILL.md

# Agents
cp /path/to/maek/claude/agents/*.md .claude/agents/

# External loop (optional)
cp /path/to/maek/maek.sh scripts/maek.sh
chmod +x scripts/maek.sh
```

Or use the one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/HUA-Labs/maek/main/install.sh | bash
```

## Usage

**Interactive** (inside Claude Code):
```
/maek                                    # From .maek/PRD.md
/maek https://github.com/.../issues/123  # From GitHub issue
/maek path/to/requirements.md            # From any file
```

**Headless** (external loop):
```bash
./scripts/maek.sh                        # From .maek/PRD.md
./scripts/maek.sh --issue 123            # From GitHub issue
./scripts/maek.sh --max-iterations 10    # Limit iterations
```

## How It Differs from the Codex Version

| Aspect | Claude Code | Codex |
|--------|------------|-------|
| Architecture | 1 skill + 3 agents + bash loop | 4 separate skills + guides |
| Focus | Autonomous execution | Judgment and verification |
| Stuck detection | Built-in (3x error → strategy switch) | Manual via loop skill |
| Context rotation | External bash loop | N/A (Codex manages sessions) |
| Parallel execution | Agent tool with concurrent subagents | N/A |
| Agent delegation | auto-impl, parallel-impl, fix-issue | N/A (single-skill execution) |

## Battle-Tested

This version has been used in 30+ production sessions on the [HUA Platform](https://github.com/HUA-Labs/HUA-platform) monorepo (Next.js, 20+ packages, 50k+ LOC). Key patterns discovered through real usage:

- **Worktree isolation** for scope-crossing changes
- **Orchestration rules**: 5+ tasks → maek, 3+ independent → parallel agents
- **Background agent gotcha**: Edit on existing files must be foreground (Write for new files is OK in background)
- **"Zero goals" anti-pattern**: Always give agents explicit, non-skippable goals
