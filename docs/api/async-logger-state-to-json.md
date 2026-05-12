---
name: async-logger-state-to-json
group: api
category: async
update-time: 20260512
description: Convert an AsyncLoggerState snapshot into a JSON value for diagnostics and transport.
key-word:
    - async
    - state
    - json
    - public
---

## Async-logger-state-to-json

Convert `AsyncLoggerState` into a `JsonValue`. This helper is the structured export path for async logger runtime snapshots when callers want machine-readable diagnostics instead of a plain string.

### Interface

```moonbit
pub fn async_logger_state_to_json(state : AsyncLoggerState) -> @json_parser.JsonValue {}
```

#### input

- `state : AsyncLoggerState` - Snapshot produced by `AsyncLogger::state()`.

#### output

- `JsonValue` - Structured JSON representation of the async logger snapshot.

### Explanation

Detailed rules explaining key parameters and behaviors

- The JSON includes runtime mode, worker support, queue counters, lifecycle flags, last error, and flush policy.
- This helper is suitable for health endpoints, diagnostics payloads, and custom serialization flows.
- It shares the same stable field names used by `stringify_async_logger_state(...)`.
- The state must already have been captured before serialization.

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

### Notes

1. Use this API when downstream code wants a JSON value rather than a ready-made string.

2. Pair it with `AsyncLogger::state()` to capture the snapshot first.

