---
name: async-logger-shutdown
group: api
category: async
update-time: 20260512
description: Gracefully stop an async logger by waiting for idle or clearing queued work, then waiting for the worker to finish.
key-word:
    - async
    - logger
    - lifecycle
    - public
---

## Async-logger-shutdown

Gracefully stop an async logger. This is the main high-level shutdown API for async logging because it coordinates drain behavior, closure, and worker completion.

### Interface

```moonbit
pub async fn[S] AsyncLogger::shutdown(self : AsyncLogger[S], clear? : Bool = false) -> Unit {}
```

#### input

- `self : AsyncLogger[S]` - Async logger that should be shut down.
- `clear : Bool` - Whether pending records should be abandoned immediately instead of waiting for idle first.

#### output

- `Unit` - No return value. The method completes after shutdown coordination finishes.

### Explanation

Detailed rules explaining key parameters and behaviors

- `clear=false` first waits for idle, then closes the logger.
- If backlog still remains after waiting, shutdown falls back to `close(clear=true)`.
- `clear=true` immediately closes and abandons pending records.
- The method waits until `is_running()` becomes `false` before returning.

### How to Use

Here are some specific examples provided.

#### When Need Graceful Service Shutdown

When a service should stop logging only after queued records are drained:
```moonbit
await logger.shutdown()
```

In this example, the logger waits for normal drain behavior before final closure.

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

1. Prefer this API over raw `close()` in normal application shutdown paths.

2. Choose `clear=true` only when loss of queued records is acceptable.
