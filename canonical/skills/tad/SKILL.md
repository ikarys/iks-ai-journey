---
name: tad
description: >
  Generate a Technical Architecture Document (TAD) for a system or significant
  component. Use when asked to document an architecture, capture a high-level
  design, or produce a TAD. Tool-neutral; portable across Claude Code, Cursor, pi.dev.
---

# Skill: Technical Architecture Document (TAD)

A TAD captures the *what* and *how* of a system's architecture: context, drivers,
the chosen structure, and the trade-offs behind it. It is a living reference, not a
one-off — keep it current as the design evolves.

## When to use
- Standing up a new service or platform component.
- Documenting an existing system whose design is only tribal knowledge.
- Onboarding material that needs the big picture, not code-level detail.

## How to produce one
1. **Gather inputs.** Ask for: the problem, the stakeholders, hard constraints
   (compliance, budget, latency), and any existing diagrams. Don't invent these.
2. **Establish drivers first.** Functional needs and quality attributes
   (scalability, availability, security) drive structure — lead with them.
3. **Describe structure at decreasing altitude:** context → containers →
   components. Stop before code; link to ADRs for individual decisions.
4. **Be explicit about trade-offs.** Every "we chose X" needs a "instead of Y,
   because Z". Record what was rejected.
5. **Fill `template.md`.** Keep prose tight; prefer diagrams (described in text /
   Mermaid) over walls of paragraphs.

## Conventions
- English, present tense, factual. No marketing language.
- Use **dummy/generic** names in examples (`service-a`, `region-x`) — never real
  company, cluster, or account identifiers.
- Cross-link decisions to ADRs (see the `adr` skill) instead of re-arguing them.

The output structure lives in [template.md](./template.md).
