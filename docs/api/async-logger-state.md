---
name: async-logger-state
group: api
category: async
update-time: 20260512
description: Read a full async logger runtime snapshot including queue counters, lifecycle flags, and runtime mode.
key-word:
    - async
    - state
    - diagnostics
    - public
---

## Async-logger-state

Read a complete async logger runtime snapshot for diagnostics. This API is the preferred way to inspect queue backlog, dropped counts, lifecycle status, and runtime mode before exporting them through JSON helpers when needed.

### Interface

```moonbit
pub fn[S] AsyncLogger::state(self : AsyncLogger[S]) -> AsyncLoggerState {}
```

#### input

- `self : AsyncLogger[S]` - The async logger whose runtime snapshot should be read.

#### output

- `AsyncLoggerState` - A snapshot containing runtime mode, worker support, queue counts, lifecycle flags, last error, and flush policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- `AsyncLoggerState` includes `runtime`, `pending_count`, `dropped_count`, `is_closed`, `is_running`, `has_failed`, `last_error`, and `flush_policy`.
- `state()` returns a point-in-time snapshot rather than a live handle.
- `async_logger_state_to_json(...)` and `stringify_async_logger_state(...)` convert the snapshot to stable diagnostic output.
- `runtime` embeds the result of `async_runtime_state()` so callers do not need to join separate helpers manually.

### How to Use

Here are some specific examples provided.

#### When Need Startup Diagnostics

When you want to expose current async logger mode and queue state at startup:
```moonbit
let logger = build_async_logger(config)
println(stringify_async_logger_state(logger.state(), pretty=true))
```

In this example, the snapshot can be printed directly without extra manual formatting.

And downstream operators can see both runtime mode and queue-related status together.

#### When Need Failure Investigation Data

When diagnosing async delivery issues:
```moonbit
let state = logger.state()
if state.has_failed {
  println(stringify_async_logger_state(state, pretty=true))
}
```

In this example, the same snapshot object works for conditional diagnostics and serialization.

### Error Case

e.g.:
- If no error has occurred, `last_error` is just an empty string.

- If the queue is empty, `pending_count` is `0`; this is normal and not a special error condition.

### Notes

1. Prefer this API over manually combining `pending_count()`, `dropped_count()`, and runtime-mode helpers.

2. Use `pretty=true` when emitting logs for humans and the compact form for machine-oriented payloads.
