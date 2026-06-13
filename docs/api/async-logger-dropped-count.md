---
name: async-logger-dropped-count
group: api
category: async
update-time: 20260512
description: Read the number of records dropped by the async logger because of overflow or queue clearing.
key-word:
    - async
    - logger
    - queue
    - public
---

## Async-logger-dropped-count

Read the cumulative number of records dropped by an async logger. This metric is useful when overflow policy or forced shutdown behavior may discard queued data.

### Interface

```moonbit
pub fn[S] AsyncLogger::dropped_count(self : AsyncLogger[S]) -> Int {}
```

#### input

- `self : AsyncLogger[S]` - Async logger whose dropped-record counter should be inspected.

#### output

- `Int` - Number of records dropped so far.

### Explanation

Detailed rules explaining key parameters and behaviors

- The counter increases when overflow policy discards records.
- The counter can also increase when `close(clear=true)` or `shutdown(clear=true)` abandons queued records.
- It can also increase when shutdown fallback logic converts remaining pending records into dropped records during a clear-close path.
- Later log attempts against an already closed queue do not add to this counter by themselves.
- This is a cumulative counter for the lifetime of the logger value.
- Use this helper when you need a focused loss metric rather than a full `state()` snapshot.

### How to Use

Here are some specific examples provided.

#### When Need To Detect Loss Under Pressure

When queue overflow may discard records:
```moonbit
if logger.dropped_count() > 0 {
  println("async log loss detected")
}
```

In this example, the code checks whether the async logger has already discarded records.

#### When Validate Shutdown Behavior In Tests

When a test intentionally clears the queue:
```moonbit
logger.close(clear=true)
ignore(logger.dropped_count())
```

In this example, the drop counter helps confirm that abandoned backlog was tracked.

### Error Case

e.g.:
- If no records have been dropped, the method simply returns `0`.

- If callers need to know why records were lost, they must interpret this metric together with overflow policy and shutdown behavior.

### Notes

1. This helper reports record loss only; it does not explain the full logger state.

2. Pair it with `pending_count()` or `state()` when investigating backlog pressure.
