---
name: async-logger-config-to-json
group: api
category: async
update-time: 20260512
description: Convert AsyncLoggerConfig into a JSON value for export, persistence, or generated async config output.
key-word:
    - async
    - config
    - json
    - public
---

## Async-logger-config-to-json

Convert a typed `AsyncLoggerConfig` into a `JsonValue`. This helper exports async queue capacity, overflow policy, batch sizing, linger timing, and flush behavior in a structured form.

### Interface

```moonbit
pub fn async_logger_config_to_json(config : AsyncLoggerConfig) -> @json_parser.JsonValue {}
```

#### input

- `config : AsyncLoggerConfig` - Async logger runtime config to export.

#### output

- `JsonValue` - Structured JSON representation of the async config.

---

e.g.:
```moonbit
pub fn async_logger_config_to_json(config : AsyncLoggerConfig) -> @json_parser.JsonValue {}
```

#### input

- `config : AsyncLoggerConfig` - Typed async config.

#### output

- `JsonValue` - JSON-exportable async configuration.

---

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `max_pending`, `max_batch`, `linger_ms`, `overflow`, and `flush`.
- Policy fields are serialized using the stable labels accepted by the config parser.
- This helper exports effective typed config after constructor normalization has already happened.
- The JSON shape matches the `async_config` section used by async build config parsing.

### How to Use

Here are some specific examples provided.

#### When Need Structured Async Config Export

When async runtime policy should be embedded in a larger JSON payload:
```moonbit
let async_json = async_logger_config_to_json(
  AsyncLoggerConfig::new(max_pending=128, max_batch=8),
)
```

In this example, callers receive a machine-readable config value.

#### When Need Roundtrip-friendly Async Settings

When code generates async policy and later persists it:
```moonbit
let value = async_logger_config_to_json(AsyncLoggerConfig::new(flush=AsyncFlushPolicy::Batch))
```

In this example, the exported JSON stays aligned with parser expectations.

### Error Case

e.g.:
- If `max_batch` or `linger_ms` were normalized during construction, the exported JSON reflects the normalized values rather than the original invalid inputs.

- If callers want direct text output instead of a JSON value, they should use `stringify_async_logger_config(...)` instead.

### Notes

Notes are here.

1. This helper exports config data, not runtime counters or failure state.

2. Use it when downstream code expects `JsonValue`.

3. Pair it with `AsyncLoggerConfig::new(...)` for code-generated config.

4. The output is suitable for persistence, tests, and generated async setup flows.
