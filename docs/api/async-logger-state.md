---
name: async-logger-state
group: api
category: async
update-time: 20260614
description: Read a full async logger runtime snapshot including the embedded runtime snapshot, queue counters, lifecycle flags, last error, and flush policy.
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
- `state()` returns a value snapshot rather than a live handle.
- This helper is equivalent to `AsyncLoggerState::new(async_runtime_state(), self.pending_count(), self.dropped_count(), self.is_closed(), self.is_running(), self.has_failed(), self.last_error(), self.flush_policy())`.
- `async_logger_state_to_json(...)` and `stringify_async_logger_state(...)` convert the snapshot to stable diagnostic output.
- `runtime` embeds the result of `async_runtime_state()` so callers do not need to join separate helpers manually.
- Because the snapshot is assembled field by field when `state()` is called, later logger changes require calling `state()` again rather than reusing an older `AsyncLoggerState` value as if it refreshed itself.
- That field-by-field assembly also means this helper is not an atomic freeze across all refs; under concurrent logger activity, neighboring fields can reflect slightly different instants.

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

- `flush_policy` reports the logger's configured async flush mode, not whether a flush has already happened.

- If concurrent logger activity is still changing counters or flags while `state()` runs, the returned value is still useful for diagnostics but should not be treated as a transactional snapshot.

### Notes

1. Prefer this API over manually combining `pending_count()`, `dropped_count()`, and runtime-mode helpers.

2. Use `pretty=true` when emitting logs for humans and the compact form for machine-oriented payloads.

3. Use `AsyncLoggerState::new(...)` only when tests or adapters need to construct a manual snapshot instead of reading one directly from a logger instance.

4. If consumers need stronger cross-field consistency than a diagnostic snapshot, they should not assume `state()` provides an atomic read barrier.
