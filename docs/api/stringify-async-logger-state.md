---
name: stringify-async-logger-state
group: api
category: async
update-time: 20260512
description: Serialize AsyncLoggerState into compact or pretty JSON text for logs and diagnostics.
key-word:
    - async
    - stringify
    - state
    - public
---

## Stringify-async-logger-state

Serialize `AsyncLoggerState` into JSON text. This is the highest-level diagnostic export helper for async logger snapshots when callers want immediate text output.

### Interface

```moonbit
pub fn stringify_async_logger_state(
  state : AsyncLoggerState,
  pretty~ : Bool = false,
) -> String {}
```

#### input

- `state : AsyncLoggerState` - Snapshot produced by `AsyncLogger::state()`.
- `pretty : Bool` - Whether JSON should be pretty-printed.

#### output

- `String` - JSON text for the async logger snapshot.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` returns compact JSON.
- `pretty=true` returns indented JSON suitable for human diagnostics.
- This helper is built on top of `async_logger_state_to_json(...)`.
- String output is convenient for logs, CLI output, and startup diagnostics.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable Diagnostics

When logger state should be printed for humans:
```moonbit
println(stringify_async_logger_state(logger.state(), pretty=true))
```

In this example, the pretty output is suitable for startup or incident diagnostics.

#### When Need Compact Structured Logs

When snapshot text should stay small:
```moonbit
println(stringify_async_logger_state(logger.state()))
```

In this example, compact JSON is emitted without extra formatting logic.

### Error Case

e.g.:
- If the snapshot contains an empty `last_error`, it is still included as an empty string in the serialized output.

- If callers need a JSON value instead of text, they should use `async_logger_state_to_json(...)` instead.

### Notes

Notes are here.

1. This API is the most convenient direct output path for async logger snapshots.

2. Use `pretty=true` for humans and the default compact mode for machine-oriented logs.

3. Pair with `AsyncLogger::state()` to capture a consistent point-in-time snapshot.

4. This helper is ideal for startup, shutdown, and failure reporting.
