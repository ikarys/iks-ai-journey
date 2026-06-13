---
name: standard
description: >
  Generate a technical standard or guideline document that defines a rule the team
  agrees to follow (naming, tagging, branching, API conventions, etc.). Use when
  asked to write a standard, guideline, or convention. Tool-neutral; portable.
---

# Skill: Technical Standard / Guideline

A standard codifies a **normative rule** the team commits to: what is required,
what is recommended, what is forbidden, and how it is checked. Unlike a TAD (a
design) or an ADR (a one-time decision), a standard is an ongoing constraint.

## When to use
- Recurring inconsistency that wastes review time (naming, labels, repo layout).
- A practice you want enforced, ideally by a linter or CI check, not by memory.

## How to produce one
1. **State the rule in one sentence** at the top — testable, unambiguous.
2. **Use RFC 2119 keywords** deliberately: MUST / MUST NOT / SHOULD / MAY. Reserve
   MUST for things that are actually enforced or block merge.
3. **Show conformant and non-conformant examples.** A standard without examples is
   argued about forever. Use dummy names.
4. **Define enforcement.** Name the linter/CI check that catches violations, or
   mark the rule as "review-only" honestly. Standards should not duplicate what a
   linter already enforces — point to it instead.
5. **Set scope and exceptions.** Where it applies, and the documented escape hatch.

## Conventions
- English, imperative, normative. No hedging on MUST rules.
- Version and date it; standards evolve — record the change.
- Generic/dummy examples only; nothing company-specific.

The output structure lives in [template.md](./template.md).
