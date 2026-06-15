# iks-ai-journey

A portable, multi-tool **AI agent configuration** repo. One source of truth in
tool-neutral markdown; thin per-tool adapters on top. Wired today for **Claude
Code** and **pi.dev**, with **Cursor** designed to plug in without restructuring.

## Principle

```
GUIDANCE (markdown)                 ENFORCEMENT (executable)
canonical/ + AGENTS.md              scripts/*.sh  ← single source of logic
   │                                   │
   ├─ symlink ─→  .claude/             ├─ .claude/settings.json   (command hook)
   ├─ settings ─→ pi.dev               ├─ .pi/extensions/*.ts     (spawns the .sh)
   └─ (future)    Cursor               └─ .cursor/hooks.json      (command hook)
```

Two layers, each with one source and thin per-tool adapters:

- **Guidance** is markdown the LLM reads (`AGENTS.md`, `canonical/rules`,
  `canonical/skills`). Portable: every agent reads the same files via its adapter —
  symlink (Claude), `skills[]` setting (pi), `.mdc` (Cursor). Soft: the model *may*
  follow it.
- **Enforcement** is executable the *harness* runs deterministically. The logic
  lives once in `scripts/*.sh` (exit `0`=allow, `≠0`=block, reason on stderr). Each
  agent calls the *same* scripts through its own mechanism — a command hook (Claude,
  Cursor) or a TypeScript extension that shells out (pi). Hard: it blocks regardless
  of the model. No logic is duplicated; only the wrappers differ.

## Layout

| Path | What it is |
|------|------------|
| `AGENTS.md` | Canonical agent instructions. Read **natively by Cursor**; symlinked into Claude Code as `.claude/CLAUDE.md`. |
| `canonical/rules/` | One light, **path-scoped, semantic** rule per technology (terraform, kubernetes, docker, argocd, python, rust). Architecture only — no linter duplication. |
| `canonical/skills/` | All skills, one folder each (`SKILL.md` + optional `template.md`): `adr/`, `agentsmd-generator/`, `git-smart-commit/`, `jira-ticket-creation/`, `precommit-setup/`. |
| `canonical/commands/` | Tool-neutral slash commands (e.g. `chat-language.md`). |
| `.claude/CLAUDE.md` | → `../AGENTS.md` (symlink) |
| `.claude/rules/` · `.claude/skills/` · `.claude/commands/` | → matching `../canonical/*` (symlinks) |
| `.claude/agents/code-reviewer.md` | Read-only review subagent (`tools: Read, Grep, Glob`). |
| `.claude/settings.json` | Permissions (deny destructive/secret-reading, allow read-only) + `PreToolUse`/`UserPromptSubmit` command hooks → `scripts/*.sh`. |
| `.pi/extensions/enforce.ts` | pi enforcement adapter: a TypeScript shim that shells out to the same `scripts/*.sh` and maps the result to pi's `{ block, reason }`. |
| `scripts/check-branch.sh` | Block edits on `main`/`master`; escape hatch `ALLOW_MAIN_EDITS=1`. Harness-neutral (uses `git`, ignores stdin). |
| `scripts/check-precommit.sh` | Nudge `/precommit-setup` when no complete `.pre-commit-config.yaml`; throttled once per session via `$PRECOMMIT_SESSION_ID`. |
| `.pre-commit-config.yaml` | Git-native enforcement for **everyone** (agents + humans): Conventional Commits + `gitleaks` secret scan. |
| `bootstrap.sh` | Idempotently wire each selected agent: Claude symlinks, pi `skills[]` + `prompts[]`. (`.pi/extensions/` is auto-discovered by pi — nothing to wire.) |

## Setup

```bash
./bootstrap.sh
```

Run it after every fresh clone. It is idempotent and **required on Windows**, where
clones often don't preserve symlinks — `bootstrap.sh` recreates them. It also fixes
executable bits. Commit-time enforcement is wired separately via `pre-commit install`
against `.pre-commit-config.yaml` (see `/precommit-setup`).

### Optional tools the hooks use (all best-effort)

Hooks skip any tool that isn't installed, so nothing here is mandatory:
`terraform`, `tflint`, `tfsec`, `ruff`, `rustfmt`, `clippy`, `hadolint`,
`kubeconform`, `shfmt`, `shellcheck`, `jq`, `gitleaks`.

## Design rules

- **Rules are semantic/architectural only.** Syntax, formatting and style are
  deferred to the toolchain run in hooks (`terraform fmt`/`tflint`/`tfsec`, `ruff`,
  `clippy`, `hadolint`, `kubeconform`). A rule never restates what a linter checks.
- **Public-safe.** No company names, clusters, accounts, or internal patterns —
  dummy/generic examples only (`service-a`, `region-x`).
- **Guidance vs. enforcement** are kept separate so guidance stays portable.

## Roadmap — adding more tools

The canonical layer never changes; you only add adapters.

- **pi.dev** — *wired*. Reads `AGENTS.md` natively; `bootstrap.sh pi` registers
  `canonical/skills/` (as `skills[]`) and `canonical/commands/` (as `prompts[]`, so
  slash commands like `/chat-language` work) in `~/.pi/agent/settings.json`, and the
  `.pi/extensions/enforce.ts` shim runs the same `scripts/*.sh` as Claude. Same
  guidance, same commands, same enforcement logic — no copies.
- **Cursor** — *designed, not yet wired*. Reads `AGENTS.md` natively; rules map
  `canonical/rules/*.md` front-matter `paths:` → `.cursor/rules/*.mdc` `globs:`.
  Enforcement reuses `scripts/*.sh` directly: Cursor's command hooks (`.cursor/
  hooks.json`, `preToolUse` → `check-branch.sh`) share Claude's exit-code contract.
  Two open contract details to confirm against a live Cursor before shipping the
  config: the `matcher` tool names for edit tools, and how `beforeSubmitPrompt`
  surfaces advisory stdout.

Adding a tool = one new adapter + a few lines in `bootstrap.sh`. The source of truth
(guidance in `canonical/`, logic in `scripts/`) stays untouched.
