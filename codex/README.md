# maek for Codex

Codex-oriented version of `maek`.

This subtree is for Codex only. Claude-specific setup at the repository root stays separate.

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
