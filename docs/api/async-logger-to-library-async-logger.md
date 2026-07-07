---
name: async-logger-to-library-async-logger
group: api
category: facade
update-time: 20260707
description: Convert a full async logger into the narrower library-facing async facade without rebuilding or detaching the underlying async state.
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
- The original `AsyncLogger[S]` handle remains the same live logger. If caller code keeps that original value, later facade calls and later unwraps still observe the same shared queue, counters, sink helpers, and lifecycle mutations.
- The returned facade keeps library-facing async operations including `log(...)`, `run()`, and `shutdown(...)`.
- Async inspection helpers and broader composition APIs remain on the underlying `AsyncLogger[S]` and are intentionally hidden until `to_async_logger()` is used again.
- If later facade-level `run()` or `shutdown()` calls record worker failure or perform shutdown cleanup, unwrapping later still exposes that same post-call state instead of a translated facade copy.
- That includes states where delegated shutdown already finished with `is_closed=true` while retained `has_failed()` and `last_error()` remain on the wrapped logger, together with the same retained dropped-count cleanup outcome.
- When `S` itself exposes richer runtime helpers, projecting to the library facade does not strip those capabilities from the wrapped logger; they are still reachable after `to_async_logger()`.
- When `S` is `RuntimeSink`, projection also preserves queued runtime state and file-backed runtime helper behavior behind the facade instead of replacing them with a library-specific copy.
- Unwrapping later with `to_async_logger()` therefore exposes the same queue counters, failure snapshots, file state, and runtime file controls that the original async logger already carried.
- That also means runtime sink mutations still alias in both directions: changing file append mode, auto-flush, rotation, or other sink helper state through a later unwrapped logger changes the same live runtime sink that the original `AsyncLogger[S]` already held.

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

If `full` is still kept elsewhere, it continues sharing that same live runtime state with `public_logger`.

### Error Case

e.g.:
- If callers later need APIs outside the library facade, they must unwrap with `to_async_logger()`.

- The conversion does not clear pending items or reset runtime state.

- If callers later need state helpers such as `pending_count()` or `state()`, they must unwrap again with `to_async_logger()`.

- Projection does not normalize failure snapshots; a later unwrap can still show combinations such as retained `last_error()` with remaining `pending_count()` when the wrapped async logger really ended up in that state.

- Projection also does not normalize delegated shutdown results; a later unwrap can still show `is_closed=true` together with retained `has_failed()`, the same `last_error()`, and the same retained dropped-count cleanup that accumulated behind the facade.

- Projection also does not normalize richer runtime sink state; if the original async logger already carried queued runtime data or file-backed helper state, a later unwrap still exposes that same live state.

- Projection does not create an isolated wrapper copy. If callers keep the original `AsyncLogger[S]`, then later facade-level writes, shutdown, or sink-helper mutations still affect that original handle too.

### Notes

1. Use this when package boundaries should avoid exposing the full async logger type.

2. This is a projection API, not a reconfiguration step.

3. Use `build_library_async_logger(...)` or `build_library_async_text_logger(...)` when construction and narrowing should happen together from config.
