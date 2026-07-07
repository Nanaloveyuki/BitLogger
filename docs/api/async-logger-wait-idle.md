---
name: async-logger-wait-idle
group: api
category: async
update-time: 20260707
description: Wait until the async logger backlog drains to zero or a worker failure interrupts normal progress, using the repo's direct async call style.
key-word:
    - async
    - logger
    - queue
    - public
---

## Async-logger-wait-idle

Wait until the async logger backlog drains to zero. This helper is useful when callers want to observe idle state without fully shutting down the logger.

### Interface

```moonbit
pub async fn[S] AsyncLogger::wait_idle(self : AsyncLogger[S]) -> Unit {}
```

#### input

- `self : AsyncLogger[S]` - Async logger whose backlog should be waited on.

#### output

- `Unit` - No return value. The method completes when the logger becomes idle or failure prevents normal progress.

### Explanation

Detailed rules explaining key parameters and behaviors

- The helper keeps yielding while `pending_count() > 0`.
- If `has_failed()` becomes `true`, waiting stops early instead of continuing to spin.
- This API does not close the logger or stop the worker.
- A return from `wait_idle()` therefore means either backlog reached `0` or failure interrupted normal drain progress.
- In the stronger lifecycle model, the common post-failure interpretation is `phase=failed` together with `backlog_retained=true` while `pending_count() > 0` remains visible.
- `wait_idle()` does not clear retained failure state by itself, so if pending records remain after a worker failure, later `wait_idle()` calls also short-circuit until another path changes that state.
- A later `run()` can make `wait_idle()` meaningful again for the retained backlog, but only after that new worker invocation has actually started and reset the stale failure flag.
- If no worker is draining the queue and no failure flag is raised, `wait_idle()` can wait indefinitely.
- It is narrower than `shutdown()` and is useful when the logger should continue to be used later.

### How to Use

Here are some specific examples provided.

#### When Need A Drain Barrier Without Shutdown

When code should wait for queued work to flush before continuing:
```moonbit
logger.wait_idle()
```

In this example, the caller waits for backlog drain but leaves the logger usable afterward.

#### When Need Phase Boundaries In Tests

When a test wants to ensure earlier async logs were processed:
```moonbit
logger.wait_idle()
println("phase complete")
```

In this example, the wait acts as a barrier between test phases.

### Error Case

e.g.:
- If the worker has failed, `wait_idle()` stops waiting even if pending records remain.

- If the worker was never started, or if nothing is making pending records decrease, `wait_idle()` can block indefinitely.

- If callers need backlog cleanup after a failure-short-circuit, they still need a later `close(clear=true)` or `shutdown(...)` path.
- In the current direct coverage, `wait_idle()` can return with `pending_count() > 0` after a worker failure, and a later `shutdown(...)` call will convert that retained backlog into dropped records before returning.

- If callers retry `wait_idle()` immediately after such a failure without restarting the worker or forcing cleanup first, the call can return again with the same retained pending backlog.

### Notes

1. Use this helper when you want a drain barrier without closing the logger.

2. Prefer `shutdown()` when lifecycle completion matters more than continued reuse.

3. Pair it with `pending_count()` or `state()` when you need to distinguish true idleness from an early stop caused by worker failure.
