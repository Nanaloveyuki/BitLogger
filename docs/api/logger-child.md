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

- `Logger[S]` - A new logger whose default target is the composed child path.

### Explanation

Detailed rules explaining key parameters and behaviors

- If the parent target is empty, the child target becomes the full target.
- If the child target is empty, the parent target is preserved.
- If both are non-empty, they are joined with `.`.
- Sink, min level, and timestamp settings are preserved in the returned logger.

### How to Use

Here are some specific examples provided.

#### When Need Hierarchical Target Naming

When subsystem logs should stay grouped under a shared namespace:
```moonbit
let logger = Logger::new(console_sink(), target="service")
let worker = logger.child("worker")
```

In this example, `worker` emits records under `service.worker`.

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

Notes are here.

1. This is the preferred API for hierarchical logger naming.

2. Composition uses `.` as the separator between parent and child segments.

3. The original logger is not mutated.

4. This API works well with `with_context_fields(...)` to align target and metadata scopes.
