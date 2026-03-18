---
name: maek-loop
description: Use when a repository maintains lightweight planning files such as PRD, progress, improvements, roadmap, or current-context notes, and you want Codex to turn them into a practical execution loop for implementation work.
---

# maek Loop

Use this when the repo contains planning files and you want execution to stay aligned with them.

## Expected Inputs

Any of these, if present:

- `PRD.md`
- `progress.md`
- `improvements.md`
- `CURRENT.md`
- roadmap or task docs under `docs/`

## Working Method

1. Read the active status file first
2. Read the product or goal doc next
3. Extract only the next meaningful slice of work
4. Verify that proposed code changes still fit current constraints
5. Update implementation before expanding scope

## Codex Rules

- Treat planning docs as direction, not runtime truth
- Do not widen scope just because the roadmap is long
- Prefer the smallest vertical slice that can be verified
- If planning and code disagree, report the mismatch explicitly

## Best Use

- shaping the next task
- choosing what not to do yet
- connecting implementation back to product intent
