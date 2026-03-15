---
name: maek
description: "maek (脈) — Autonomous implementation loop. Task decomposition, stuck detection, context rotation, build verification."
user-invocable: true
---

# maek — Autonomous Implementation Loop

## RULES (always follow)

- ALWAYS run verify command after each task (from `.maek/config`)
- ALWAYS update `.maek/progress.md` after completing a task
- Same build error 3x → SWITCH STRATEGY, do not repeat
- Same file edit→revert 2x → STOP and re-analyze
- 1 task = 1 commit. Never batch into one giant commit.

## Load

1. Input: `$ARGUMENTS` as URL → file path → `.maek/PRD.md` → ask user
2. Resume: `.maek/progress.md` exists? Read it, skip completed tasks
3. Config: read `.maek/config` for `verify=` command. Missing? Ask user, create it.

## Decompose

Break input into tasks. Write `.maek/progress.md`:

```markdown
# maek Progress
## Source: [url or path]
## Started: [timestamp]
### Tasks
- [ ] T1: [description] (files: ~N)
- [ ] T2: [description] (files: ~N, depends: T1)
### Stuck Log
```

Order: foundation → core → follow-up. Each task = 5–15 files max.

## Execute

For each incomplete task in progress.md:

| Situation | Do |
|-----------|-----|
| Single task | `Agent(subagent_type="auto-impl", prompt="...")` or implement directly |
| 2+ independent tasks | `Agent(subagent_type="parallel-impl", prompt="...")` or launch multiple `Agent()` |
| Bug fix from issue | `Agent(subagent_type="fix-issue", prompt="...")` |
| Need to explore first | `Agent(subagent_type="Explore", prompt="...")` |

Then verify: `Bash("<verify command from config>")`

## Stuck Detection

| Condition | Action |
|-----------|--------|
| Same build error 3x | Switch approach |
| File edit→revert 2x | Re-analyze problem |
| Agent failure 3x | Ask user |

Escalation order:
1. Different approach based on error message
2. Read more surrounding code
3. WebSearch official docs (ignore info older than 1 year)
4. Ask user with summary of what was tried

Log to Stuck Log section: `- [timestamp] T2: error → action taken`

## After Each Task

1. Verify passes → mark `- [x]` in progress.md
2. Commit: `feat(scope): [description]`
3. Next task

When all tasks complete or session ending → update progress.md with final status.
