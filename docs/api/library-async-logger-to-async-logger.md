---
name: library-async-logger-to-async-logger
group: api
category: facade
update-time: 20260707
description: Recover the underlying full async logger from the library-facing async facade without rebuilding, copying, or detaching the wrapped async state.
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
- The returned `AsyncLogger[S]` is still that same live wrapped value, so later facade writes or lifecycle calls continue mutating the very logger instance that was unwrapped earlier.
- Repeated `to_async_logger()` calls therefore do not create independent snapshots. They keep exposing the same underlying logger state that the facade already wraps.
- Use this when code needs wider async logger APIs outside the library facade.
- This is the step required for helpers such as `pending_count()`, `dropped_count()`, `state()`, `wait_idle()`, `has_failed()`, `last_error()`, or broader composition methods that are intentionally hidden by `LibraryAsyncLogger[S]`.
- It is also the step that exposes the real post-run or post-shutdown state after facade-level lifecycle calls, because those calls delegated to this same wrapped logger all along.
- That includes failure/backlog combinations and shutdown results exactly as they accumulated behind the facade.
- Because the same live value is shared, code can unwrap once, keep that `AsyncLogger[S]` handle, and then observe `pending_count()`, `state()`, `is_closed()`, or failure fields changing as later facade-level `info(...)`, `log(...)`, `run()`, or `shutdown(...)` calls execute.
- That also means the unwrapped logger can already be both `is_closed=true` and `has_failed=true`, with the same retained `last_error()` string and the same dropped-count cleanup outcome that delegated shutdown left behind.
- If the wrapped sink type has richer helper APIs, unwrapping also restores access to that same sink helper surface through the original `AsyncLogger[S]` value.
- When the wrapped sink is `RuntimeSink`, that same unwrap also preserves queued runtime state and file-backed helper behavior exactly as they existed behind the facade, including runtime file state snapshots and file control methods.
- Runtime sink helper mutations are still live too. Changing file append mode, auto-flush, rotation, reopen state, or related helper-managed file state through the unwrapped logger changes the same wrapped runtime sink that later facade writes and shutdown behavior continue using.

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

The same handle keeps reflecting later facade writes instead of becoming a detached snapshot.

### Error Case

e.g.:
- If callers only need library-facing async write or lifecycle APIs, unwrapping is unnecessary.

- Unwrapping does not start or stop the background runtime by itself.

- Recovering the full async logger does not clear queue contents or reset failure state.

- Unwrapping does not create an isolated snapshot. If later facade calls enqueue more records or change lifecycle state, the previously unwrapped logger handle reflects those same live mutations.

- Unwrapping does not convert facade lifecycle history into a simplified snapshot; any retained `last_error()`, pending backlog, dropped counts, or sink runtime details stay exactly as they were on the wrapped logger.

- If facade-level `run()` or `shutdown()` already ended in a failure-retaining state, unwrapping can therefore expose combinations such as `is_closed=true` together with `has_failed=true`, the same `last_error()`, and the same leftover dropped-count cleanup.

- Recovering the full async logger also does not translate runtime sink helper state into a simpler snapshot; queue counters, file availability, file failure counters, and runtime file controls stay exactly as they were on the wrapped logger.

- Recovering the full async logger also does not isolate later runtime sink helper mutations. If unwrapped code changes file helper state, later facade writes and shutdown still run against that same updated wrapped sink.

### Notes

1. Use this only when the narrower async facade is no longer sufficient.

2. This is the inverse projection of `AsyncLogger::to_library_async_logger()`.

3. Use `LibraryAsyncLogger[S]` directly when the narrower package-facing surface is still sufficient.
