# Claude Code Instructions

Read [AGENTS.md](../AGENTS.md) first — it is the canonical source of truth for
all coding conventions, workflow, language rules, and architecture guidance.

The sections below are **Claude Code-only** and not duplicated in AGENTS.md.

---

## Branch discipline
- When blocked by `check-branch.sh` (editing on `main`/`master`), **do not create
  the branch silently**. Instead, propose a branch name derived from the task
  (e.g. `feat/add-pagination`, `fix/auth-token-expiry`) and ask for confirmation
  before running `git switch -c <proposed-name>`.

## Hooks & enforcement (Claude Code only)
- `scripts/check-branch.sh` runs as PreToolUse before every edit — blocks edits on
  `main`/`master`.
- Conventional Commits and secret scanning are enforced via `.pre-commit-config.yaml`
  (hooks: `conventional-pre-commit`, `gitleaks`).
