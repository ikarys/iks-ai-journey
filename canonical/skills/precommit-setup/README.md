# pre-commit Setup Skill

Scaffold a production-grade `.pre-commit-config.yaml` tailored to the current repo,
then optionally install the hooks.

## Install

Create a file `SKILL.md` in a specific folder to be able to use it.

### Example
- Cursor: `.cursor/skills/precommit-setup/SKILL.md`
- Pi: `~/.pi/agent/skills/precommit-setup/SKILL.md` (global) or `.pi/skills/precommit-setup/SKILL.md` (project)
- Claude Code: `~/.claude/skills/precommit-setup/SKILL.md`

## Usage

In Cursor, Pi, or Claude Code, simply ask:
- "Set up pre-commit for this repo"
- "Add a pre-commit config"
- "Scaffold gitleaks and conventional-commit hooks"

The agent will automatically load the skill if the description matches.
If it doesn't, force it with `/skill:precommit-setup` (Pi) or `@file:.cursor/skills/precommit-setup/SKILL.md` (Cursor).

## What It Does

1. Detects the project stack (Python, Node/TS, Go, Shell, Terraform, Docker, …)
2. Always includes a base set of hooks:
   - **Secrets:** gitleaks
   - **Hygiene:** end-of-file-fixer, trailing-whitespace, check-yaml/json/toml,
     check-merge-conflict, check-added-large-files
   - **Commits:** conventional-pre-commit (commit-msg stage)
3. Adds stack-specific hooks (ruff, shellcheck, markdownlint, terraform, hadolint, …)
4. Writes the config (after confirmation), then offers to run `pre-commit install`

## What It Does NOT Do

- Does not `git add` or commit the new config — you do that
- Does not install the `pre-commit` tool itself (only suggests the command)
- Does not add Node linters (prettier, eslint) automatically — too project-specific
- Does not auto-fix hook failures (e.g. gitleaks may surface real secrets)
