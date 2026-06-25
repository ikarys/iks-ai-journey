---
name: terragrunt-dry
description: >
  Diagnose and design Terragrunt DRY infrastructure (Azure / OpenTofu): include
  hierarchies, dependency wiring, remote_state, generate blocks, run --all blast
  radius. Use when asked about terragrunt.hcl, DRY layouts, find_in_parent_folders,
  mock_outputs, or when a Terragrunt command/merge/dependency behaves unexpectedly.
---

# Terragrunt DRY Skill (Azure / OpenTofu)

Diagnostic-first guidance for **consuming/composing** infrastructure with
Terragrunt. Assumes reusable OpenTofu modules live elsewhere; this skill is about
the live layer that wires them together DRY.

Scope guards: **Azure** (azurerm backend, Azure AD auth) and **OpenTofu**
(`terraform_binary = "tofu"`, `.tofu` sources). Currency: **Terragrunt v1.0+**
CLI — `run --all` (not `run-all`), flags without the legacy `--terragrunt-`
prefix, docs at `docs.terragrunt.com`.

This skill is **not** a linter. `fmt`, `validate`, `tflint`, `tfsec` own syntax
and style — stay silent on what they catch.

---

## Step 0 — Capture context

Before answering, establish:

```bash
terragrunt --version          # confirm v1.0+ (CLI redesign applies)
tofu version
```

- **Layout** — where is `root.hcl`? env/region hierarchy? template dir
  (`_envcommon/` or `_base/`)?
- **Backend** — azurerm storage account / container / key strategy.
- **Auth** — how do runners authenticate (SP / MSI / OIDC via `ARM_*` env)?
- **Scope** — single unit, or `run --all` over a stack?

