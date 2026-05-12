---
name: async-logger-is-closed
group: api
category: async
update-time: 20260512
description: Read whether the async logger has been closed and should no longer accept normal new queue traffic.
key-word:
    - async
    - logger
    - lifecycle
    - public
---

## Async-logger-is-closed

Read whether the async logger has been closed. This helper is useful for lifecycle checks around shutdown and queue finalization.

### Interface

```moonbit
pub fn[S] AsyncLogger::is_closed(self : AsyncLogger[S]) -> Bool {}
```

#### input

- `self : AsyncLogger[S]` - Async logger whose closure state should be inspected.

#### output

- `Bool` - Whether the logger has already been closed.

### Explanation

Detailed rules explaining key parameters and behaviors

- `close(...)` sets the closed state immediately.
- `shutdown(...)` also results in a closed logger by the end of its lifecycle flow.
- A closed logger should no longer be treated as a normal active enqueue target.
- This helper reflects lifecycle state only and does not indicate whether the worker is still draining.

### How to Use

Here are some specific examples provided.

#### When Guard Late-stage Logging

When code should avoid treating a logger as fully active during teardown:
```moonbit
if logger.is_closed() {
  println("logger already closed")
}
```

In this example, teardown logic can branch on the closure state.

#### When Verify Shutdown Progress

When tests or diagnostics want to inspect lifecycle state:
```moonbit
logger.close()
ignore(logger.is_closed())
```

In this example, the helper confirms that close state was entered.

### Error Case

e.g.:
- If `is_closed()` returns `true`, pending records may still exist until drain or clear behavior completes.

- If callers need to know whether the worker is still active, they should also inspect `is_running()`.

### Notes

1. Closed state and running state are related but not identical.

2. Use this helper when lifecycle control matters more than queue counters.
