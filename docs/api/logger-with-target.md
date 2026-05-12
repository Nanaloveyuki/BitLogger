---
name: logger-with-target
group: api
category: logging
update-time: 20260512
description: Replace the default target carried by a logger so later records inherit a new target namespace.
key-word:
    - logger
    - target
    - namespace
    - public
---

## Logger-with-target

Replace the logger's default target. This API is the simplest way to retarget a logger instance so later log calls inherit a new namespace without passing `target?` on every call.

### Interface

```moonbit
pub fn[S] Logger::with_target(self : Logger[S], target : String) -> Logger[S] {}
```

#### input

- `self : Logger[S]` - Base logger whose default target should be replaced.
- `target : String` - New default target namespace.

#### output

- `Logger[S]` - A new logger value carrying the updated target.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned logger keeps the same sink, min level, and timestamp settings.
- This API replaces the default target instead of composing it.
- Per-call `target?` arguments can still override the default target on individual log calls.
- The original logger value is not mutated.

### How to Use

Here are some specific examples provided.

#### When Need A Stable Namespace For One Subsystem

When one logger should always emit under a fixed target:
```moonbit
let logger = Logger::new(console_sink())
  .with_target("service.auth")

logger.info("started")
```

In this example, later records inherit `service.auth` unless a call overrides the target explicitly.

#### When Reuse One Sink Across Different Namespaces

When multiple subsystem loggers share the same sink:
```moonbit
let base = Logger::new(console_sink())
let worker = base.with_target("worker")
let api = base.with_target("api")
```

In this example, target routing stays explicit without duplicating sink construction.

### Error Case

e.g.:
- If `target` is empty, the logger remains valid and later records default to an empty target.

- If callers actually need parent-child target composition, `child(...)` is the better API.

### Notes

1. Use this API for replacement, not hierarchical composition.

2. It is useful when one sink serves several target namespaces.

