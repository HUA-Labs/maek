# maek-loop Guide

## When To Use

Use `maek-loop` when the repo maintains lightweight planning files and you want the next verified implementation step instead of a broad plan.

Typical inputs:

- `PRD.md`
- `progress.md`
- `CURRENT.md`
- `improvements.md`
- roadmap docs under `docs/`

## What It Does

`maek-loop` turns planning context into a practical execution loop.

Its job is to:

- read the current status first
- connect product intent to the current codebase
- choose the next smallest useful slice
- avoid scope expansion too early

## Working Method

Recommended loop:

1. read the active status file
2. read the goal or product doc
3. extract the next meaningful slice
4. verify the slice against current constraints
5. implement before widening scope

## Good Output

A good `maek-loop` result should answer:

- what to do next
- why this slice is the right size
- what should wait
- what must be verified before moving on

## Common Failure Modes

- treating roadmap length as implementation scope
- following planning docs even when code drifted
- trying to solve multiple slices in one pass
- skipping verification because the plan looked clear

If planning and code disagree, the mismatch should be called out explicitly.

## Example Prompts

```text
Use $maek-loop and choose the next smallest verified implementation step.
```

```text
Use $maek-loop and turn the current PRD into a concrete task for today.
```

```text
Use $maek-loop and tell me what not to do yet.
```

## Best Pairings

- Start with `maek-bootstrap` if the repo context is not already clear.
- Follow with `maek-consumer-qa` when the slice changes public package behavior.
- Finish with `maek-release` if the slice is intended to ship now.
