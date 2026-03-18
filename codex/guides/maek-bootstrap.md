# maek-bootstrap Guide

## When To Use

Use `maek-bootstrap` at the start of a task when:

- the repo is unfamiliar
- the repo is large and you need the shortest useful read path
- there are several docs and you need a trust order before editing

## What It Does

`maek-bootstrap` should build a minimal working model of the repository before code changes begin.

Expected focus:

- what matters now
- what files to read first
- which subtree actually contains the task
- what source wins when docs disagree

## Read Order

Recommended read order:

1. current user request
2. root `README*`
3. status files if present:
   - `CURRENT.md`
   - `progress.md`
   - `PRD.md`
   - `improvements.md`
4. task-relevant docs under:
   - `docs/`
   - `.agent-docs/`
   - `.claude/`
   - `.maek/`

Do not bulk-read the repo. Read only enough to route the task correctly.

## Source Of Truth Order

When information conflicts, prefer this order:

1. current code and build/test output
2. actual package artifacts used by the app
3. current status or memory files
4. architecture docs
5. planning docs

## Good Output

A good `maek-bootstrap` result should leave you with:

- active constraints
- likely entry points
- known unstable areas
- a short reading list
- a clear next place to inspect

## Example Prompts

```text
Use $maek-bootstrap and get me ready to work on this repository.
```

```text
Use $maek-bootstrap and tell me which files matter before I touch auth.
```

```text
Use $maek-bootstrap and identify the exact package boundary for this bug.
```

## Best Pairings

- Pair with `maek-loop` when planning files exist.
- Pair with `maek-consumer-qa` when the task affects public packages or starters.
- Pair with `maek-release` when you need a ship decision after triage.
