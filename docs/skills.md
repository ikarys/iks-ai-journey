# Skills

Skills are on-demand capabilities, one folder each under
[`canonical/skills/`](../canonical/skills/). Each folder holds a `SKILL.md`
(loaded by the agent) and an optional `README.md` / `template.md`. The `SKILL.md`
frontmatter `description` is the source of truth — the table below only indexes it.

| Skill | Does |
|-------|------|
| [adr](../canonical/skills/adr/) | Generate an Architecture Decision Record in MADR format — one decision, options, rationale. Tool-neutral. |
| [agentsmd-generator](../canonical/skills/agentsmd-generator/) | Generate a production-grade `AGENTS.md` by reading the repo. Auto-detects `--dev` / `--iac` / `--gitops`. |
| [git-smart-commit](../canonical/skills/git-smart-commit/) | Group working-tree changes into coherent Conventional Commits after validation. Not for push/rebase/merge. |
| [jira-ticket-creation](../canonical/skills/jira-ticket-creation/) | Generate a Jira ticket (title + description) from a short subject; auto-detects type. |
| [precommit-setup](../canonical/skills/precommit-setup/) | Scaffold a complete `.pre-commit-config.yaml` (gitleaks, hygiene, conventional + stack hooks). |

## How skills are wired per agent

| Agent | Mechanism |
|-------|-----------|
| **Claude Code** | `.claude/skills` → `../canonical/skills` symlink (created by `bootstrap.sh`) |
| **pi.dev** | `skills[]` array in `~/.pi/agent/settings.json` points at `canonical/skills` (written by `bootstrap.sh pi`) |
| **Cursor** | n/a (Cursor has no skill concept) |

Both agents read the *same* folder — no copies, no drift. See
[Architecture](architecture.md).

## Adding a skill

1. Create `canonical/skills/<name>/SKILL.md` with frontmatter `name` + `description`.
2. Optional `README.md` (humans) and `template.md` (skill assets).
3. It is picked up automatically — Claude via the symlink, pi via the `skills[]`
   path. No bootstrap change needed.
