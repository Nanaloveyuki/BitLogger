---
name: stringify-async-logger-state
group: api
category: async
update-time: 20260614
description: Serialize AsyncLoggerState into compact or pretty JSON text for logs and diagnostics using the canonical nested runtime snapshot shape.
key-word:
    - async
    - stringify
    - state
    - public
---

## Stringify-async-logger-state

Serialize `AsyncLoggerState` into JSON text. This is the highest-level diagnostic export helper for async logger snapshots or manually constructed state values when callers want immediate text output.

### Interface

```moonbit
pub fn stringify_async_logger_state(
  state : AsyncLoggerState,
  pretty~ : Bool = false,
) -> String {}
```

#### input

- `state : AsyncLoggerState` - Snapshot produced by `AsyncLogger::state()` or any manually constructed `AsyncLoggerState` value.
- `pretty : Bool` - Whether JSON should be pretty-printed.

#### output

- `String` - JSON text for the async logger snapshot.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` returns compact JSON.
- `pretty=true` returns indented JSON suitable for human diagnostics.
- This helper is built on top of `async_logger_state_to_json(...)`.
- Internally it stringifies the same JSON snapshot shape returned by the public export helper, using `@json_parser.stringify(...)` or `@json_parser.stringify_pretty(value, 2)`.
- The compact form matches snapshots such as `{"runtime":{"mode":"native_worker","background_worker":true},"pending_count":0,...}`.
- String output is convenient for logs, CLI output, and startup diagnostics.
- The serializer does not care whether the input came from a live logger read or a synthetic `AsyncLoggerState::new(...)` call.
- It also preserves mixed diagnostic states exactly as provided, such as a failure flag together with non-zero backlog.

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

- Stringification does not apply cleanup behavior; it only formats the supplied snapshot fields.

### Notes

1. The nested `runtime` section uses the same canonical mode labels as `stringify_async_runtime_state(...)`.

2. The compact output shape is already locked by the async runtime snapshot tests, so it is suitable for stable diagnostics and assertions.

3. Use `async_logger_state_to_json(...)` when the next consumer still needs a `JsonValue` for composition before final stringification.

4. Pair it with `AsyncLogger::state()` for current logger diagnostics, or with `AsyncLoggerState::new(...)` when exporting a manual snapshot built by tests or adapters.

