---
description: Decide whether to /clear or /compact, then keep the context lean
argument-hint: (optional) what you're switching to next
---

Context discipline check. Long sessions re-send their whole history as input tokens
every turn, so stale context is a recurring cost. Pick the right reset:

1. **Assess** what's still relevant to the work ahead — and, if given, to:
   **$ARGUMENTS**.
2. **Recommend one**, in a single line, with the reason:
   - **`/clear`** — switching to unrelated work. Nothing from this session helps the
     next task; wipe it so it stops being taxed every turn.
   - **`/compact`** — continuing the *same* task but the history is long. Summarize
     and shrink; keep the thread, drop the bulk.
   - **neither** — context is small or all still relevant. Say so and carry on.
3. These are built-in commands the user runs — surface the recommendation, don't
   assume it's done.

Be terse. One recommendation, one reason. No preamble.
