# maek-consumer-qa Guide

## When To Use

Use `maek-consumer-qa` when the important question is:

Can a fresh consumer actually install this, build it, and run it?

Best fit:

- scaffold tools
- starters
- templates
- published package combinations
- first QA before release

## Minimum Flow

The default flow should be:

1. create or open the consumer app
2. install dependencies
3. run a production build
4. if build passes, run the app
5. make one local HTTP request or equivalent runtime check

## Always Record

Capture these every time:

- scaffold command or starting point
- generated dependency ranges
- actually installed versions
- exact failing command
- pass/fail runtime evidence

## Issue Classification

Classify failures clearly:

- source bug
- publish mismatch
- template bug
- SSR or prerender bug
- config issue

Helpful heuristics:

- if source looks correct but installed output fails, treat it as a publish mismatch
- if dev works but build fails, treat it as production stability risk
- if a starter fails `install + build`, treat it as release-blocking

## Good Output

A good `maek-consumer-qa` result should include:

- reproduction commands
- version evidence
- the first real blocker
- whether the app was made to pass locally
- what remains an upstream issue

## Example Prompts

```text
Use $maek-consumer-qa and verify this package combination from a fresh app.
```

```text
Use $maek-consumer-qa and tell me whether this starter survives install, build, and run.
```

```text
Use $maek-consumer-qa and write a first QA report with exact commands and blockers.
```

## Best Pairings

- Start with `maek-bootstrap` to locate the exact package and template boundaries.
- Finish with `maek-release` if the QA result should drive a ship decision.
