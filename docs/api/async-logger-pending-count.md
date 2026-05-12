---
name: async-logger-pending-count
group: api
category: async
update-time: 20260512
description: Read the current number of queued records that have not yet been drained by the async logger worker.
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

- If the queue is empty, the method simply returns `0`.

### Notes

1. Use `state()` when you also need dropped counts, failure state, or runtime mode.

2. This helper is useful for lightweight health checks and tests.
