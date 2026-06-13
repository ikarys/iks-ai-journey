# iks-ai-journey

A portable, multi-tool **AI agent configuration** repo. One source of truth in
tool-neutral markdown; thin per-tool adapters on top. Set up for **Claude Code**
today, designed so **pi.dev** and **Cursor** can plug in later without restructuring.

## Principle

```
canonical/  ── tool-neutral guidance (markdown)  ← the only source of truth
   │
   ├─ symlink ─→  .claude/   (Claude Code adapter: CLAUDE.md, rules, skills)
   └─ (future)    Cursor / pi.dev adapters

Guidance (markdown) is portable.
Enforcement (hooks, permissions, settings) is Claude Code-specific.
```

Guidance lives once in `canonical/` (and `AGENTS.md`). Each tool gets a thin adapter
that points back at it — no copies, no drift. Mechanisms that *enforce* the guidance
(format-on-save, branch protection, permission denials) are wired in `.claude/` and
are Claude Code-only by nature.

## Layout

| Path | What it is |
|------|------------|
| `AGENTS.md` | Canonical agent instructions. Read **natively by Cursor**; symlinked into Claude Code as `.claude/CLAUDE.md`. |
| `canonical/rules/` | One light, **path-scoped, semantic** rule per technology (terraform, kubernetes, docker, argocd, python, rust). Architecture only — no linter duplication. |
| `canonical/skills/` | Doc-generation skills, one folder each = `SKILL.md` + `template.md`: `tad/` (Technical Architecture Doc), `adr/` (MADR decision record), `standard/` (technical standard). |
| `.claude/CLAUDE.md` | → `../AGENTS.md` (symlink) |
| `.claude/rules/` | → `../canonical/rules/` (symlink) |
| `.claude/skills/` | → `../canonical/skills/` (symlink) |
| `.claude/agents/code-reviewer.md` | Read-only review subagent (`tools: Read, Grep, Glob`). |
| `.claude/settings.json` | Permissions (deny destructive/secret-reading, allow read-only) + `PreToolUse`/`PostToolUse` hooks. |
| `scripts/auto-fmt.sh` | **PostToolUse** hook: dispatch formatter/linter by extension, each guarded by `command -v`, never fails the edit. |
| `scripts/check-branch.sh` | **PreToolUse** hook: block edits on `main`/`master`; escape hatch `ALLOW_MAIN_EDITS=1`. |
| `git-hooks/commit-msg` | Enforce **Conventional Commits** (tool-agnostic, any git client). |
| `git-hooks/pre-commit` | Run `gitleaks` if installed, else warn. |
| `bootstrap.sh` | Idempotently (re)create symlinks + set `core.hooksPath=git-hooks`. |

> Note: a separate top-level `skills/` directory holds personal, hand-written
> skills and is independent of the `canonical/skills/` doc-gen set above.

## Setup

```bash
./bootstrap.sh
```

Run it after every fresh clone. It is idempotent and **required on Windows**, where
clones often don't preserve symlinks — `bootstrap.sh` recreates them. It also wires
the git hooks (`core.hooksPath=git-hooks`) and fixes executable bits.

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

- **Cursor** (later): reads `AGENTS.md` natively. Map `canonical/rules/*.md`
  front-matter `paths:` → Cursor `.mdc` `globs:` (generate `.cursor/rules/` from
  canonical, or symlink where supported). No content is duplicated.
- **pi.dev** (later): add a `pi/` adapter pointing at `AGENTS.md` and
  `canonical/`. Port the *guidance*; re-express *enforcement* (the hook scripts in
  `scripts/` and `git-hooks/`) in pi.dev's own mechanism, since hooks are
  Claude-Code-specific.

Adding a tool = one new adapter folder + a few lines in `bootstrap.sh`. The source
of truth stays untouched.
