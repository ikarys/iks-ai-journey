---
title: Python
description: Semantic and architectural guidance for Python.
paths:
  - "**/*.py"
---

# Python — semantic guidance

> Formatting, imports, and lint are owned by `ruff` (run in hooks). This file is
> design only.

- **Explicit boundaries.** Keep I/O (network, disk, env) at the edges; keep the
  core logic pure and testable. Don't reach for globals or `os.environ` mid-domain.
- **Type the public surface.** Annotate function signatures and dataclasses so
  intent is checkable; let inference handle locals.
- **Errors are values you handle.** Raise specific exceptions; never swallow with a
  bare `except`. Fail loud at boundaries, not silently in the middle.
- **Composition over inheritance.** Prefer small functions and dataclasses; reserve
  classes for genuine state + behaviour. Avoid deep hierarchies.
- **Dependencies point inward.** Domain code must not import framework/transport
  code. Inject collaborators rather than constructing them inline.
- **Iterators and comprehensions** for data shaping; avoid building throwaway lists
  when a generator expresses the intent.
- Side-effect-free module import — no work at import time beyond definitions.
