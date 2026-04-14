---
name: jira-story-ticket
description: Generate a Jira Story ticket (title + description) from a short subject input. Use when the user wants to create a Jira ticket, write a story, or says something like "create a ticket for...", "generate a Jira story about...", "I need a ticket on...". Automatically detects ticket type from input; asks one clarifying question only if ambiguous.
---

# Jira Story Ticket Generator

## Workflow

### Step 1 — Parse input

Extract from the user's message:
1. **Subject** — what the ticket is about
2. **Language** — detected from input, or explicitly stated (default: English)
3. **Ticket type** — infer from subject (see Type Detection below)

If ticket type is ambiguous, ask ONE question:
> "Is this a Story, Bug, Task, or Spike?"

Do not ask for more information. Generate from what you have.

---

### Step 2 — Detect ticket type

| Signal in subject | Type |
|---|---|
| "bug", "error", "crash", "broken", "fix", "regression", "not working" | **Bug** |
| "research", "investigate", "explore", "spike", "study", "analyze", "think about" | **Spike** |
| "doc", "documentation", "write", "readme", "guide", "confluence" | **Task** |
| "as a user", "user can", "user should", feature, capability, behavior | **Story** |
| anything else with no clear signal | **Story** (default) |

---

### Step 3 — Generate ticket

Generate **title** and **description** using the format matching the detected type (see Formats section below).

**Verbosity rules — strictly enforced:**
- Title: max 60 characters
- User Story: 1 sentence
- Context: 2-3 lines max
- AC: as many as needed, but each criterion is ONE short sentence (no sub-clauses, no explanations)
- Out of Scope: 2-3 items max, only if obvious from input
- Notes/Dependencies: short bullet points only — no sub-lists, no technical explanations
- **The full ticket must fit on one screen**

Output format:

---
🎫 **Type**: [Story | Bug | Task | Spike]
📌 **Title**: [generated title]

**Description**:
[generated description in markdown]

---

---

## Formats

### Story

**Title format**: `[Verb] [object] [optional context]`
- Imperative verb, lowercase, no trailing period, max 60 chars
- Examples: `Add OAuth2 login to the user portal`, `Display invoice history in account dashboard`

**Description**:

```
## User Story
As a [persona], I want [goal], so that [benefit].

## Context
[2-3 lines max. Why this ticket exists.]

## Acceptance Criteria
- [ ] Given [context], when [action], then [result]  ← short, one line each
- [ ] ...

## Out of Scope
- [2-3 items max, only if obvious]

## Notes / Dependencies
- [Short bullets only — no explanations]
```

---

### Bug

**Title format**: `[Component/Area] – [What is broken] [optional: in what condition]`
- Examples: `Login page – OAuth redirect fails on mobile`, `Invoice export – PDF generation crashes for empty orders`

**Description**:

```
## Summary
[One sentence.]

## Steps to Reproduce
1. [Step]
2. [Step]

## Expected Behavior
[One line.]

## Actual Behavior
[One line.]

## Environment
- [Version / platform / OS — if known]

## Notes
[Short bullets only — if inferable]
```

---

### Task

**Title format**: `[Action noun] [object] [optional: for/on context]`
- Examples: `Write API integration guide for onboarding`, `Update README for local dev setup`

**Description**:

```
## Objective
[1-2 lines. What and why.]

## Deliverables
- [ ] [Output 1]
- [ ] [Output 2]

## Definition of Done
- [ ] [Criterion]

## Notes / Dependencies
- [Short bullets only]
```

---

### Spike

**Title format**: `[Spike] [Question or topic to investigate]`
- Examples: `Spike: Evaluate Kafka vs RabbitMQ for event streaming`, `Spike: Assess feasibility of real-time PDF rendering in browser`

**Description**:

```
## Goal
[One sentence. The question to answer.]

## Timebox
[Duration — if inferable]

## Approach
- [Axis 1]
- [Axis 2]

## Expected Output
[doc / ADR / POC / recommendation]

## Notes / Dependencies
- [Short bullets only]
```

---

## Language rules

- Generate the full ticket (title + description) in the language detected from the user's input or explicitly requested
- If the user writes in French → generate in French
- If the user writes in English → generate in English
- If the user explicitly says "in French" or "en anglais" → follow that instruction
- Never mix languages within a single ticket

---

## What this skill does NOT do

- Does not create the ticket in Jira (no API calls)
- Does not ask for story points, assignee, or labels
- Does not validate or lint existing tickets
- Does not generate Epics (separate skill)
