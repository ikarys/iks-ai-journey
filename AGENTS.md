# Agent Instructions

Canonical, tool-neutral guidance. Read natively by Cursor; symlinked into Claude
Code as `.claude/CLAUDE.md`. Mechanisms that *enforce* these (hooks, permissions)
live in `.claude/` and are Claude Code-only — this file is guidance.

## Language

- **Chat with me in English by default.**
- **All artifacts in English** regardless of chat language: code, comments, docs,
  commit messages, identifiers.
- When I write you a prompt in English, gently coach my English: if a phrasing is
  awkward or unidiomatic, suggest a cleaner version in one line, then proceed.
- **Switching chat language:** run `/chat-language <lang>` (e.g. `fr`, `es`) to
  switch the conversation language for the rest of the session. It reverts to
  English in a new session. Artifacts stay English either way.

## Workflow

- For any non-trivial task (multi-file, design choices, migrations), **prefer plan
  mode** first. Show the plan, get my approval, then execute.
- Work in small, reviewable steps. Keep diffs focused.

## Subagents — use them proactively

- **You have standing permission to spawn subagents — I do not need to ask each
  time.** When a step is self-contained and would otherwise flood the main context,
  delegate it. Saving tokens in the main thread is a valid reason on its own.
- Reach for a subagent when it genuinely helps:
  - **Broad search / exploration** — sweeping many files to find where something
    lives. Spawn a read-only explore agent and keep only its conclusion.
  - **Parallel independent work** — several unrelated lookups or edits with no
    dependency between them can run as concurrent agents.
  - **Bounded, mechanical edits** — a single well-scoped change you can hand off
    with a precise spec.
- **Don't** delegate when the task is small enough to do inline, needs the full
  conversation context to get right, or when coordinating the agent would cost more
  than just doing it. One focused agent beats several half-scoped ones.
- Always relay what matters from an agent's result — its output is not shown to me.

## Code quality

- Apply **Clean Code** and **Clean Architecture** *as you generate* — naming,
  small functions, clear boundaries, dependency direction. Don't bolt it on later.
- Favour readability and explicitness over cleverness.

## Tests

- **Do not write unit tests unless I explicitly validate it first.** Propose what
  you would test and wait for my go-ahead.

## Commits

- **Conventional Commits** always: `type(scope): subject`
  (`feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `build`, `ci`, `perf`).
- Imperative subject, no trailing period, body explains *why* when useful.

## Rules & linters — separation of concerns

- `canonical/rules/` holds **semantic / architectural** guidance only, path-scoped
  per technology.
- **Rules never duplicate linters.** Syntax, formatting, and style are owned by the
  toolchain run in hooks: `terraform fmt`/`tflint`/`tfsec`, `ruff`, `clippy`,
  `hadolint`, `kubeconform`. If a linter can catch it, the rules stay silent on it.

## Safety

- Never run destructive commands (`rm -rf`, `terraform apply/destroy`,
  `kubectl delete`) — these are denied at the harness level. Plan/diff/read only.
- Never read secrets (`.env`, `*.pem`, credentials). Treat them as opaque.
