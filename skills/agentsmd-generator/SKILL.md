---
name: agentsmd-generator
description: "Generates a production-grade AGENTS.md by reading the current repo and applying best practices for AI coding agents. Use when the user asks to generate or scaffold an AGENTS.md or CLAUDE.md, or wants to document conventions for AI agents on their project. Auto-detects mode: --dev (app code), --iac (Terraform/Terragrunt/Pulumi), --gitops (ArgoCD/Flux/Helm/Kustomize). Trigger on: AGENTS.md, agent instructions, coding agent conventions, onboard AI agent."
---

# AGENTS.md Generator

Generates a production-grade `AGENTS.md` for the current repository.
AGENTS.md is the open standard "README for AI coding agents" (agents.md spec,
adopted by GitHub Copilot, Cursor, Windsurf, Claude Code, Amp, Jules, etc.).

---

## Step 1 — Detect repo type

Scan the repository and identify which mode(s) apply:

| Mode | Signals |
|------|---------|
| `--dev` | `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `src/`, `lib/` |
| `--iac` | `*.tf`, `terragrunt.hcl`, `Pulumi.yaml`, `cloudformation/` |
| `--gitops` | `Chart.yaml`, `kustomization.yaml`, `Application.yaml` (ArgoCD), `HelmRelease.yaml` (Flux) |

A repo can match multiple modes (e.g. monorepo with `infra/` + `src/`).
State detected mode(s) before generating.

---

## Step 2 — Generate AGENTS.md

Write **only** non-obvious, actionable content an agent cannot infer from source files.
- Max ~150 lines
- All commands in code blocks
- Reference `README.md` instead of duplicating it
- Omit any section with no relevant data found

---

### SHARED SECTIONS (always include)

#### `# Project Overview`
What this repo does, its scope, key constraints, team context if detectable.

#### `# Repo Structure`
Top-level dirs and their purpose. Highlight non-obvious layout decisions.

#### `# Git & PR Workflow`
- Branch naming convention
- Commit message format (detect Conventional Commits from history or config)
- PR requirements (required reviewers, CI gates, labels)

#### `# Security & Secrets`
- What never goes in files (API keys, tokens, passwords, kubeconfigs)
- Where secrets live (SOPS, Vault, `.env`, secret manager)
- Files/patterns that must never be committed (add to `.gitignore` examples)

#### `# Agent Boundaries` ← MANDATORY, never omit

Explicit split between safe and destructive operations.

```markdown
## Agent Boundaries
### ✅ Allowed without approval
- Read, lint, format, template rendering
- Write/modify source files and tests
- Open MR/PR for review
- Run dry-run / plan / diff commands

### ❌ Requires explicit human approval
- Apply changes to production environments
- Merge to main/master
- Delete or rename resources
- Modify state backends or remote config
- Change ArgoCD/Flux sync policies
- Run destructive CLI commands (terraform destroy, kubectl delete, etc.)
```

---

### MODE: `--dev`

#### `# Dev Environment Setup`
Exact install + run commands (copy-pasteable).

#### `# Build & Run`
Commands only. No prose.

#### `# Testing`
- Command to run full test suite
- Command to run a single test
- Expected output for passing suite

#### `# Code Conventions`
- Enforced linter/formatter + config file path
- Naming conventions (files, functions, classes, branches)
- Patterns to follow (e.g. return early, no magic strings, DI over globals)
- Patterns to **AVOID** — explicit list

#### `# Architecture Notes`
Key modules, service boundaries, important entry points an agent must know.

---

### MODE: `--iac`

#### `# IaC Overview`
- Tool: Terraform / Terragrunt / Pulumi / other
- State backend location and locking mechanism
- Workspace or environment strategy (directory-per-env vs workspaces)

#### `# Environments`
Table or list: environment name → directory path → blast radius (low/med/high).

#### `# Plan & Validate` (read-only operations)
```bash
# Init
terraform init
# or
terragrunt run-all init

# Plan
terraform plan -out=tfplan
# or
terragrunt run-all plan

# Static analysis (if present)
tflint --recursive
tfsec .
trivy config .
conftest test --policy policy/ .
```

#### `# Apply Rules`
- Who/what triggers apply (CI pipeline only, never local?)
- Required approvals before prod apply
- ❌ Never run `apply` or `destroy` directly — always via CI

#### `# Module Structure`
Where reusable modules live. Versioning convention (Git tags, registry).

#### `# State & Sensitive Outputs`
- Remote state references between stacks (`terraform_remote_state` paths)
- Outputs containing sensitive data — mark them, never log

---

### MODE: `--gitops`

#### `# GitOps Overview`
- Tool: ArgoCD / Flux / other
- Cluster(s) managed + criticality (non-prod / prod)
- Sync model per environment: auto-sync vs manual

#### `# App Structure`
Where `Application` / `AppSet` / `HelmRelease` CRs are defined.
Naming convention for app CRs and Helm releases.

#### `# Render & Validate` (read-only operations)
```bash
# Helm
helm template <release> <chart> -f values/<env>.yaml
helm lint <chart>

# Kustomize
kustomize build overlays/<env>

# ArgoCD diff
argocd app diff <app-name> --local <path>

# Validation (if present)
kubeconform -strict -summary manifests/
conftest test --policy policy/ manifests/
datree test manifests/
```

#### `# Deployment Order`
Dependencies between apps (CRDs before operators, operators before apps).
Document ArgoCD `syncWave` annotations or Flux `dependsOn` if used.

#### `# Sync Policy Rules`
List per app or per environment:
- Auto-sync + prune + self-heal: which apps/envs
- Manual-only: databases, stateful workloads, infra operators
- ❌ Never modify `syncPolicy`, `prune`, or `selfHeal` settings without approval

#### `# Secrets Management`
How secrets reach the cluster:
- SOPS + age/GPG → which files are encrypted, key location
- External Secrets Operator → which secret store backend
- Vault Agent / Vault Secrets Operator → auth method
- Sealed Secrets → controller namespace

What agents must **never** touch: decrypted secret files, kubeconfig files,
private keys.

---

## Step 3 — Output rules

- Output **only** the `AGENTS.md` content in a single markdown code block
- Sections with no data found → omit entirely
- `# Agent Boundaries` is **always** present regardless of mode
- All commands in fenced code blocks
- Max ~150 lines — if repo is complex, prioritize non-obvious information
- Do **not** duplicate content already in `README.md` — link to it

---

## Reference

- Spec: https://agents.md/
- GitHub blog (2500+ repo analysis): https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/
- Best practice: only document what agents **cannot infer** from source files
