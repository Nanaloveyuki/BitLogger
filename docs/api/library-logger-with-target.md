---
name: library-logger-with-target
group: api
category: facade
update-time: 20260613
description: Replace the default target carried by a LibraryLogger facade.
key-word:
    - library
    - facade
    - target
    - public
---

## Library-logger-with-target

Replace the default target on a `LibraryLogger[S]`. This is the library-facing counterpart to `Logger::with_target(...)` when a package wants to retarget a logger without exposing the full sync logger API.

### Interface

```moonbit
pub fn[S] LibraryLogger::with_target(self : LibraryLogger[S], target : String) -> LibraryLogger[S] {
```

#### input

- `self : LibraryLogger[S]` - Base facade whose default target should be replaced.
- `target : String` - New default target namespace.

#### output

- `LibraryLogger[S]` - New library-facing logger facade carrying the updated target.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to the wrapped logger's `with_target(...)` behavior and then re-wraps the result.
- The returned value keeps the same sink type and minimum level settings.
- This replaces the default target instead of composing it.
- The original facade value is not mutated.

### How to Use

Here are some specific examples provided.

#### When Need A New Fixed Namespace Inside Library Code

When one facade should emit under a different target namespace:
```moonbit
let logger = default_library_logger().with_target("sdk.http")
logger.info("request prepared")
```

In this example, later writes inherit `sdk.http` unless a call overrides the target directly.

#### When Reuse The Same Sink Across Several Library Subsystems

When multiple library-facing loggers should share one base pipeline:
```moonbit
let base = LibraryLogger::new(console_sink())
let cache = base.with_target("cache")
let io = base.with_target("io")
```

In this example, one base facade becomes several target-specific facades.

### Error Case

e.g.:
- If `target` is empty, the returned logger remains valid and later records simply use an empty default target.

- If callers need hierarchical target composition rather than replacement, `child(...)` is the better API.

### Notes

1. Use this API for replacement, not target-path composition.

2. It keeps the narrower `LibraryLogger` boundary intact.
