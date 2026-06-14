---
name: async-logger-child
group: api
category: async
update-time: 20260512
description: Derive a child async logger by composing the current target with a child target segment.
key-word:
    - async
    - logger
    - target
    - public
---

## Async-logger-child

Create a child async logger by composing the current target with another target segment. This is the standard API for hierarchical async logger naming such as `app.worker` or `service.http.client`.

### Interface

```moonbit
pub fn[S] AsyncLogger::child(self : AsyncLogger[S], target : String) -> AsyncLogger[S] {}
```

#### input

- `self : AsyncLogger[S]` - Parent async logger whose target should be extended.
- `target : String` - Child target segment or suffix.

#### output

- `AsyncLogger[S]` - A new async logger value whose default target is the composed child path.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned logger is derived from `self`; the original async logger value is not mutated.
- If the parent target is empty, the child target becomes the full target.
- If the child target is empty, the parent target is preserved.
- If both are non-empty, they are joined with `.`.
- Only the stored target changes. Queue settings, sink wiring, flush policy, level gating, and lifecycle state remain shared with the same underlying async logger setup.
- In the current direct async coverage, `timestamp` is also preserved on the derived child logger while the source logger keeps its previous parent target.

### How to Use

Here are some specific examples provided.

#### When Need Hierarchical Async Targets

When subsystem logs should stay grouped under one async namespace:
```moonbit
let logger = async_logger(console_sink(), target="service")
let worker = logger.child("worker")
```

In this example, `worker` emits under `service.worker` while keeping the same async queue behavior.

And `logger` still keeps its original stored target, because `child(...)` returns a derived async logger value instead of mutating the parent.

#### When Build Deep Async Scopes Step By Step

When deeper target composition should remain readable:
```moonbit
let http = async_logger(console_sink(), target="app")
  .child("http")
  .child("client")
```

In this example, the final logger target becomes `app.http.client`.

### Error Case

e.g.:
- If `target` is empty, the returned logger keeps the original parent target.

- If callers need complete replacement rather than composition, `with_target(...)` should be used instead.

### Notes

1. This is the preferred API for hierarchical async logger naming.

2. Composition changes the target only and does not rebuild the queue or sink.

3. State helpers such as `pending_count()`, `dropped_count()`, `is_closed()`, and `has_failed()` still operate on the same async logger state after derivation.

4. Use `child("")` when code should keep the current target while still following a target-composition code path.
