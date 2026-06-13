---
name: library-async-logger-shutdown
group: api
category: facade
update-time: 20260613
description: Gracefully stop a LibraryAsyncLogger by draining or clearing queued work, then waiting for the worker to finish.
key-word:
    - async
    - library
    - lifecycle
    - public
---

## Library-async-logger-shutdown

Gracefully stop a library-facing async logger. This is the high-level shutdown API for `LibraryAsyncLogger[S]` because it coordinates drain behavior, closure, and worker completion while preserving the narrower facade surface.

### Interface

```moonbit
pub async fn[S] LibraryAsyncLogger::shutdown(
  self : LibraryAsyncLogger[S],
  clear? : Bool = false,
) -> Unit {
```

#### input

- `self : LibraryAsyncLogger[S]` - Library-facing async logger that should be shut down.
- `clear : Bool` - Whether pending records should be abandoned immediately instead of waiting for idle first.

#### output

- `Unit` - No return value. The method completes after shutdown coordination finishes.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method delegates directly to the wrapped async logger's `shutdown(...)` behavior.
- `clear=false` first waits for idle, then closes the logger.
- `clear=true` immediately closes and abandons pending records.
- The method waits until the worker is no longer running before returning.

### How to Use

Here are some specific examples provided.

#### When Need Graceful Async Library Shutdown

When a service should stop logging only after queued records are drained:
```moonbit
await logger.shutdown()
```

In this example, the facade waits for normal drain behavior before final closure.

#### When Need Fast Shutdown Under Pressure

When teardown should prefer speed over preserving backlog:
```moonbit
await logger.shutdown(clear=true)
```

In this example, pending work is abandoned intentionally so shutdown can complete sooner.

### Error Case

e.g.:
- If `clear=true`, pending records are intentionally dropped rather than drained.

- If callers skip `shutdown()` and only inspect flags manually, it is easier to leave the worker lifecycle in an unclear state.

### Notes

1. Prefer this API over low-level closure control in normal library shutdown paths.

2. Choose `clear=true` only when loss of queued records is acceptable.
