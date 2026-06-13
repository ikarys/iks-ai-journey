---
title: Terraform
description: Semantic and architectural guidance for Terraform / HCL.
paths:
  - "**/*.tf"
  - "**/*.hcl"
---

# Terraform — semantic guidance

> Syntax, formatting and static checks are owned by `terraform fmt`, `tflint`,
> and `tfsec` (run in hooks). This file is architecture only.

- **Modules are contracts.** A module should do one thing; expose intent through
  variables with descriptions and sane defaults, return meaningful outputs.
- **No hardcoded environment values.** Parameterise region, sizing, and names;
  pass them in. Avoid embedding account IDs or cluster names in resources.
- **State is shared and dangerous.** Assume remote state with locking. Never design
  a change that requires manual state surgery without calling it out.
- **Prefer `for_each` over `count`** when elements have stable identities, so a
  removal doesn't reindex and destroy unrelated resources.
- **Make changes plannable.** Structure code so `terraform plan` clearly shows
  intent; avoid constructs that force replacement when an update would do.
- **Dependency direction:** data sources and locals upstream, resources downstream.
  Don't create hidden cycles via remote state references.
- Tag/label resources for ownership and cost, driven by variables — never literals.
