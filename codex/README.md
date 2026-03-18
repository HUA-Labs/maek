# maek for Codex

Codex-oriented version of `maek`.

This subtree is for Codex only. Claude-specific setup at the repository root stays separate.

## Who This Is For

Use this if you want Codex to work like a repo operator, not just a code generator.

Best fit:

- large repos with several active docs
- package or starter workflows
- release checks that need evidence
- teams that want short, repeatable prompt patterns

## Included Skills

- `maek-bootstrap`
- `maek-loop`
- `maek-consumer-qa`
- `maek-release`

## Install

Install each skill folder under `$CODEX_HOME/skills`.

Source folders:

- `codex/skills/maek-bootstrap`
- `codex/skills/maek-loop`
- `codex/skills/maek-consumer-qa`
- `codex/skills/maek-release`

Target layout:

```text
$CODEX_HOME/skills/
|-- maek-bootstrap/
|-- maek-loop/
|-- maek-consumer-qa/
`-- maek-release/
```

Do not install the whole `codex/` folder as one skill.

## Usage

Mention the skill name directly in the prompt.

Example:

```text
Use $maek-bootstrap and establish repo context before editing code.
```

Prompting tip:

- name the skill
- state the immediate goal
- state the output you want back

Example:

```text
Use $maek-consumer-qa and verify whether this starter survives install, build, and one runtime check. Write the result as a short QA report.
```

Recommended order:

1. `maek-bootstrap`
2. `maek-loop`
3. `maek-consumer-qa` when packages or starters changed
4. `maek-release` before shipping

## Guides

- [maek-bootstrap guide](./guides/maek-bootstrap.md)
- [maek-loop guide](./guides/maek-loop.md)
- [maek-consumer-qa guide](./guides/maek-consumer-qa.md)
- [maek-release guide](./guides/maek-release.md)

## Boundary

This is not a direct Claude port. It keeps the same spirit, but the Codex version is smaller, more execution-focused, and grounded in current code and build output.
