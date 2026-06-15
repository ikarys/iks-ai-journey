# Enforcement

Enforcement is executable the *harness* runs deterministically — it blocks
regardless of what the model decides. The logic lives once in
[`scripts/`](../scripts/) with a harness-neutral contract; each agent calls the same
scripts through its own hook mechanism. See [Architecture](architecture.md).

## The contract

- **Output:** exit `0` = allow · exit `≠0` = block, reason on `stderr` · advisory
  text on `stdout`.
- **Input:** via env vars / args. Scripts *may* best-effort parse stdin for Claude's
  hook payload, but never depend on it.

## Scripts

| Script | Policy |
|--------|--------|
| [check-branch.sh](../scripts/check-branch.sh) | Block edits on `main` / `master`. Escape hatch: `ALLOW_MAIN_EDITS=1`. Uses `git`, ignores stdin — portable as-is. |
| [check-precommit.sh](../scripts/check-precommit.sh) | Nudge `/precommit-setup` when no complete `.pre-commit-config.yaml`. Throttled once per session via `$PRECOMMIT_SESSION_ID` / `$1` / stdin / per-day key. |

## Per-agent adapters

| Agent | How it calls the scripts |
|-------|--------------------------|
| **Claude Code** | `.claude/settings.json` → `PreToolUse` (`Edit\|Write\|NotebookEdit`) runs `check-branch.sh`; `UserPromptSubmit` runs `check-precommit.sh`. Blocks on exit `2`. |
| **pi.dev** | [`.pi/extensions/enforce.ts`](../.pi/extensions/enforce.ts): `tool_call` → `check-branch.sh` → `{ block, reason }`; `before_agent_start` → `check-precommit.sh` → injected note. Auto-discovered. |
| **Cursor** | `.cursor/hooks.json` → `preToolUse` → `check-branch.sh` (designed, not shipped — see [Architecture](architecture.md#cursor--open-before-shipping)). |

## Git-native enforcement (everyone)

[`.pre-commit-config.yaml`](../.pre-commit-config.yaml) runs at the **git** layer, so
it applies to agents *and* humans, any client: Conventional Commits + `gitleaks`
secret scan. Activate with `pre-commit install` (the `precommit-setup` skill
scaffolds it). Commit-time policies belong here; runtime policies (no `rm -rf`, no
secret reads, no edits on `main`) belong in the per-agent scripts above.

## Read-only review subagent

[`.claude/agents/code-reviewer.md`](../.claude/agents/code-reviewer.md) — a
read-only reviewer (`tools: Read, Grep, Glob`) that reports correctness, security,
clarity, and architecture findings without editing. Claude-specific format; the
persona is portable.

## Adding a check

1. Add `scripts/<check>.sh` honouring the contract (exit code + reason; input via
   env/args).
2. Wire it into each agent's hook mechanism (Claude `settings.json`, pi
   `enforce.ts`, Cursor `hooks.json`).
