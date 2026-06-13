---
name: async-logger-to-library-async-logger
group: api
category: facade
update-time: 20260613
description: Convert a full async logger into the narrower library-facing async facade without rebuilding the underlying async state.
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
- Target, min level, async config, flush behavior, pending counts, and failure state are preserved because the same underlying async logger value is wrapped.
- The returned facade keeps library-facing async operations including `log(...)`, `run()`, and `shutdown(...)`.
- Async inspection helpers and broader composition APIs remain on the underlying `AsyncLogger[S]` and are intentionally hidden until `to_async_logger()` is used again.
- If later facade-level `run()` or `shutdown()` calls record worker failure, leave backlog behind, or follow runtime-dependent shutdown cleanup rules, unwrapping later still exposes that same post-call state instead of a translated facade copy.
- When `S` itself exposes richer runtime helpers, projecting to the library facade does not strip those capabilities from the wrapped logger; they are still reachable after `to_async_logger()`.

### How to Use

Here are some specific examples provided.

#### When Need To Expose A Narrower Async Type

When internal setup uses the full async logger API but public library code should return a smaller facade:
```moonbit
let logger = async_logger(console_sink(), target="lib.async")
let public_logger = logger.to_library_async_logger()
```

In this example, `public_logger` keeps the same async behavior but exposes the library-facing facade.

#### When Need To Narrow Surface Without Resetting Runtime State

When an already-used async logger should be projected to a library boundary without changing its current state:
```moonbit
let full = build_async_logger(config)
let public_logger = full.to_library_async_logger()
ignore(public_logger.is_enabled(@bitlogger.Level::Info))
```

In this example, the projection changes the exposed type only; it does not rebuild queue or lifecycle state.

### Error Case

e.g.:
- If callers later need APIs outside the library facade, they must unwrap with `to_async_logger()`.

- The conversion does not clear pending items or reset runtime state.

- If callers later need state helpers such as `pending_count()` or `state()`, they must unwrap again with `to_async_logger()`.

- Projection does not normalize failure snapshots; a later unwrap can still show combinations such as retained `last_error()` with remaining `pending_count()` when the wrapped async logger really ended up in that state.

### Notes

1. Use this when package boundaries should avoid exposing the full async logger type.

2. This is a projection API, not a reconfiguration step.

3. Use `build_library_async_logger(...)` or `build_library_async_text_logger(...)` when construction and narrowing should happen together from config.
