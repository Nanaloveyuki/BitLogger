---
name: async-logger-wait-idle
group: api
category: async
update-time: 20260512
description: Wait until the async logger backlog drains to zero or a worker failure interrupts normal progress.
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
- If `has_failed()` becomes `true`, waiting stops early instead of looping forever.
- This API does not close the logger or stop the worker.
- It is narrower than `shutdown()` and is useful when the logger should continue to be used later.

### How to Use

Here are some specific examples provided.

#### When Need A Drain Barrier Without Shutdown

When code should wait for queued work to flush before continuing:
```moonbit
await logger.wait_idle()
```

In this example, the caller waits for backlog drain but leaves the logger usable afterward.

#### When Need Phase Boundaries In Tests

When a test wants to ensure earlier async logs were processed:
```moonbit
await logger.wait_idle()
println("phase complete")
```

In this example, the wait acts as a barrier between test phases.

### Error Case

e.g.:
- If the worker has failed, `wait_idle()` stops waiting even if pending records remain.

- If the worker was never started, pending records may not drain and callers should not expect idle progress automatically.

### Notes

1. Use this helper when you want a drain barrier without closing the logger.

2. Prefer `shutdown()` when lifecycle completion matters more than continued reuse.
