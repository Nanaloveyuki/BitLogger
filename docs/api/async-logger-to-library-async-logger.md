---
name: async-logger-to-library-async-logger
group: api
category: facade
update-time: 20260613
description: Convert a full async logger into the narrower library-facing async facade.
key-word:
    - async
    - library
    - facade
    - public
---

## Async-logger-to-library-async-logger

Convert `AsyncLogger[S]` into `LibraryAsyncLogger[S]`. This keeps the same async queue and sink behavior while projecting the value onto the smaller library-facing async surface.

### Interface

```moonbit
pub fn[S] AsyncLogger::to_library_async_logger(self : AsyncLogger[S]) -> LibraryAsyncLogger[S] {}
```

#### input

- `self : AsyncLogger[S]` - Full async logger to project into the library facade.

#### output

- `LibraryAsyncLogger[S]` - Narrower library-facing wrapper over the same async logger state.

### Explanation

Detailed rules explaining key parameters and behaviors

- This conversion does not rebuild the queue, sink, or runtime state.
- Target, min level, async config, and flush behavior are preserved.
- The returned facade keeps library-facing async operations including `log(...)`, `run()`, and `shutdown(...)`.

### How to Use

Here are some specific examples provided.

#### When Need To Expose A Narrower Async Type

When internal setup uses the full async logger API but public library code should return a smaller facade:
```moonbit
let logger = async_logger(console_sink(), target="lib.async")
let public_logger = logger.to_library_async_logger()
```

In this example, `public_logger` keeps the same async behavior but exposes the library-facing facade.

### Error Case

e.g.:
- If callers later need APIs outside the library facade, they must unwrap with `to_async_logger()`.

- The conversion does not clear pending items or reset runtime state.

### Notes

1. Use this when package boundaries should avoid exposing the full async logger type.

2. This is a projection API, not a reconfiguration step.
