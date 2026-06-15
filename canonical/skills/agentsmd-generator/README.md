# AGENTS.md Generator Skill

Generate a production-grade `AGENTS.md` by reading the current repo and applying
best practices for AI coding agents. `AGENTS.md` is the open standard "README for AI
coding agents" ([agents.md](https://agents.md/)).

## Install

Create a file `SKILL.md` in a specific folder to be able to use it.

### Example
- Cursor: `.cursor/skills/agentsmd-generator/SKILL.md`
- Pi: `~/.pi/agent/skills/agentsmd-generator/SKILL.md` (global) or `.pi/skills/agentsmd-generator/SKILL.md` (project)
- Claude Code: `~/.claude/skills/agentsmd-generator/SKILL.md`

## Usage

In Cursor, Pi, or Claude Code, simply ask:
- "Generate an AGENTS.md for this repo"
- "Scaffold a CLAUDE.md"
- "Document the conventions for AI agents on this project"

The agent will automatically load the skill if the description matches.
If it doesn't, force it with `/skill:agentsmd-generator` (Pi) or `@file:.cursor/skills/agentsmd-generator/SKILL.md` (Cursor).

## Modes (auto-detected)

| Mode | Signals |
|------|---------|
| `--dev` | `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `src/`, `lib/` |
| `--iac` | `*.tf`, `terragrunt.hcl`, `Pulumi.yaml`, `cloudformation/` |
| `--gitops` | `Chart.yaml`, `kustomization.yaml`, `Application.yaml` (ArgoCD), `HelmRelease.yaml` (Flux) |

A repo can match several modes (e.g. monorepo with `infra/` + `src/`).

## What It Does

1. Detects the repo type(s) and states the mode(s) before generating
2. Writes **only** non-obvious content an agent cannot infer from source (~150 lines max)
3. Always includes an `# Agent Boundaries` section (allowed vs. needs-approval)
4. Outputs the `AGENTS.md` in a single markdown code block

## What It Does NOT Do

- Does not duplicate `README.md` — it links to it
- Does not emit empty sections — anything with no data found is omitted
- Does not write the file to disk on its own — it outputs the content for you to place
