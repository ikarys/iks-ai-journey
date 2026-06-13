---
title: Rust
description: Semantic and architectural guidance for Rust.
paths:
  - "**/*.rs"
---

# Rust — semantic guidance

> Formatting and lint are owned by `rustfmt` and `clippy` (run in hooks). This
> file is design only.

- **Make illegal states unrepresentable.** Model the domain with enums and newtypes
  so the type system rejects invalid combinations at compile time.
- **Errors via `Result`, not panics.** Reserve `panic!`/`unwrap`/`expect` for true
  invariants. Propagate with `?`; define error types at module boundaries.
- **Borrow, don't clone reflexively.** Take `&T`/`&mut T` in APIs; clone only when
  ownership genuinely must transfer. Let the borrow checker guide the design.
- **Encapsulate with modules and visibility.** Keep fields private; expose intent
  through methods. `pub` is a deliberate contract, not a default.
- **Prefer iterators** over manual index loops — they express intent and avoid
  bounds bugs.
- **Concurrency through ownership.** Share via `Arc`, mutate via `Mutex`/channels;
  don't fight `Send`/`Sync` with unsafe unless you can justify the invariant.
- Keep `unsafe` blocks tiny, isolated, and documented with the upheld invariant.
