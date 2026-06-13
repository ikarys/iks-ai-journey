---
name: adr
description: >
  Generate an Architecture Decision Record in MADR format. Use when capturing a
  single significant technical decision, the options considered, and the rationale.
  Tool-neutral; portable across Claude Code, Cursor, pi.dev.
---

# Skill: Architecture Decision Record (ADR — MADR)

An ADR records **one** architecturally significant decision: the context that
forced it, the options weighed, the choice, and its consequences. It is immutable
once accepted — supersede it with a new ADR rather than editing history.

## When to use
- A choice is hard to reverse, affects structure, or will be questioned later
  ("why did we pick X?").
- You need a durable, linkable rationale to reference from a TAD or PR.

## How to produce one
1. **Frame the decision as a problem,** not a solution. The title is a short noun
   phrase: *"Use append-only event store for audit log"*.
2. **List real options** — at least two, ideally three. A decision with one option
   is not a decision; say so or drop the ADR.
3. **Compare on the drivers** that matter (cost, complexity, operability, lock-in).
   Be honest about the downsides of the chosen option.
4. **State consequences,** positive and negative, including follow-on work.
5. **Number sequentially** (`adr-0001-...md`) and set status:
   `Proposed → Accepted → Deprecated → Superseded by adr-NNNN`.

## Conventions
- One decision per file. Keep it short — a page is plenty.
- English, neutral, dated. Use dummy names in examples.
- Never edit an Accepted ADR's decision; write a superseding one and link both ways.

The output structure lives in [template.md](./template.md).
