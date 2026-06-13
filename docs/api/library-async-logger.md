---
name: library-async-logger
group: api
category: facade
update-time: 20260614
description: Public library-facing async logger facade type used to expose a narrower surface than AsyncLogger while preserving sink typing.
key-word:
    - library
    - async
    - facade
    - public
---

## Library-async-logger

`LibraryAsyncLogger[S]` is the public library-facing async logger facade type. It wraps `AsyncLogger[S]` and keeps queue-backed async logging behavior while intentionally exposing a narrower public surface for package boundaries.

### Interface

```moonbit
pub struct LibraryAsyncLogger[S] {
  inner : AsyncLogger[S]
}
```

#### output

- `LibraryAsyncLogger[S]` - Public library-oriented async logger wrapper over a concrete sink type `S`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public facade struct, not a type alias.
- The wrapped sink type `S` is preserved, so sink-specific typing remains available through the facade type parameter.
- The facade keeps common library-safe async operations such as `new(...)`, `with_target(...)`, `child(...)`, `bind(...)`, `is_enabled(...)`, `run()`, `shutdown()`, and the main async write methods `log(...)`, `info(...)`, `warn(...)`, and `error(...)`.
- `LibraryAsyncLogger::new(...)` delegates to `async_logger(...)`, so the same async queue, raising flush callback, and runtime-dependent lifecycle behavior still exist behind the narrower facade.
- It does not expose the wider `AsyncLogger[S]` composition surface or the async state and lifecycle inspection helpers directly.
- Call `to_async_logger()` when later code must recover the full underlying `AsyncLogger[S]` surface.
- That recovered logger is the same live async value, so queue counters, retained failure state, runtime-dependent shutdown outcomes, and sink helper access are preserved rather than recomputed.

### How to Use

Here are some specific examples provided.

#### When Need A Narrower Public Async Logger Type

When a package should expose async logging capability without publishing the full `AsyncLogger[S]` API:
```moonbit
let logger : LibraryAsyncLogger[@bitlogger.ConsoleSink] = LibraryAsyncLogger::new(
  @bitlogger.console_sink(),
  target="lib.async",
)
```

In this example, the package boundary exposes the library async facade instead of the full async logger type.

#### When Need To Recover The Full Async Logger Later

When a library-facing async facade should later be adapted back into the ordinary async logger surface:
```moonbit
let full = logger.to_async_logger()
ignore(full.pending_count())
```

In this example, the facade can be unwrapped when broader async lifecycle or state operations are needed internally.

### Error Case

e.g.:
- `LibraryAsyncLogger[S]` itself does not have a runtime failure mode.

- Runtime behavior still depends on the wrapped sink `S` and async runtime support, so sink-specific or target-specific limitations remain unchanged behind the facade.

- Post-close logging behavior, queue state, and failure-state behavior remain those of the wrapped `AsyncLogger[S]`; the facade only narrows what is directly exposed.

- If the wrapped async logger later ends in a mixed diagnostic state such as `has_failed=true` with retained backlog, unwrapping exposes that exact state instead of a library-specific translation.

- Helpers such as `pending_count()`, `dropped_count()`, `is_closed()`, `is_running()`, `has_failed()`, `last_error()`, `flush_policy()`, `state()`, and `wait_idle()` remain on the underlying `AsyncLogger[S]` and require `to_async_logger()` first.

### Notes

1. Use `LibraryAsyncLogger::new(...)`, `build_library_async_logger(...)`, or `parse_and_build_library_async_logger(...)` when you need a value of this type.

2. Use `AsyncLogger[S]` directly when exposing the full async lifecycle and state surface is acceptable.

3. Use `to_async_logger()` when internal code later needs the broader lifecycle/state helpers without changing the facade type exposed at the package boundary.
