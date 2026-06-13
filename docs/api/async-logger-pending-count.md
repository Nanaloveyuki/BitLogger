---
name: async-logger-pending-count
group: api
category: async
update-time: 20260614
description: Read the current number of queued records that have not yet been drained or cleared from the async logger pipeline.
key-word:
    - async
    - logger
    - queue
    - public
---

## Async-logger-pending-count

Read the current number of queued records that are still waiting to be processed. This API is the most direct backlog metric for an async logger instance.

### Interface

```moonbit
pub fn[S] AsyncLogger::pending_count(self : AsyncLogger[S]) -> Int {}
```

#### input

- `self : AsyncLogger[S]` - Async logger whose current backlog should be inspected.

#### output

- `Int` - Current number of pending records still in the async pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- The count increases when records are accepted into the queue.
- The count decreases as the worker drains records.
- The count is also reset to `0` when queued records are abandoned through clear-close paths such as `close(clear=true)`.
- Log attempts against a closed queue do not create new pending backlog.
- This is a point-in-time metric and may change immediately after it is read.
- Use this helper when a single backlog number is enough and a full `state()` snapshot is unnecessary.

### How to Use

Here are some specific examples provided.

#### When Need A Fast Backlog Check

When code should observe queue pressure directly:
```moonbit
let pending = logger.pending_count()
```

In this example, callers get the current queue backlog without building a full diagnostics snapshot.

#### When Wait For Near-idle Conditions

When operators or tests want to inspect drain progress:
```moonbit
if logger.pending_count() == 0 {
  println("queue idle")
}
```

In this example, the queue backlog is checked directly.

### Error Case

e.g.:
- If the worker is not running, `pending_count()` may stay above `0` until records are drained or cleared.

- If `wait_idle()` returns early because `has_failed()` became `true`, `pending_count()` may still be above `0` until later cleanup or clear-close handling runs.

- If the queue is empty, the method simply returns `0`.

### Notes

1. Use `state()` when you also need dropped counts, failure state, or runtime mode.

2. This helper is useful for lightweight health checks and tests.

3. Pair it with `is_running()` or `has_failed()` when backlog alone is not enough to explain whether the worker is actively draining, stopped, or failed.
