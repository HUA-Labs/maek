# maek Detailed Guide

This guide covers advanced patterns, real-world lessons, and troubleshooting from 30+ production sessions on a Next.js monorepo with 20+ packages.

## Table of Contents

- [Context Control Patterns](#context-control-patterns)
- [Project Setup](#project-setup)
- [Writing Effective PRDs](#writing-effective-prds)
- [Task Decomposition Patterns](#task-decomposition-patterns)
- [Stuck Detection Deep Dive](#stuck-detection-deep-dive)
- [Context Rotation](#context-rotation)
- [Parallel Execution](#parallel-execution)
- [Monorepo Patterns](#monorepo-patterns)
- [Orchestration Rules](#orchestration-rules)
- [Common Pitfalls](#common-pitfalls)
- [Troubleshooting](#troubleshooting)

---

## Context Control Patterns

The core insight behind maek is that **an AI agent's memory should be the filesystem, not the context window.** This principle applies far beyond automated loops — it's a general pattern for working with any AI coding agent across sessions.

### The Three Layers

```
┌─────────────────────────────────────────┐
│  MEMORY.md     Long-term knowledge      │  Persists forever
│                (user prefs, decisions,   │  Updated rarely
│                 architecture choices)    │
├─────────────────────────────────────────┤
│  CURRENT.md    Session context          │  Persists across sessions
│                (active work, next TODOs, │  Updated each session
│                 warnings, blockers)      │
├─────────────────────────────────────────┤
│  progress.md   Task execution state     │  Persists during a task
│                (task list, stuck log,    │  Deleted when done
│                 completion status)       │
└─────────────────────────────────────────┘
```

Each layer has a different lifespan and purpose:

| File | Scope | Lifespan | Who Updates |
|------|-------|----------|-------------|
| `MEMORY.md` | Project-wide knowledge | Permanent | Agent + human |
| `CURRENT.md` | Active work context | Multi-session | Agent at session end |
| `progress.md` | Single task execution | Single task | maek automatically |

### MEMORY.md — Long-Term Knowledge

Stores things the agent should always know but can't derive from code:

```markdown
# Project Memory

## User Preferences
- Korean casual tone, no emoji
- Commit messages always in English

## Architecture Decisions
- text-primary is NOT for text (low contrast) — use text-foreground
- motion-core is optional peer dep of hua-ui

## External References
- Pipeline bugs tracked in Linear project "INGEST"
- Oncall dashboard: grafana.internal/d/api-latency
```

**What belongs here:** User preferences, team decisions, external system pointers, past incidents.

**What doesn't:** Code patterns (read the code), git history (use git log), debugging recipes (the fix is in the code).

### CURRENT.md — Session Context

The handoff document between sessions. When a new session starts, reading this file should give the agent full context to continue work.

```markdown
# Current Context

**Last updated**: 2024-03-18 (Session 31)

## Completed
- PR #647: Phase A/B/C normalization (MERGED)

## In Progress
- Phase D/E/F: disabled, colors, form size

## Next TODO
- [ ] Publish motion-core 2.5.0
- [ ] Fix NextAuth Turbopack build issue

## Warnings
- sum-diary build broken on main (NextAuth dep issue, not our code)
- sync-to-public.sh uses ALLOWLIST — add new public files explicitly
```

**Key principle:** CURRENT.md is a **lossy summary**. It captures what the code and git log can't tell you — the *why*, the *what's next*, and the *watch out for*.

### progress.md — Task Execution State

maek's automated state file. Tracks task-level progress within a single feature:

```markdown
# maek Progress
## Source: https://github.com/.../issues/123
## Started: 2024-03-18T14:00

### Tasks
- [x] T1: Add shared types (5 files)
- [ ] T2: Implement API routes (8 files) ← current
- [ ] T3: Add frontend components (6 files)

### Stuck Log
- 14:30 T2: `Module not found: @auth/core` → added to serverExternalPackages
```

### Combining the Layers

In practice, you use all three:

1. **Start of session**: Read MEMORY.md (who am I working with?) → Read CURRENT.md (what's the state?) → Resume or start new work
2. **During work**: maek manages progress.md automatically
3. **End of session**: Update CURRENT.md with what happened and what's next

This pattern works with any AI agent — Claude, Codex, Copilot, or whatever comes next. The files are plain markdown. The agent is interchangeable; the context is permanent.

### Adopting This Without maek

You don't need maek to use these patterns. At minimum:

1. Create a `CURRENT.md` in your project (or `.claude/memory/CURRENT.md`, or wherever your agent reads)
2. At the end of each session, ask the agent to update it
3. At the start of each session, the agent reads it first

That alone eliminates 80% of the "context loss between sessions" problem.

---

## Project Setup

### Verify Command

The verify command is the single most important configuration. It should:

1. **Typecheck first** — catches most errors cheaply
2. **Lint second** — catches style and import issues
3. **Build last** — full verification

```bash
# Good: layered verification
verify=npx tsc --noEmit && npx eslint . --quiet && npm run build

# Good: monorepo with filter
verify=pnpm typecheck && pnpm build --filter my-app

# Bad: build only (misses type errors that build ignores)
verify=npm run build

# Bad: too slow (runs everything including e2e)
verify=npm run test && npm run build && npm run e2e
```

Keep the verify command under 60 seconds. If it's slow, filter to the relevant package.

### Config File

`.maek/config` supports these keys:

```bash
verify=<command>          # Required
max_stuck_retries=3       # Default: 3
parallel_threshold=2      # Min tasks for parallel mode. Default: 2
auto_commit=true          # Commit after each task. Default: true
```

### Gitignore

Always gitignore runtime state:

```
.maek/progress.md
.maek/loop.log
```

But do NOT gitignore `.maek/config` or `.maek/PRD.md` — these are project configuration.

---

## Writing Effective PRDs

### Structure

```markdown
# Feature Name

## Goal
One sentence. What does "done" look like?

## Requirements
- Specific, implementable items
- Each should map to roughly 1 task (5-15 files)
- Include technical constraints (e.g., "must work with React 19")

## Out of Scope
- Things explicitly NOT to do
- Prevents the agent from scope-creeping

## Verification
How to know it works (beyond just building).
```

### Good vs Bad Requirements

**Good** (implementable, bounded):
- "Add `size` prop to Input component with sm/md/lg variants matching Select's API"
- "Replace all `#22c55e` with `var(--color-success)` in hua-ui components"

**Bad** (vague, unbounded):
- "Improve the UI" — improve how?
- "Refactor the codebase" — which part? What's the goal?
- "Make it faster" — what metric? What target?

### The "Zero Goals" Anti-Pattern

Never give the agent optional goals. If something is listed, it must be done.

Bad: "Fix these errors if you have time"
Good: "Fix all 5 type errors in Input.tsx. Do not skip any."

Agents will skip "optional" work. Be explicit about every goal.

---

## Task Decomposition Patterns

### Small Feature (3-5 files)

Don't decompose. Use `auto-impl` directly.

### Medium Feature (10-20 files)

Split into 2-3 sequential tasks:

```markdown
- [ ] T1: Add shared types and utilities (5 files)
- [ ] T2: Implement components using T1 types (8 files)
- [ ] T3: Add tests (4 files)
```

### Large Feature (30+ files)

Split into independent areas for parallel execution:

```markdown
- [ ] T1: Shared types and interfaces (foundation)
- [ ] T2: Backend API routes (depends: T1)
- [ ] T3: Frontend components (depends: T1, parallel with T2)
- [ ] T4: Tests (depends: T2, T3)
```

### Cross-Package Changes (monorepo)

Each package change should be a separate task with its own build verification:

```markdown
- [ ] T1: Update @hua-labs/ui (verify: pnpm build --filter @hua-labs/ui)
- [ ] T2: Update sum-diary to use new API (verify: pnpm build --filter sum-diary)
```

---

## Stuck Detection Deep Dive

### How It Works

maek tracks two things:
1. **Error history** — build error messages across verify runs
2. **Edit history** — which files were modified and reverted

### Detection Rules

| Signal | Threshold | Verdict |
|--------|-----------|---------|
| Same error message | 3 consecutive | **stuck** |
| Edit file → revert same file | 2 cycles | **thrashing** |
| Subagent returns failure | 3 times | **escalate** |
| progress.md unchanged | 3 loop iterations | **stall** (external loop only) |

### Escalation Strategy

When stuck is detected, maek tries these in order:

1. **Different approach** — If import fails, try a different module. If type fails, try a different interface.
2. **More context** — Read surrounding code, check how similar things are done elsewhere.
3. **Web search** — Search official documentation (only results from past year).
4. **Ask user** — Summarize what was tried and what failed. This is the last resort.

### Stuck Log

Every stuck event is logged in `progress.md`:

```markdown
### Stuck Log
- 2024-03-18T14:30 T2: `Cannot find module '@auth/core'` → switched to direct import
- 2024-03-18T14:45 T2: same error → searched docs, found serverExternalPackages config
- 2024-03-18T15:00 T2: resolved after adding to next.config.ts
```

This log carries across context rotations, so the next session knows what was already tried.

---

## Context Rotation

### Why It's Needed

AI agents degrade over long sessions:
- Context window fills up with failed attempts
- Attention drifts from the original goal
- Repeated errors lead to increasingly desperate (and wrong) fixes

### How maek.sh Solves It

The external loop starts a **fresh agent session** for each iteration:

```
Iteration 1: Fresh session → reads progress.md → works on T1 → completes → updates progress.md
Iteration 2: Fresh session → reads progress.md → works on T2 → gets stuck → logs stuck → updates
Iteration 3: Fresh session → reads progress.md → sees stuck log → tries different approach for T2
```

Each iteration has the full context budget. State is carried via files, not memory. This works with any AI agent that can read/write files.

### When to Use External Loop vs Interactive

| Situation | Use |
|-----------|-----|
| Quick fix (1-3 tasks) | `/maek` interactive |
| Large feature (5+ tasks) | `maek.sh` external loop |
| Debugging a stubborn issue | `/maek` interactive (you can intervene) |
| Overnight batch work | `maek.sh --max-iterations 20` |

---

## Parallel Execution

### When to Parallelize

Use parallel execution when:
- 2+ tasks are **truly independent** (different files)
- Tasks don't have data dependencies
- Combined file count is manageable (< 30 files total)

### Isolation Strategies

**Same workspace** (most common):
- Tasks touch different directories
- No shared file modifications
- Example: backend API + frontend component

**Worktree isolation** (for risky splits):
- Tasks might touch the same files
- Changes could conflict
- Example: two components that share a utility file

### Real-World Example

From HUA Platform Session 29 — 4 parallel worktree agents:

```
Agent 1 (worktree): Card padding normalization
Agent 2 (worktree): Text line-height defaults
Agent 3 (worktree): Pressable hover/active feedback
Agent 4 (worktree): Form useId auto-generation
```

Each in its own worktree → no conflicts → merged one by one with build verification between each.

---

## Monorepo Patterns

### Build Verification

In a monorepo, always verify the specific package:

```bash
verify=pnpm build --filter @my-org/changed-package
```

Don't verify the entire monorepo unless you're making cross-package changes.

### Dependency Ordering

When changing a shared package, verify consumers too:

```bash
# Changed @hua-labs/ui → verify ui first, then apps that use it
verify=pnpm build --filter @hua-labs/ui && pnpm build --filter sum-diary
```

### Scope Discipline

**The worktree rule**: If you're working on package A and want to also fix something in package B — don't. Create a separate task or PR. Mixing scopes leads to painful reverts.

---

## Orchestration Rules

Rules of thumb for choosing the right tool:

| Situation | Tool |
|-----------|------|
| 1-2 simple tasks | Direct implementation (no maek needed) |
| 3-5 sequential tasks | `/maek` interactive |
| 5+ tasks spanning sessions | `maek.sh` external loop |
| 3+ independent tasks | `parallel-impl` agent |
| Bug from GitHub issue | `fix-issue` agent |
| Need codebase understanding first | `Explore` agent, then implement |

---

## Common Pitfalls

### 1. Skipping Verification

Every task must be verified before moving on. Broken builds compound — if T1 breaks the build and T2 also breaks it, you'll spend 10x longer debugging T2's error because it's layered on T1's.

### 2. Too-Large Tasks

If a task involves > 15 files, split it. Large tasks hit context limits and produce worse code.

### 3. Forgetting progress.md

If you're using the external loop and don't update progress.md, the next session will redo all the work. Always mark completed tasks.

### 4. Fighting the Stuck Detector

If maek says it's stuck, trust it. Don't manually retry the same approach — try something genuinely different.

### 5. Background Agent Edits

When delegating to background agents: **new file creation (Write) is safe in background.** But **editing existing files (Edit) in background can lose changes** if the foreground also modifies them. Keep edits in foreground.

---

## Troubleshooting

### "verify command not found"

Create `.maek/config`:
```bash
mkdir -p .maek
echo 'verify=npm run build' > .maek/config
```

### "progress.md not updating"

Check that the skill has write access to `.maek/`. In Claude Code, the first write may require user approval.

### "External loop keeps restarting the same task"

The session isn't updating progress.md before exiting. Check:
1. Is `.maek/progress.md` writable?
2. Is the verify command failing (preventing the task from being marked complete)?
3. Is the task too large for one session?

### "Agent keeps making the same mistake"

This is the stuck detector's job. If it's not triggering:
1. Check if the error messages are slightly different each time (bypasses exact-match detection)
2. Manually add to the Stuck Log: `- [timestamp] T1: <error> → tried X, didn't work`
3. Give more explicit constraints in the task description

### "Parallel tasks conflict on the same file"

Use worktree isolation:
```
Agent(subagent_type="auto-impl", isolation="worktree", prompt="...")
```

Or restructure the tasks so they don't touch the same files.
