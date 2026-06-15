# Commands

Slash commands are reusable prompt templates under
[`canonical/commands/`](../canonical/commands/). The filename maps to the command
name (`chat-language.md` → `/chat-language`). Frontmatter `description` and
`argument-hint` are shared across agents; the body is the prompt.

| Command | Does |
|---------|------|
| [`/chat-language`](../canonical/commands/chat-language.md) | Switch the chat language for the rest of the session (artifacts stay English). |

## How commands are wired per agent

| Agent | Mechanism |
|-------|-----------|
| **Claude Code** | `.claude/commands` → `../canonical/commands` symlink (created by `bootstrap.sh`) |
| **pi.dev** | `prompts[]` array in `~/.pi/agent/settings.json` points at `canonical/commands` (written by `bootstrap.sh pi`) |
| **Cursor** | n/a in this repo |

## Caveat — argument interpolation

The body uses `$ARGUMENTS` (Claude's placeholder). pi's prompt-template
substitution token may differ; if `/chat-language fr` loads but the argument is not
interpolated, the placeholder needs adapting for pi. Confirm against a live pi.

## Adding a command

Create `canonical/commands/<name>.md` with frontmatter `description` +
`argument-hint`. Picked up automatically — Claude via the symlink, pi via the
`prompts[]` path.
