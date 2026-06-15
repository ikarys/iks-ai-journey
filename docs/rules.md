# Rules

Rules are **semantic / architectural** guidance, one light file per technology under
[`canonical/rules/`](../canonical/rules/). Each is **path-scoped** via frontmatter
(`title`, `description`, `paths:`) so it applies only to matching files.

| Rule | Scope |
|------|-------|
| [argocd](../canonical/rules/argocd.md) | Argo CD / GitOps |
| [docker](../canonical/rules/docker.md) | Dockerfiles and Compose |
| [kubernetes](../canonical/rules/kubernetes.md) | Kubernetes manifests |
| [python](../canonical/rules/python.md) | Python |
| [rust](../canonical/rules/rust.md) | Rust |
| [terraform](../canonical/rules/terraform.md) | Terraform / HCL |

## Rules vs. linters — separation of concerns

Rules carry **architecture only**. Syntax, formatting and style are owned by the
toolchain run in hooks (`terraform fmt`/`tflint`/`tfsec`, `ruff`, `clippy`,
`hadolint`, `kubeconform`, `shellcheck`). **A rule never restates what a linter
checks** — if a linter can catch it, the rule stays silent. See
[`AGENTS.md` → Rules & linters](../AGENTS.md).

## How rules are wired per agent

| Agent | Mechanism |
|-------|-----------|
| **Claude Code** | `.claude/rules` → `../canonical/rules` symlink (created by `bootstrap.sh`) |
| **pi.dev** | read as part of the project context |
| **Cursor** | map frontmatter `paths:` → `.cursor/rules/*.mdc` `globs:` (designed, not shipped) |

## Adding a rule

Create `canonical/rules/<tech>.md` with frontmatter `title`, `description`, and
`paths:` globs. Keep it semantic — defer anything a linter owns.
