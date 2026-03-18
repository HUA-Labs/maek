---
name: maek-release
description: Use when preparing packages, starters, or apps for release. Best for publish-readiness checks, public-private boundary validation, release risk summaries, and verifying that docs, source, and shipped artifacts still agree.
---

# maek Release

Use this for release prep and pre-publish verification.

## Goal

Decide whether something is safe to ship and what still blocks release.

## Standard Procedure

1. Confirm intended scope of release
2. Check package exports and public entry points
3. Verify targeted build, typecheck, or test commands
4. Run one consumer-side smoke test if packages or templates changed
5. Check that docs do not claim APIs missing from shipped artifacts
6. Summarize residual risk

## Risk Checks

- source exports vs published exports
- optional peer dependency degradation
- scaffold or template drift
- private files leaking into public packages
- docs ahead of the shipped bundle

## Deliverable

Summarize in four parts:

- what changed
- what was verified
- what is still risky
- what blocks release

## Escalate Immediately If

- a published package cannot satisfy imports expected by another published package
- a starter app fails `install + build`
- documentation promises APIs that shipped artifacts do not expose
