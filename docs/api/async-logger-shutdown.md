---
name: async-logger-shutdown
group: api
category: async
update-time: 20260614
description: Gracefully stop an async logger by waiting for idle or clearing queued work, with worker-wait behavior depending on the active async runtime.
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
- In runtimes where shutdown clearing after idle is enabled, remaining backlog after `wait_idle()` triggers a fallback `close(clear=true)`.
- `clear=true` immediately closes and abandons pending records.
- In runtimes where shutdown waits for workers, the method then waits until `is_running()` becomes `false` before returning.
- In the current backend split, native-worker runtimes enable both the post-`wait_idle()` clear fallback and the final wait-for-worker phase, while compatibility runtimes skip both extra steps.
- That means a failure-short-circuited `wait_idle()` can still be followed by forced pending-to-dropped cleanup on native-worker runtimes, while compatibility runtimes close without that extra forced clear step.
- In the current tested failure path, native-worker shutdown turns the leftover pending item into one more dropped record, while compatibility shutdown leaves that leftover closed-queue count in `pending_count()` instead.
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

- If `wait_idle()` returns early because the worker failed, shutdown behavior after that point still depends on the active runtime's fallback and worker-wait rules.

- After a worker failure, native-worker shutdown may convert the remaining backlog into dropped records, while compatibility shutdown can leave the pending counter reflecting that leftover closed queue state.
- In the current direct regression coverage, that split appears as `pending_count() == 0` and `dropped_count()` increasing on native-worker runtimes, versus `pending_count() > 0` and no extra dropped cleanup on compatibility runtimes.

- In compatibility-style runtimes without background-worker waiting, shutdown still closes the logger but may not perform the extra wait-for-worker phase described for native-worker runtimes.

- If pending work exists but no worker was started, `shutdown(clear=false)` may never reach its later close step because it is still waiting inside `wait_idle()`.

- If callers skip `shutdown()` and only inspect flags manually, it is easier to leave the worker lifecycle in an unclear state.

### Notes

1. Prefer this API over raw `close()` in normal application shutdown paths.

2. Exact post-close waiting behavior depends on the active async runtime mode.

3. Choose `clear=true` only when loss of queued records is acceptable.

4. Pair it with `state()` or focused counters when tests need to assert whether shutdown drained backlog or converted it into dropped records.

5. Prefer `shutdown(clear=true)` when teardown must not depend on a still-running drain worker.