If version < v1.0, warn: command/flag syntax below differs; point to the
[CLI Redesign guide](https://docs.terragrunt.com/migrate/cli-redesign/).

---

## Step 1 — Diagnose via routing table

Match the symptom, apply the named fix below. Keep depth inline — no external
files yet.

| Symptom | Likely cause | Fix section |
|---------|-------------|-------------|
| `include.x.locals` is null / not found | missing `expose = true`, or wrong include name | **include patterns** |
| Values not inherited from parent | not re-read via `read_terragrunt_config` | **Variable inheritance** |
| Wrong `key`/path in backend | `path_relative_to_include()` from wrong include | **Azure backend** |
| `dependency` output empty during plan | no `mock_outputs`, or command not allowed | **dependency patterns** |
| `run --all` applies in wrong order | broken DAG / missing `dependency` block | **dependency patterns** |
| `run --all` touches too much | no `--working-dir` / `find` scope | **run --all guidance** |
| Provider/version drift across units | provider not centralized in `generate` | **include patterns** |
| Merge overwrites nested maps | `merge` used where `deep_merge` needed | **include patterns** |
| Terraform ignores `.tofu` source | wrong binary | **OpenTofu guard** |
| Secret visible in `.hcl` / state | secret inlined instead of env/KV | **Safety rules** |

---

## DRY architecture reference

Canonical hierarchy — config flows **down**, each level adds/overrides:

```
src/
├── root.hcl                 # remote_state + generate "provider" (the one root include)
├── global.hcl               # org-wide locals (tags, shared DNS zones, …)
├── _envcommon/  (or _base/) # reusable unit templates, one per component
│   └── <component>/default/terragrunt.hcl   # terraform{source=…} + base inputs
└── <env>/                   # env = subscription
    ├── subscription.hcl     # env_name, subscription_id, env tags
    └── <region>/
        ├── region.hcl       # location, backend SA/RG, region tags
        └── <category>/<unit>/terragrunt.hcl   # thin: includes + input overrides
```

Principles:
- **Units stay thin.** A leaf `terragrunt.hcl` = includes + a few `inputs`. All
  reusable logic lives in `root.hcl` and the template under `_envcommon`/`_base`.
- **One source of truth per concern.** Provider → `root.hcl`. Backend →
  `root.hcl`. Component wiring → template. Env values → `subscription.hcl` /
  `region.hcl`.
- **Directory-per-env**, never TF workspaces. Isolation is the directory tree.

---

## include patterns

Two-include pattern — bare root + named template:

```hcl
# leaf unit
include {                                  # the root include (unnamed)
  path = find_in_parent_folders("root.hcl")
}

include "base" {                           # named → reusable template
  path = "${get_repo_root()}/src/_envcommon/aks/default/terragrunt.hcl"
}

inputs = {
  name = "aks-shared-001"                  # thin override only
}
```

- `find_in_parent_folders("root.hcl")` walks **up** to the nearest match. Name
  the file explicitly (bare `find_in_parent_folders()` is deprecated).
- **`expose = true`** on a named include if you must read its `locals`/`inputs`
  from the child: `include.base.locals.x`. Without it, those attrs are null.
- **Merge strategy** — default `include` is shallow. For nested maps (tags,
  provider features) set `merge_strategy = "deep"` so child keys merge instead
  of replacing the parent map wholesale.
- **Centralize provider + versions** in `root.hcl` via `generate` so every unit
  gets identical pinning — kills drift:

```hcl
generate "provider" {
  path      = "provider.terragrunt.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "azurerm" {
      features {}
      subscription_id     = "${local.subscription_id}"
      storage_use_azuread = true
    }
  EOF
}
```

---

## Variable inheritance

Primary mechanism — **re-read parent configs**, don't rely on transitive include
locals:

```hcl
locals {
  subscription_vars = read_terragrunt_config(find_in_parent_folders("subscription.hcl"))
  region_vars       = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  env_name = local.subscription_vars.locals.env_name
  location = local.region_vars.locals.location
}

inputs = merge(
  local.region_vars.locals.region_tags,   # inherited map
  { name = "..." }                         # unit-specific
)
```

Alternates (use only if the repo already does):
- `expose = true` on includes to reach `include.x.locals` directly.
- `yamldecode(file("global.yaml"))` if vars live in YAML instead of `.hcl`.

Hierarchy: `global.hcl → subscription.hcl → region.hcl → unit`. Each reads the
ones above via `find_in_parent_folders`.

---

## dependency patterns

Wire one unit's outputs into another:

```hcl
dependency "network" {
  config_path = "../../network/vnet"

  mock_outputs = {
    subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/…/subnets/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  subnet_id = dependency.network.outputs.subnet_id
}
```

- `mock_outputs` lets `plan`/`validate` run before the dependency is applied.
  **Guard them** with `mock_outputs_allowed_terraform_commands` so `apply` never
  silently uses a mock (would corrupt real wiring).
- `dependency` blocks build the **DAG** — `run --all` apply/destroy order derives
  from them. Missing block → wrong order. Use `dependencies { paths = [...] }`
  for ordering-only (no output) edges.
- Empty output during plan → add/extend `mock_outputs`.

---

## run --all guidance

`run --all <cmd>` fans a command across every unit in the working tree, ordered
by the dependency DAG.

```bash
terragrunt run --all plan                        # always preview first
terragrunt run --all plan  --working-dir ./dev   # scope to one env
terragrunt run --all apply --working-dir ./dev/westeurope   # narrow blast radius
terragrunt run --all apply --parallelism 4       # cap concurrency
```

- **Blast radius** — `run --all apply` from repo root hits *everything*. Always
  scope with `--working-dir` (or run from inside the target subtree).
- **`--parallelism N`** throttles concurrent units (rate limits, lock
  contention).
- Legacy `--terragrunt-`prefixed flags are deprecated in v1.0 — use
  `--working-dir`, `--parallelism`, etc.
- **Stacks (optional)** — implicit (directory hierarchy, the default above) is
  fine to start. Adopt explicit `terragrunt.stack.hcl` only when you have many
  near-identical units differing only in values (catalog/template reuse). See
  [Stacks](https://docs.terragrunt.com/features/stacks/).

---

## Azure backend reference

Centralize in `root.hcl`; derive the key from the unit's path so each unit gets
isolated state automatically:

```hcl
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    subscription_id      = local.subscription_id
    resource_group_name  = local.backend_rg
    storage_account_name = local.backend_sa
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

- `path_relative_to_include()` → per-unit state key, zero hardcoding.
- `use_azuread_auth = true` + `storage_use_azuread = true` (provider) → no
  storage access keys.
- Backend SA/RG/subscription come from `region.hcl` / `subscription.hcl` locals.

---

## OpenTofu guard

```hcl
# root.hcl
terraform_binary = "tofu"
```

- OpenTofu reads `.tofu` and `.tf`; **Terraform ignores `.tofu`**. Module sources
  using `.tofu` require the `tofu` binary.
- Confirm `tofu version` resolves, not `terraform`.

---

## Safety rules (never-do)

- **Never** `run --all apply`/`destroy` on prod without an explicit
  `--working-dir` scope. Default is the entire tree.
- **Never** put secrets in `.hcl` files or `inputs`. Use `ARM_*` env vars
  (SP/MSI/OIDC), SOPS, or an Azure Key Vault data source. State is not a secret
  store.
- **Always** `run --all plan` before any `apply`.
- **Never** mix Terragrunt-managed state with hand-created `.tfstate`.
- **Never** commit `.terragrunt-cache/` — add to `.gitignore`.
- **Never** weaken `mock_outputs_allowed_terraform_commands` to include `apply`.

---

## Response contract

Every answer to a Terragrunt question ends with:

1. **Assumptions + version floor** — Terragrunt/OpenTofu versions assumed.
2. **Risk** — LOW / MEDIUM / HIGH / CRITICAL (blast radius, state, secrets).
3. **Fix + tradeoffs** — chosen approach, what it costs.
4. **Validation** — exact commands (`terragrunt validate`,
   `run --all plan --working-dir …`).
5. **Rollback** — how to undo (re-apply prior config, state restore).

---

## What this skill does NOT do

- Does not author OpenTofu modules — that is the module repo's concern.
- Does not run `apply`/`destroy` — read-only diagnosis + plan only.
- Does not duplicate linters (`fmt`, `tflint`, `tfsec`) — silent on syntax/style.
- Does not manage secrets — points to env/SOPS/Key Vault, never inlines them.
