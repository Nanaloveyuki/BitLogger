---
name: async-logger-is-running
group: api
category: async
update-time: 20260614
description: Read whether the async logger worker loop is currently running, regardless of queue backlog or recorded failure state.
key-word:
    - async
    - logger
    - lifecycle
    - public
---

## Async-logger-is-running

Read whether the async logger worker is currently active. This helper is useful for runtime diagnostics and shutdown coordination.

### Interface

```moonbit
pub fn[S] AsyncLogger::is_running(self : AsyncLogger[S]) -> Bool {}
```

#### input

- `self : AsyncLogger[S]` - Async logger whose worker state should be inspected.

#### output

- `Bool` - Whether the async worker loop is currently running.

### Explanation

Detailed rules explaining key parameters and behaviors

- `run()` sets the running state while the worker loop is active.
- The flag is cleared when the worker exits normally or after failure handling finishes.
- A logger may be closed while still running briefly during final drain or shutdown processing.
- This helper is only a direct read of the current `is_running` ref; it does not wait, synchronize, or infer why the value is what it is.
- This helper focuses on worker activity rather than queue size or failure details.
- `is_running()` can be `false` even when `pending_count()` is still nonzero, for example if the worker was never started or if it exited after a recorded failure.

### How to Use

Here are some specific examples provided.

#### When Need Worker Activity Diagnostics

When runtime output should show whether the worker loop is active:
```moonbit
println(logger.is_running().to_string())
```

In this example, diagnostics can distinguish an idle configured logger from one with an active worker.

#### When Coordinate Shutdown Waiting

When code should poll worker completion explicitly:
```moonbit
while logger.is_running() {
  @async.pause()
}
```

In this example, callers watch the worker lifecycle directly.

### Error Case

e.g.:
- If `is_running()` is `false`, pending records may still exist if the worker was never started or has already failed.

- If callers need a one-shot lifecycle flow, `shutdown()` is usually better than manual polling.

- If `is_running()` is `true`, that still does not guarantee healthy drain progress; callers may need `has_failed()` or `state()` for failure context.

- Under concurrent activity, the returned value may change immediately after it is read.

### Notes

1. Use this helper for worker activity checks, not as a complete health signal.

2. Pair it with `has_failed()` or `state()` when diagnosing stalled pipelines.

3. Pair it with `pending_count()` when you need to distinguish an idle worker from a stopped logger that still has backlog.
