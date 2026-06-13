---
name: library-async-logger-with-target
group: api
category: facade
update-time: 20260613
description: Replace the default target carried by a LibraryAsyncLogger facade.
key-word:
    - async
    - library
    - facade
    - public
---

## Library-async-logger-with-target

Replace the default target on a `LibraryAsyncLogger[S]`. This is the library-facing counterpart to `AsyncLogger::with_target(...)` when package code wants to retarget an async logger without exposing the full async logger API.

### Interface

```moonbit
pub fn[S] LibraryAsyncLogger::with_target(
  self : LibraryAsyncLogger[S],
  target : String,
) -> LibraryAsyncLogger[S] {
```

#### input

- `self : LibraryAsyncLogger[S]` - Base facade whose default target should be replaced.
- `target : String` - New default target namespace.

#### output

- `LibraryAsyncLogger[S]` - New library-facing async facade carrying the updated target.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to the wrapped async logger's `with_target(...)` behavior and then re-wraps the result.
- The returned value keeps the same queue state, sink type, and async config.
- This replaces the default target instead of composing it.
- The original facade value is not mutated.

### How to Use

Here are some specific examples provided.

#### When Need A New Fixed Async Namespace Inside Library Code

When one facade should emit under a different async target namespace:
```moonbit
let logger = LibraryAsyncLogger::new(@bitlogger.console_sink())
  .with_target("sdk.http")
```

In this example, later async writes inherit `sdk.http` unless a call overrides the target directly.

#### When Reuse One Async Setup Across Library Subsystems

When multiple library-facing async loggers should share one queue policy:
```moonbit
let base = LibraryAsyncLogger::new(
  @bitlogger.console_sink(),
  config=AsyncLoggerConfig::new(max_pending=64),
)
let cache = base.with_target("cache")
let io = base.with_target("io")
```

In this example, one base facade becomes several target-specific async facades.

### Error Case

e.g.:
- If `target` is empty, the returned logger remains valid and later records simply use an empty default target.

- If callers need hierarchical target composition rather than replacement, `child(...)` is the better API.

### Notes

1. Use this API for replacement, not target-path composition.

2. It keeps the narrower `LibraryAsyncLogger` boundary intact.
