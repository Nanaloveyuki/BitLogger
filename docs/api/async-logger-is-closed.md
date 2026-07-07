---
name: async-logger-is-closed
group: api
category: async
update-time: 20260707
description: Read whether the async logger has entered closed lifecycle state and should no longer be treated as a normal active enqueue target.
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
- This helper is derived from the current lifecycle phase rather than from an independent closed flag ref.
- This helper reflects lifecycle state only and does not indicate whether the worker is still draining.
- `is_closed()` becoming `true` does not imply the logger reached a clean success state. Failure flags, retained `last_error()`, and remaining backlog-related counters can still reflect the earlier worker outcome.
- After shutdown on a worker-failure path, `is_closed()` can therefore be `true` while retained failure state still remains visible under `phase=closed_failed`.
- Late log attempts are rejected in the shared async log path after closure, so `is_closed()` now aligns with a stable post-close enqueue rejection contract.

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

- If callers need to know whether the logger is also terminal or rerunnable, they should inspect `state().terminal` or `state().can_rerun`.

- Closing a logger does not by itself reset `has_failed()` or `last_error()`.

- A closed logger can still report leftover `pending_count()` or `dropped_count()` values from the shutdown path, so `is_closed()` alone is not enough to infer whether backlog was fully drained or explicitly abandoned.

### Notes

1. Closed state and running state are related but not identical.

2. Use this helper when lifecycle control matters more than queue counters.

3. Pair it with `pending_count()`, `is_running()`, or `state()` when you need to understand what closure means for remaining backlog on a live logger instance.
