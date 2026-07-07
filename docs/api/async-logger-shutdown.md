---
name: async-logger-shutdown
group: api
category: async
update-time: 20260707
description: Gracefully stop an async logger by waiting for idle or clearing queued work, then waiting for any active worker to finish.
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
- If `wait_idle()` returned early because a worker failure left backlog behind, shutdown now converts that retained pending backlog into dropped records with `close(clear=true)` before returning.
- `clear=true` immediately closes and abandons pending records, even if no worker was ever started for that logger.
- After either shutdown branch starts closing, the helper waits until `is_running()` becomes `false` before returning.
- In lifecycle-phase terms, shutdown drives the logger into `closing` while a worker is still active, then settles into `closed` or `closed_failed` once that worker has exited.
- Shutdown itself does not clear retained worker failure state. If a previous `run()` already recorded `has_failed=true` and a non-empty `last_error()`, those diagnostics can remain visible after shutdown completes.
- Because `clear=false` delegates to `wait_idle()` first, shutdown can also wait indefinitely when pending records exist but no worker is making progress and no failure flag is raised.

### How to Use

Here are some specific examples provided.

#### When Need Graceful Service Shutdown

When a service should stop logging only after queued records are drained:
```moonbit
logger.shutdown()
```

In this example, the logger waits for normal drain behavior before final closure.

#### When Need Fast Shutdown Under Pressure

When teardown should prefer speed over preserving backlog:
```moonbit
logger.shutdown(clear=true)
```

In this example, pending work is abandoned intentionally so shutdown can complete sooner.

### Error Case

e.g.:
- If `clear=true`, pending records are intentionally dropped rather than drained.

- If `wait_idle()` returns early because the worker failed, shutdown still finishes by converting retained pending backlog into dropped records before it returns.

- Even after shutdown finishes with `is_closed=true`, callers can still observe retained `has_failed()` and `last_error()` from an earlier worker failure.

- If pending work exists but no worker was started, `shutdown(clear=false)` may never reach its later close step because it is still waiting inside `wait_idle()`.

- If callers skip `shutdown()` and only inspect flags manually, it is easier to leave the worker lifecycle in an unclear state.

### Notes

1. Prefer this API over raw `close()` in normal application shutdown paths.

2. `shutdown()` now always waits for an already-running worker to leave `is_running=true` before returning.

3. Choose `clear=true` only when loss of queued records is acceptable.

4. Pair it with `state()` or focused counters when tests need to assert whether shutdown drained backlog or converted it into dropped records.

5. Prefer `shutdown(clear=true)` when teardown must not depend on a still-running drain worker.
