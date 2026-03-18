---
name: maek-bootstrap
description: Use when starting work in an unfamiliar or partially familiar repository and you need to establish the current context, active priorities, source-of-truth order, and which local docs to read first before coding.
---

# maek Bootstrap

Use this at the beginning of a repository task.

## Goal

Build a minimal working model of the repo before making changes.

## Read Order

1. Current task request
2. Root `README*`
3. Project status files if present:
   - `CURRENT.md`
   - `progress.md`
   - `PRD.md`
   - `improvements.md`
4. Task-relevant docs under:
   - `docs/`
   - `.agent-docs/`
   - `.claude/`
   - `.maek/`

Do not bulk-read everything. Read only enough to route the task correctly.

## Source Of Truth Order

When information conflicts, trust sources in this order:

1. Current code and test/build output
2. Package artifacts actually used by the app
3. Active status or memory files
4. Architecture docs
5. Product planning docs

## Extract Only

- current priorities
- hard constraints
- package or runtime boundaries
- relevant entry points
- known unstable areas

## Codex Rules

- Prefer verification over recall
- Keep notes short and operational
- Separate source behavior from shipped-artifact behavior
- If the repo is large, identify the exact sub-tree before deep reading
