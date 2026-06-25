---
name: precommit-setup
description: >
  Scaffold a complete .pre-commit-config.yaml for the current git repo: gitleaks
  (secrets), file hygiene (end-of-file-fixer, trailing-whitespace,
  check-yaml/json/merge-conflict), conventional-pre-commit, plus stack-specific
  hooks (ruff, shellcheck, markdownlint, terraform, etc.) by detected project type.
  Use when asked to set up pre-commit, or when /precommit-setup is invoked.
---

# Skill: pre-commit Setup

Scaffold a production-grade `.pre-commit-config.yaml` tailored to the current
repo, then optionally install the hooks.

---

## Step 0 — Guard rails

Before starting:

```bash
git rev-parse --is-inside-work-tree
```

If not a git repo → stop: "Not inside a git repo. pre-commit requires git."

If `.pre-commit-config.yaml` already exists:

- Show its current content.
- Ask: "A config already exists. Overwrite / merge / cancel?"
  - **Overwrite**: generate fresh config, replace file.
  - **Merge**: add missing hooks to existing config, preserve custom entries.
  - **Cancel**: stop.

---

## Step 1 — Detect project stack

Scan the repo root and immediate subdirectories for stack signals:

| Stack | Signals |
|-------|---------|
| Python | `pyproject.toml`, `requirements*.txt`, `setup.py`, `*.py` files |
| Node/JS/TS | `package.json`, `*.js`, `*.ts`, `.eslintrc*`, `.prettierrc*` |
| Go | `go.mod` |
| Shell | `*.sh` files, `bin/` directory with executable scripts |
| Terraform | `*.tf`, `terraform.tfvars` |
| Markdown | `*.md` files (almost always present) |
| Docker | `Dockerfile*`, `docker-compose*.y*ml` |
| YAML-heavy | `*.yaml`/`*.yml` prevalence (k8s, ArgoCD, Helm) |

Collect all matching stacks — a repo can be multi-stack.

---

## Step 2 — Build the config

Assemble the config from blocks below. Always include **base hooks**; add
**stack hooks** for each detected stack.

### Base hooks (always included)

```yaml
repos:
  # ── File hygiene ────────────────────────────────────────────────────────────
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: mixed-line-ending
        args: [--fix=lf]
      - id: check-merge-conflict
      - id: check-added-large-files
        args: [--maxkb=500]
      - id: check-yaml
      - id: check-json
      - id: check-toml

  # ── Secrets ─────────────────────────────────────────────────────────────────
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.22.1
    hooks:
      - id: gitleaks

  # ── Conventional Commits ────────────────────────────────────────────────────
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v3.4.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
```

### Stack-specific hooks

**Python** — add after base:

```yaml
  # ── Python ──────────────────────────────────────────────────────────────────
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

**Shell** — add after base:

```yaml
  # ── Shell ───────────────────────────────────────────────────────────────────
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.10.0.1
    hooks:
      - id: shellcheck
```

**Markdown** — add when `.md` files detected:

```yaml
  # ── Markdown ────────────────────────────────────────────────────────────────
  - repo: https://github.com/igorshubovych/markdownlint-cli
    rev: v0.44.0
    hooks:
      - id: markdownlint
```

**Terraform** — add after base:

```yaml
  # ── Terraform ───────────────────────────────────────────────────────────────
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.99.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
```

**Docker** — add when Dockerfile detected:

```yaml
  # ── Docker ──────────────────────────────────────────────────────────────────
  - repo: https://github.com/hadolint/hadolint
    rev: v2.13.0-beta
    hooks:
      - id: hadolint-docker
```

**Node/JS/TS** — do NOT add prettier/eslint automatically; they require
project-specific config. Instead, tell the user:
> "Detected Node/JS/TS project. prettier and eslint are not added automatically
> — they require project config files. Run `npx prettier --write .` or configure
> them separately, then ask me to add them."

---

## Step 3 — Resolve latest revs (optional)

If the user asks for latest versions, or if the repo already uses a newer rev
than what's hardcoded above, update `rev` fields. Use the hardcoded revs above
as safe defaults when not asked.

---

## Step 4 — Write the file

Write the assembled config to `.pre-commit-config.yaml` at the repo root.

Show a diff-style preview before writing if the file already existed (merge
mode). If creating fresh, show the full file content and ask: "Write this
config? (yes / edit / cancel)".

**Do not write without explicit user confirmation.**

---

## Step 5 — Install hooks (ask first)

After writing, ask:
> "Run `pre-commit install` and `pre-commit install --hook-type commit-msg`
> to activate the hooks? (yes / skip)"

If yes:

```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

If `pre-commit` is not installed, tell the user:
> "pre-commit not found. Install with: `pip install pre-commit` or
> `brew install pre-commit`, then run `pre-commit install`."

---

## Step 6 — Validate (optional)

If the user wants a dry-run after install:

```bash
pre-commit run --all-files
```

Surface any failures and explain the fix. Do NOT auto-fix hook failures without
asking — some (e.g. gitleaks) may surface real secrets.

---

## What this skill does NOT do

- Does not `git add` or commit the new config file — user does that.
- Does not install `pre-commit` itself (only suggests the command).
- Does not configure per-hook settings beyond safe defaults.
- Does not touch Node-specific linters (prettier, eslint) — too project-specific.
