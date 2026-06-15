# Architecture Decision Record (ADR) Skill

Generate an **Architecture Decision Record** in MADR format — one significant
technical decision, the options considered, and the rationale. Tool-neutral.

## Install

Create a file `SKILL.md` in a specific folder to be able to use it.

### Example
- Cursor: `.cursor/skills/adr/SKILL.md`
- Pi: `~/.pi/agent/skills/adr/SKILL.md` (global) or `.pi/skills/adr/SKILL.md` (project)
- Claude Code: `~/.claude/skills/adr/SKILL.md`

## Usage

In Cursor, Pi, or Claude Code, simply ask:
- "Write an ADR for using an event store for the audit log"
- "Document this decision as an ADR"
- "Record why we picked Postgres over DynamoDB"

The agent will automatically load the skill if the description matches.
If it doesn't, force it with `/skill:adr` (Pi) or `@file:.cursor/skills/adr/SKILL.md` (Cursor).

## What It Does

1. Frames the decision as a problem (a short noun-phrase title)
2. Lists real options (≥2) and compares them on the drivers that matter
3. States the choice, its consequences (good and bad), and follow-on work
4. Numbers the file sequentially (`adr-0001-...md`) with a status lifecycle:
   `Proposed → Accepted → Deprecated → Superseded by adr-NNNN`

The output structure lives in [template.md](./template.md).

## What It Does NOT Do

- Does not edit an Accepted ADR — it writes a superseding one and links both ways
- Does not bundle multiple decisions in one file (one decision per ADR)
- Does not make the decision for you — it captures the reasoning you provide
