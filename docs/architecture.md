# Architecture

This repo keeps **one source of truth** and adds **thin per-tool adapters** on top.
Two independent layers, each with a single source:

| Layer | What it is | Source | Nature |
|-------|-----------|--------|--------|
| **Guidance** | Markdown the LLM *reads* | [`AGENTS.md`](../AGENTS.md), [`canonical/`](../canonical/) | Portable, **soft** (the model *may* follow it) |
| **Enforcement** | Executable the *harness* runs | [`scripts/`](../scripts/), [`.pre-commit-config.yaml`](../.pre-commit-config.yaml) | Mechanism-bound, **hard** (blocks regardless of the model) |

```
GUIDANCE (markdown)                 ENFORCEMENT (executable)
canonical/ + AGENTS.md              scripts/*.sh  ← single source of logic
   │                                   │
   ├─ symlink ─→  .claude/             ├─ .claude/settings.json   (command hook)
   ├─ settings ─→ pi.dev               ├─ .pi/extensions/*.ts     (spawns the .sh)
   └─ (future)    Cursor               └─ .cursor/hooks.json      (command hook)
```

## Why two layers

- **Guidance is portable.** Every agent can read the same markdown — only the
  *delivery* differs (a symlink, a settings array, a `.mdc` file). No copies.
- **Enforcement is mechanism-bound but the *logic* need not be.** The rules live
  once in `scripts/*.sh` with a harness-neutral contract; each agent calls the same
  scripts through its own hook system. No reimplementation.

### The script contract (harness-neutral)

So one script serves every agent:

- **Output:** exit `0` = allow · exit `≠0` = block, reason on `stderr` · advisory
  text on `stdout`.
- **Input:** via env vars / args (not a harness-specific JSON schema). Scripts *may*
  best-effort parse stdin for Claude's hook contract, but never depend on it.

## Per-agent adapters

| | Guidance delivery | Enforcement delivery | Status |
|---|---|---|---|
| **Claude Code** | `.claude/` symlinks → `canonical/` + `AGENTS.md` | `.claude/settings.json` command hooks → `scripts/*.sh` | wired |
| **pi.dev** | reads `AGENTS.md` natively; `skills[]` + `prompts[]` in `~/.pi/agent/settings.json` | [`.pi/extensions/enforce.ts`](../.pi/extensions/enforce.ts) shells out to `scripts/*.sh` | wired |
| **Cursor** | reads `AGENTS.md` natively; `canonical/rules` → `.cursor/rules/*.mdc` | `.cursor/hooks.json` command hooks → `scripts/*.sh` | designed, not shipped |

Claude and Cursor share the **same** command-hook model (shell script, JSON on
stdin, block via exit code), so they reuse `scripts/*.sh` directly. pi uses
TypeScript extensions, so its adapter is a ~10-line shim that spawns the scripts.

### Cursor — open before shipping

The schema is known; two contract details need confirming against a live Cursor:

1. the `matcher` tool names for edit/write tools (wrong → fail-open, harmless);
2. how `beforeSubmitPrompt` surfaces advisory `stdout` (the pre-commit nudge).

## Adding an agent

The canonical and script layers never change — you only add an adapter:

1. **Guidance** — point the agent at `AGENTS.md` + `canonical/` its own way
   (symlink, settings path, or generated rules file).
2. **Enforcement** — call `scripts/*.sh` from the agent's hook mechanism; map exit
   code → that agent's block/allow result.
3. Wire it in [`bootstrap.sh`](../bootstrap.sh): add a key/label to the registry and
   a `setup_<agent>` function.

## See also

- [Skills](skills.md) · [Commands](commands.md) · [Rules](rules.md) ·
  [Enforcement](enforcement.md)
