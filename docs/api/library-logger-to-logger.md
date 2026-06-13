---
name: library-logger-to-logger
group: api
category: facade
update-time: 20260613
description: Recover the underlying full sync logger from the library-facing sync facade.
key-word:
    - logger
    - library
    - facade
    - public
---

## Library-logger-to-logger

Recover `Logger[S]` from `LibraryLogger[S]`. This unwraps the library-facing sync facade when code needs methods that are only available on the full logger type.

### Interface

```moonbit
pub fn[S] LibraryLogger::to_logger(self : LibraryLogger[S]) -> Logger[S] {}
```

#### input

- `self : LibraryLogger[S]` - Library-facing sync logger facade.

#### output

- `Logger[S]` - The underlying full sync logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This conversion unwraps the existing logger instead of rebuilding it.
- Sink wiring, target, min level, and attached wrappers remain the same.
- Use this when code needs full-surface APIs such as `with_timestamp(...)`, `with_filter(...)`, or `with_patch(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Full Logger-only Composition APIs

When a library-facing logger must be widened temporarily for additional composition:
```moonbit
let library_logger = LibraryLogger::new(console_sink(), target="lib")
let full_logger = library_logger.to_logger().with_timestamp()
```

In this example, the facade is unwrapped so the caller can access full logger composition APIs again.

### Error Case

e.g.:
- If callers only need library-oriented write APIs, unwrapping is unnecessary.

- Unwrapping does not change the current target or sink behavior by itself.

### Notes

1. Use this only when the narrower facade is no longer sufficient.

2. This is the inverse projection of `Logger::to_library_logger()`.
