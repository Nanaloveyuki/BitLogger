---
name: async-logger-state-type
group: api
category: async
update-time: 20260614
description: Public async logger state alias used for queue, lifecycle, runtime, and flush-policy diagnostics.
key-word:
    - async
    - logger
    - state
    - public
---

## Async-logger-state-type

`AsyncLoggerState` is the public snapshot type used to describe an async logger's runtime status. It is a direct alias to the async logger state model returned by `AsyncLogger::state()` and used by async diagnostics serializers.

### Interface

```moonbit
pub type AsyncLoggerState = @utils.AsyncLoggerState
```

#### output

- `AsyncLoggerState` - Public async logger snapshot containing `runtime`, `pending_count`, `dropped_count`, `is_closed`, `is_running`, `has_failed`, `last_error`, and `flush_policy`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a live logger handle.
- The `runtime` field embeds an `AsyncRuntimeState` snapshot.
- The remaining fields capture queue counts, lifecycle status, failure state, last error text, and active flush policy.
- `AsyncLogger::state()` returns this type directly, while `async_logger_state_to_json(...)` and `stringify_async_logger_state(...)` export the same data shape for diagnostics.
- `AsyncLogger::state()` currently builds this snapshot from `async_runtime_state()` plus the logger's current counters, lifecycle flags, last error, and flush policy.
- `AsyncLoggerState::new(...)` can also construct this type manually, but manual construction is synthetic snapshot data and does not read one live logger instant by itself.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Snapshot For Async Diagnostics

When application code should inspect async logger state before deciding how to report it:
```moonbit
let state : AsyncLoggerState = logger.state()
```

In this example, queue, lifecycle, and runtime information stay available as structured data.

#### When Need To Branch On Failure Or Backlog

When code should react to the current async logger condition:
```moonbit
let state = logger.state()
if state.has_failed || state.pending_count > 0 {
  println(stringify_async_logger_state(state, pretty=true))
}
```

In this example, the typed snapshot supports both logic and later export.

### Error Case

e.g.:
- `AsyncLoggerState` itself does not have a runtime failure mode.

- `last_error` may be an empty string when no failure has occurred, which is normal and not a special error condition by itself.

- Because this is just a data shape, manual construction can represent combinations that do not come from a live logger at one exact instant.

### Notes

1. Use `AsyncLogger::state()` when you need a value of this type from one logger instance.

2. Use `AsyncRuntimeState` when only backend-level capability information is needed and logger-instance state is unnecessary.

3. Use `async_logger_state_to_json(...)` or `stringify_async_logger_state(...)` when this snapshot should leave typed space and become stable diagnostic output.
