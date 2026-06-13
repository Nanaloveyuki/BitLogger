---
name: library-async-logger-to-async-logger
group: api
category: facade
update-time: 20260613
description: Recover the underlying full async logger from the library-facing async facade without rebuilding queue or lifecycle state.
key-word:
    - async
    - library
    - facade
    - public
---

## Library-async-logger-to-async-logger

Recover `AsyncLogger[S]` from `LibraryAsyncLogger[S]`. This unwraps the library-facing async facade when code needs methods that are only available on the full async logger type.

### Interface

```moonbit
pub fn[S] LibraryAsyncLogger::to_async_logger(self : LibraryAsyncLogger[S]) -> AsyncLogger[S] {}
```

#### input

- `self : LibraryAsyncLogger[S]` - Library-facing async logger facade.

#### output

- `AsyncLogger[S]` - The underlying full async logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This conversion unwraps the existing async logger instead of rebuilding it.
- Queue state, sink wiring, target, min level, flush policy, and current failure/lifecycle state remain the same.
- Use this when code needs wider async logger APIs outside the library facade.
- This is the step required for helpers such as `pending_count()`, `dropped_count()`, `state()`, `wait_idle()`, `has_failed()`, `last_error()`, or broader composition methods that are intentionally hidden by `LibraryAsyncLogger[S]`.
- It is also the step that exposes the real post-run or post-shutdown state after facade-level lifecycle calls, because those calls delegated to this same wrapped logger all along.

### How to Use

Here are some specific examples provided.

#### When Need Full Async Logger-only APIs

When a library-facing async logger must be widened for additional async logger composition:
```moonbit
let library_logger = LibraryAsyncLogger::new(@bitlogger.console_sink(), target="lib.async")
let full_logger = library_logger.to_async_logger().with_timestamp()
```

In this example, the facade is unwrapped so the caller can access the full async logger API again.

#### When Need Direct Async State Inspection

When library-facing code later needs runtime diagnostics from the wrapped logger:
```moonbit
let full = library_logger.to_async_logger()
ignore(full.pending_count())
ignore(full.state())
```

In this example, unwrapping exposes the broader async inspection helpers on the same underlying logger state.

### Error Case

e.g.:
- If callers only need library-facing async write or lifecycle APIs, unwrapping is unnecessary.

- Unwrapping does not start or stop the background runtime by itself.

- Recovering the full async logger does not clear queue contents or reset failure state.

### Notes

1. Use this only when the narrower async facade is no longer sufficient.

2. This is the inverse projection of `AsyncLogger::to_library_async_logger()`.

3. Use `LibraryAsyncLogger[S]` directly when the narrower package-facing surface is still sufficient.
