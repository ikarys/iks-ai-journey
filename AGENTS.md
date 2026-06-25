# Agent Instructions

Canonical, tool-neutral guidance. Read natively by Cursor; symlinked into Claude
Code as `.claude/CLAUDE.md`. The mechanisms that *enforce* these (hooks,
permissions) live in `.claude/` and are Claude Code-only — this file is guidance.

## Language

- **Chat in English by default.**
- **All artifacts in English** regardless of chat language: code, comments, docs,
  commit messages, identifiers.
- Coach my English: if a phrasing is awkward or unidiomatic, suggest a cleaner
  version in one line, then proceed.
- **Switch chat language:** `/chat-language <lang>` (e.g. `fr`, `es`) for the rest
  of the session; reverts to English in a new session. Artifacts stay English.

## Workflow

- Non-trivial task (multi-file, design choices, migrations) → **prefer plan mode**:
  show the plan, get approval, then execute.
- Work in small, reviewable steps. Keep diffs focused.

## Subagents — use them proactively

- **Standing permission to spawn subagents — don't ask each time.** Delegate any
  self-contained step that would otherwise flood the main context. Saving main-thread
  tokens is reason enough.
- Reach for one when it helps:
  - **Broad search / exploration** — sweeping many files. Spawn the read-only
    `explore` agent (Haiku) and keep only its conclusion.
  - **Parallel independent work** — unrelated lookups/edits as concurrent agents.
  - **Bounded mechanical edits** — one well-scoped change handed off with a spec.
- **Don't** delegate when the task is small enough inline, needs full conversation
  context, or coordination costs more than doing it. One focused agent beats several
  half-scoped ones.
- Always relay what matters from a result — the agent's output is not shown to me.

## Token economy

- **Minimize token/cost.** Don't use a large model where a smaller one suffices.
- Cheaper capable model for implementation and mechanical work; top model for
  planning and hard debugging. In Claude Code: Sonnet by default, Opus on demand via
  `/model`. No automatic routing — session model plus discipline.
- Keep context lean: `/fresh` (`/clear` on task switch, `/compact` mid-long-task).
- **Default to prose-compression when available.** In Claude Code the caveman plugin
  provides it — default to caveman **full** without being asked; I adjust intensity
  on the fly (`lite`/`full`/`ultra`/`wenyan-*` or off). Compress prose only — keep
  code, paths, commands, and error strings verbatim.

## Code quality

- Apply **Clean Code** and **Clean Architecture** *as you generate* — naming, small
  functions, clear boundaries, dependency direction. Don't bolt it on later.
- Favour readability and explicitness over cleverness.

## Tests

- **No unit tests unless I explicitly validate first.** Propose what you'd test and
  wait for my go-ahead.

## Commits

- **Conventional Commits** always: `type(scope): subject`
  (`feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `build`, `ci`, `perf`).
- Imperative subject, no trailing period; body explains *why* when useful.

## Rules & linters — separation of concerns

- `canonical/rules/` holds **semantic / architectural** guidance only, path-scoped
  per technology.
- **Rules never duplicate linters.** Syntax, formatting, and style belong to the
  toolchain in hooks: `terraform fmt`/`tflint`/`tfsec`, `ruff`, `clippy`, `hadolint`,
  `kubeconform`. If a linter can catch it, the rules stay silent.

## Safety

- Never run destructive commands (`rm -rf`, `terraform apply/destroy`,
  `kubectl delete`) — denied at the harness level. Plan/diff/read only.
- Never read secrets (`.env`, `*.pem`, `*.key`, `*.crt`, credentials, any file whose
  name contains `secret`) — denied at the harness level. Treat them as opaque.
