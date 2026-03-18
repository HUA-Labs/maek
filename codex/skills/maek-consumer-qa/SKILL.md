---
name: maek-consumer-qa
description: Use when validating a scaffolded app, package template, starter, or published package combination from the consumer side. Best for install, build, and runtime checks, compatibility regressions, and first QA before release.
---

# maek Consumer QA

Use this when the question is:

Can a fresh consumer install this and make it work?

## Minimum Flow

1. Create or open the consumer app
2. Install dependencies
3. Run production build
4. If build passes, run the app
5. Make one local HTTP request or equivalent runtime check

## Always Record

- scaffold command or starting point
- generated dependency ranges
- actually installed versions
- exact failing command
- whether failure is:
  - source bug
  - publish mismatch
  - template bug
  - SSR or prerender bug
  - config issue

## Heuristics

- If workspace source looks correct but installed output fails, classify as publish mismatch
- If dev works but build fails, classify as production stability issue, not total unusability
- If a starter cannot survive `install + build`, treat that as release-blocking

## Exit Criteria

A QA pass is complete only when:

- install, build, and a basic runtime check pass
- or a blocking mismatch is reproduced with commands and version evidence
