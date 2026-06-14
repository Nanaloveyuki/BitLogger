---
name: logger-child
group: api
category: logging
update-time: 20260512
description: Derive a child logger by composing the current target with a child target segment.
key-word:
    - logger
    - target
    - child
    - public
---

## Logger-child

Create a child logger by composing the current target with another target segment. This is the standard API for hierarchical target naming such as `app.worker` or `service.http.client`.

### Interface

```moonbit
pub fn[S] Logger::child(self : Logger[S], target : String) -> Logger[S] {}
```

#### input

- `self : Logger[S]` - Parent logger whose target should be extended.
- `target : String` - Child target segment or suffix.

#### output

- `Logger[S]` - A new logger value whose default target is the composed child path.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned logger is derived from `self`; the original logger value is not mutated.
- If the parent target is empty, the child target becomes the full target.
- If the child target is empty, the parent target is preserved.
- If both are non-empty, they are joined with `.`.
- Only the stored target changes. Sink, min level, and timestamp settings are preserved in the returned logger.
- The wider composition surface stays available on the derived logger, so follow-up calls such as `with_timestamp()` or log writes continue to work with the composed target.

### How to Use

Here are some specific examples provided.

#### When Need Hierarchical Target Naming

When subsystem logs should stay grouped under a shared namespace:
```moonbit
let logger = Logger::new(console_sink(), target="service")
let worker = logger.child("worker")
```

In this example, `worker` emits records under `service.worker`.

And `logger` still keeps its original stored target, because `child(...)` returns a derived logger value instead of mutating the parent.

#### When Build Deeply Scoped Loggers Step By Step

When deeper target composition should remain readable:
```moonbit
let http = Logger::new(console_sink(), target="app")
  .child("http")
  .child("client")
```

In this example, the final logger target becomes `app.http.client`.

### Error Case

e.g.:
- If `target` is empty, the returned logger keeps the original parent target.

- If callers need complete replacement rather than composition, `with_target(...)` should be used instead.

### Notes

1. This is the preferred API for hierarchical logger naming.

2. Composition uses `.` as the separator between parent and child segments.

3. The same compose-and-preserve contract is exercised through the library, configured, and application logger surfaces, not only on the base `Logger[S]` value.

