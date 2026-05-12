---
name: async-logger-with-target
group: api
category: async
update-time: 20260512
description: Replace the default target carried by an async logger so later records inherit a new target namespace.
key-word:
    - async
    - logger
    - target
    - public
---

## Async-logger-with-target

Replace the async logger's default target. This API retargets later enqueue operations without changing the queue, overflow policy, or sink wiring.

### Interface

```moonbit
pub fn[S] AsyncLogger::with_target(self : AsyncLogger[S], target : String) -> AsyncLogger[S] {}
```

#### input

- `self : AsyncLogger[S]` - Base async logger whose default target should be replaced.
- `target : String` - New default target namespace.

#### output

- `AsyncLogger[S]` - A new async logger value carrying the updated target.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned logger keeps the same sink, queue state, overflow policy, flush policy, and lifecycle flags.
- This API replaces the default target instead of composing it.
- Per-call `target?` arguments on `log(...)` can still override the default target.
- The original logger value is not mutated.

### How to Use

Here are some specific examples provided.

#### When Need A Stable Async Target Namespace

When one async logger should always emit under a fixed target:
```moonbit
let logger = async_logger(console_sink())
  .with_target("service.worker")
```

In this example, later async log calls inherit `service.worker` unless a call overrides the target explicitly.

#### When Reuse One Async Setup Across Namespaces

When multiple subsystem loggers should share the same async queue behavior:
```moonbit
let base = async_logger(console_sink(), config=AsyncLoggerConfig::new(max_pending=64))
let api = base.with_target("api")
let jobs = base.with_target("jobs")
```

In this example, target routing changes without rebuilding the async runtime configuration.

### Error Case

e.g.:
- If `target` is empty, the logger remains valid and later records default to an empty target.

- If callers need hierarchical target composition rather than replacement, `child(...)` is the better API.

### Notes

1. Use this API for replacement, not parent-child target composition.

2. It is useful when several subsystems should share one async queue policy.
