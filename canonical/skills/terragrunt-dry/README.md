# Terragrunt DRY Skill (Azure / OpenTofu)

Diagnostic-first guidance for composing infrastructure with **Terragrunt** the
DRY way — `include` hierarchies, `dependency` wiring, `remote_state`, `generate`
blocks, and `run --all` blast-radius control. Targets **Azure** (azurerm backend,
Azure AD auth) and **OpenTofu** (`terraform_binary = "tofu"`).

Currency: **Terragrunt v1.0+** CLI (`run --all`, no `--terragrunt-` flag prefix,
`docs.terragrunt.com`).

## Install

Create `SKILL.md` in a skills folder for your agent:

- Cursor: `.cursor/skills/terragrunt-dry/SKILL.md`
- Pi: `~/.pi/agent/skills/terragrunt-dry/SKILL.md` (global) or `.pi/skills/terragrunt-dry/SKILL.md` (project)
- Claude Code: `~/.claude/skills/terragrunt-dry/SKILL.md`

In this repo it lives under `canonical/skills/terragrunt-dry/` and is symlinked
into `~/.claude` by `bootstrap.sh`.

## Usage

Ask naturally:
- "Why is my `dependency` output empty during plan?"
- "Design a DRY Terragrunt layout for Azure"
- "My `run --all apply` touches too many units"
- "Where should the provider block live?"

The agent auto-loads the skill when the description matches. Force it with
`/skill:terragrunt-dry` (Pi) or `@file:.cursor/skills/terragrunt-dry/SKILL.md`
(Cursor).

## What It Does

1. Captures context (Terragrunt/OpenTofu version, layout, backend, auth).
2. Routes the symptom through a failure-mode table to the right fix section.
3. Teaches the DRY idioms: thin units, `find_in_parent_folders`,
   `read_terragrunt_config`, centralized `generate` provider, `path_relative_to_include`
   backend keys, `mock_outputs` guards.
4. Warns on `run --all` blast radius and enforces a response contract
   (assumptions, risk, fix, validation, rollback).

## What It Does NOT Do

- Does not author OpenTofu modules — that is the module repo's job.
- Does not run `apply`/`destroy` — read-only diagnosis + `plan` only.
- Does not duplicate linters (`fmt`, `tflint`, `tfsec`) — silent on syntax/style.
- Does not manage secrets — points to `ARM_*` env / SOPS / Key Vault.
