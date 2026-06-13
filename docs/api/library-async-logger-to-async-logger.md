---
name: library-async-logger-to-async-logger
group: api
category: facade
update-time: 20260613
description: Recover the underlying full async logger from the library-facing async facade.
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
- Queue state, sink wiring, target, and flush policy remain the same.
- Use this when code needs wider async logger APIs outside the library facade.

### How to Use

Here are some specific examples provided.

#### When Need Full Async Logger-only APIs

When a library-facing async logger must be widened for additional async logger composition:
```moonbit
let library_logger = LibraryAsyncLogger::new(console_sink(), target="lib.async")
let full_logger = library_logger.to_async_logger().with_timestamp()
```

In this example, the facade is unwrapped so the caller can access the full async logger API again.

### Error Case

e.g.:
- If callers only need library-facing async write or lifecycle APIs, unwrapping is unnecessary.

- Unwrapping does not start or stop the background runtime by itself.

### Notes

1. Use this only when the narrower async facade is no longer sufficient.

2. This is the inverse projection of `AsyncLogger::to_library_async_logger()`.
