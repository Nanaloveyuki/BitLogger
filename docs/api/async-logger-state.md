---
name: async-logger-state
group: api
category: async
update-time: 20260707
description: Read a full async logger runtime snapshot including runtime, lifecycle phase, derived lifecycle conclusions, queue counters, last error, and flush policy.
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

- `AsyncLoggerState` - A snapshot containing runtime mode, lifecycle phase, derived lifecycle conclusions, queue counts, last error, and flush policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- `AsyncLoggerState` includes `runtime`, `phase`, `pending_count`, `dropped_count`, `is_closed`, `is_running`, `has_failed`, `backlog_retained`, `can_rerun`, `terminal`, `last_error`, and `flush_policy`.
- `state()` returns a value snapshot rather than a live handle.
- This helper is equivalent to `AsyncLoggerState::new(async_runtime_state(), self.phase(), self.pending_count(), self.dropped_count(), self.last_error(), self.flush_policy())`.
- `async_logger_state_to_json(...)` and `stringify_async_logger_state(...)` convert the snapshot to stable diagnostic output.
- `runtime` embeds the result of `async_runtime_state()` from the moment `state()` is called, so callers do not need to join separate helpers manually.
- The runtime portion is therefore recomputed from the active backend helper on each call, while the remaining fields come from the logger's current counters, lifecycle phase, derived lifecycle conclusions, and flush policy at that same general moment.
- Because the snapshot is assembled field by field when `state()` is called, later logger changes require calling `state()` again rather than reusing an older `AsyncLoggerState` value as if it refreshed itself.
- That field-by-field assembly also means this helper is not an atomic freeze across all refs; under concurrent logger activity, neighboring fields can reflect slightly different instants.
- `phase` is the primary lifecycle conclusion. The current public phases are `ready`, `running`, `failed`, `closing`, `closed`, and `closed_failed`.
- `backlog_retained=true` means pending backlog still exists while the logger is no longer actively draining it.
- `can_rerun=true` means the current phase still allows a future `run()` call to restart drain work.
- `terminal=true` means the logger is closed, no worker is active, and no pending backlog remains.
- After a worker failure, snapshots can legitimately report `phase=failed`, `has_failed=true`, `backlog_retained=true`, a non-empty `last_error`, and `pending_count>0` together until later cleanup or restart changes them.
- After shutdown cleanup on an already failed logger, snapshots can also legitimately report `phase=closed_failed`, `is_closed=true`, `terminal=true`, retained `has_failed=true`, and the same `last_error()`.
- `state()` only reports the current field values; it does not clear failure state, drain backlog, or synchronize pending work by itself.

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

And the reported failure fields can still appear together with non-zero backlog when a worker stopped early.

### Error Case

e.g.:
- If no error has occurred, `last_error` is just an empty string.

- If the queue is empty, `pending_count` is `0`; this is normal and not a special error condition.

- `flush_policy` reports the logger's configured async flush mode, not whether a flush has already happened.

- The embedded `runtime` object is also just a snapshot of the current backend helper result at read time; `state()` does not cache it onto the logger for later reuse.

- If concurrent logger activity is still changing counters or flags while `state()` runs, the returned value is still useful for diagnostics but should not be treated as a transactional snapshot.

- A snapshot showing `has_failed=true` does not imply `pending_count` is already `0`; remaining queued records may still be visible until later cleanup or restart.

- A snapshot showing `is_closed=true` also does not imply failure state was cleared; after failure-driven shutdown, `phase=closed_failed`, `has_failed=true`, and the recorded `last_error` can still remain visible until a later `run()` actually restarts the logger.

### Notes

1. Prefer this API over manually combining `pending_count()`, `dropped_count()`, and runtime-mode helpers.

2. Use `pretty=true` when emitting logs for humans and the compact form for machine-oriented payloads.

3. Use `AsyncLoggerState::new(...)` only when tests or adapters need to construct a manual snapshot instead of reading one directly from a logger instance.

4. If consumers need stronger cross-field consistency than a diagnostic snapshot, they should not assume `state()` provides an atomic read barrier.
