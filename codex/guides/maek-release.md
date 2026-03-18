# maek-release Guide

## When To Use

Use `maek-release` when you need a real release decision based on evidence.

Best fit:

- package releases
- starter releases
- public API validation
- artifact consistency checks
- pre-publish triage

## What It Checks

The standard release pass should cover:

1. intended release scope
2. public exports and entry points
3. relevant build, typecheck, or test commands
4. one consumer-side smoke test when packages or starters changed
5. docs vs shipped artifact consistency
6. residual risk

## High-Risk Cases

Escalate immediately if:

- a published package cannot satisfy imports expected by another published package
- a starter app fails `install + build`
- docs promise APIs that shipped artifacts do not expose

## Good Output

A good `maek-release` result should summarize four things:

- what changed
- what was verified
- what is still risky
- what blocks release

It should end in a clear recommendation, not just raw findings.

## Example Prompts

```text
Use $maek-release and check release blockers, shipped artifacts, and residual risk.
```

```text
Use $maek-release and tell me whether docs and exports still match what users get.
```

```text
Use $maek-release and give me a ship / no-ship call with the remaining blockers.
```

## Best Pairings

- Use `maek-bootstrap` first if the package graph or repo structure is unclear.
- Use `maek-consumer-qa` when the release includes public packages, starters, or templates.
