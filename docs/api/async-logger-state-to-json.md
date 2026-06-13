---
name: async-logger-state-to-json
group: api
category: async
update-time: 20260614
description: Convert an AsyncLoggerState snapshot into a JSON value for diagnostics and transport using the canonical nested runtime shape and flush-policy labels.
key-word:
    - async
    - state
    - json
    - public
---

## Async-logger-state-to-json

Convert `AsyncLoggerState` into a `JsonValue`. This helper is the structured export path for async logger runtime snapshots or manually constructed state values when callers want machine-readable diagnostics instead of a plain string.

### Interface

```moonbit
pub fn async_logger_state_to_json(state : AsyncLoggerState) -> @json_parser.JsonValue {}
```

#### input

- `state : AsyncLoggerState` - Snapshot produced by `AsyncLogger::state()` or any manually constructed `AsyncLoggerState` value.

#### output

- `JsonValue` - Structured JSON representation of the async logger snapshot.

### Explanation

Detailed rules explaining key parameters and behaviors

- The JSON includes runtime mode, worker support, queue counters, lifecycle flags, last error, and flush policy.
- The top-level fields are `runtime`, `pending_count`, `dropped_count`, `is_closed`, `is_running`, `has_failed`, `last_error`, and `flush_policy`.
- The nested `runtime` field reuses `async_runtime_state_to_json(...)`, and `flush_policy` is serialized with the canonical labels `Never`, `Batch`, or `Shutdown`.
- The public helper returns the same internal JSON snapshot shape used by `stringify_async_logger_state(...)`, so both export paths stay aligned without duplicate field assembly logic.
- This helper is suitable for health endpoints, diagnostics payloads, and custom serialization flows.
- It shares the same stable field names used by `stringify_async_logger_state(...)`.
- The state must already have been captured or constructed before serialization.
- Serialization preserves whatever snapshot combination it receives, including failure flags together with remaining backlog counts.

### How to Use

Here are some specific examples provided.

#### When Need Machine-readable Diagnostics

When the snapshot should be embedded into a JSON payload:
```moonbit
let state_json = async_logger_state_to_json(logger.state())
```

In this example, callers receive a structured value that can be composed into larger JSON objects.

#### When Need A Snapshot Before Custom Stringify

When another serializer or pipeline expects a JSON value:
```moonbit
let payload = async_logger_state_to_json(logger.state())
println(@json_parser.stringify(payload))
```

In this example, the helper stays useful even outside the built-in stringify wrapper.

### Error Case

e.g.:
- If the snapshot contains no error, `last_error` is serialized as an empty string.

- If the queue is empty, `pending_count` and `dropped_count` are still serialized normally as numeric values.

- If `has_failed` is `true`, serialization does not force `pending_count` to `0` or clear `last_error`; it reports the snapshot exactly as provided.

### Notes

1. This helper preserves the nested runtime snapshot instead of flattening `mode` and `background_worker` onto the top level.

2. The resulting object matches the compact string form produced by `stringify_async_logger_state(...)` after JSON stringification.

3. Use this API when downstream code wants a JSON value rather than a ready-made string.

4. Pair it with `AsyncLogger::state()` when you want current logger data, or with `AsyncLoggerState::new(...)` when tests or adapters are exporting a synthetic snapshot.

