---
name: library-async-logger-shutdown
group: api
category: facade
update-time: 20260614
description: Gracefully stop a LibraryAsyncLogger by delegating to the wrapped async logger's shutdown behavior, including runtime-dependent drain and worker-wait rules.
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
- If the active async runtime uses shutdown clearing after idle and backlog still remains, the wrapped logger falls back to `close(clear=true)`.
- `clear=true` immediately closes and abandons pending records.
- In runtimes where shutdown waits for workers, the method then waits until the worker is no longer running before returning.
- After a worker-failure short-circuit, native-worker backends can still convert remaining backlog into dropped records, while compatibility backends skip that extra forced-clear step.
- In the current direct facade coverage, the wrapped logger ends that path with `pending_count() == 0` and one more dropped item on native-worker runtimes, versus a still-nonzero pending count and no extra dropped cleanup on compatibility runtimes.
- Delegated shutdown also does not clear retained worker failure state by itself. If the wrapped logger had already recorded a worker error, later inspection through `to_async_logger()` can still show `has_failed=true` and the same `last_error()` string after shutdown completes.
- The narrower library facade does not change any of these runtime-dependent shutdown rules; it only keeps the broader inspection helpers out of the direct public surface.
- Inspecting the logger later through `to_async_logger()` reveals the same delegated shutdown result rather than a rebuilt or translated lifecycle snapshot.

### How to Use

Here are some specific examples provided.

#### When Need Graceful Async Library Shutdown

When a service should stop logging only after queued records are drained:
```moonbit
logger.shutdown()
```

In this example, the facade waits for normal drain behavior before final closure.

#### When Need Fast Shutdown Under Pressure

When teardown should prefer speed over preserving backlog:
```moonbit
logger.shutdown(clear=true)
```

In this example, pending work is abandoned intentionally so shutdown can complete sooner.

And the decision still applies to the same wrapped async logger state rather than a separate library-specific queue.

### Error Case

e.g.:
- If `clear=true`, pending records are intentionally dropped rather than drained.

- In compatibility-style runtimes without background-worker waiting, shutdown still closes the logger but may not perform the extra wait-for-worker phase described for native-worker runtimes.

- Even when delegated shutdown finishes with `is_closed=true`, callers can still observe retained `has_failed()` and `last_error()` on the unwrapped logger if the worker had already failed before shutdown cleanup completed.

- If callers skip `shutdown()` and only inspect flags manually, it is easier to leave the worker lifecycle in an unclear state.

- If callers need to inspect `pending_count()`, `dropped_count()`, `is_running()`, or failure state during shutdown analysis, they must unwrap first with `to_async_logger()`.

### Notes

1. Prefer this API over low-level closure control in normal library shutdown paths.

2. Exact post-close waiting behavior depends on the active async runtime mode.

3. Choose `clear=true` only when loss of queued records is acceptable.

4. Use `to_async_logger()` first when shutdown orchestration also needs direct lifecycle or backlog inspection.
