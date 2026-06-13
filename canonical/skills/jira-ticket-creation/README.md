# Jira Ticket Creation Skill

## Install

Create a file `SKILL.md` in a specific folder to be able to use it.

### Example
- Cursor: `.cursor/skills/jira-ticket-creation/SKILL.md`
- Pi: `~/.pi/agent/skills/jira-ticket-creation/SKILL.md` (global) or `.pi/skills/jira-ticket-creation/SKILL.md` (project)
- Claude Code: `~/.claude/skills/jira-ticket-creation/SKILL.md`

## Usage

In Cursor, Pi, or Claude Code, simply ask:
- "Create a ticket for user authentication"
- "Generate a Jira story about invoice export"
- "I need a ticket on search performance"
- "Write a bug ticket for the login crash on mobile"

The agent will automatically load the skill if the description matches.
If it doesn't, force it with `/skill:jira-story-ticket` (Pi) or `@file:.cursor/skills/jira-ticket-creation/SKILL.md` (Cursor).

## Supported Ticket Types

| Type | When to use |
|---|---|
| **Story** | New feature, user-facing capability, behavior |
| **Bug** | Error, crash, regression, broken behavior |
| **Task** | Documentation, maintenance, non-feature work |
| **Spike** | Research, investigation, feasibility study |

The skill automatically detects the ticket type from your input. If ambiguous, it asks one clarifying question.

## What It Does

1. Parses your input to extract subject, language, and ticket type
2. Generates a structured Jira ticket (title + description) in the detected language
3. Outputs the ticket in markdown format, ready to copy into Jira

## What It Does NOT Do

- No Jira API calls — it only generates the ticket content
- No story points, assignee, or labels
- No Epic generation
