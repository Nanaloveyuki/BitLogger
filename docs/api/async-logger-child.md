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

- `AsyncLogger[S]` - A new async logger whose default target is the composed child path.

### Explanation

Detailed rules explaining key parameters and behaviors

- If the parent target is empty, the child target becomes the full target.
- If the child target is empty, the parent target is preserved.
- If both are non-empty, they are joined with `.`.
- Queue settings, sink wiring, and runtime behavior are preserved in the returned logger.

### How to Use

Here are some specific examples provided.

#### When Need Hierarchical Async Targets

When subsystem logs should stay grouped under one async namespace:
```moonbit
let logger = async_logger(console_sink(), target="service")
let worker = logger.child("worker")
```

In this example, `worker` emits under `service.worker` while keeping the same async queue behavior.

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
