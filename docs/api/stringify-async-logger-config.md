---
name: stringify-async-logger-config
group: api
category: async
update-time: 20260512
description: Serialize AsyncLoggerConfig into compact or pretty JSON text for export and diagnostics.
key-word:
    - async
    - config
    - stringify
    - public
---

## Stringify-async-logger-config

Serialize `AsyncLoggerConfig` into JSON text. This helper is the most direct output path when async runtime policy should be logged, printed, or copied as config text.

### Interface

```moonbit
pub fn stringify_async_logger_config(config : AsyncLoggerConfig, pretty~ : Bool = false) -> String {}
```

#### input

- `config : AsyncLoggerConfig` - Async config to serialize.
- `pretty : Bool` - Whether JSON should be pretty-printed.

#### output

- `String` - Serialized JSON text for the async config.

---

e.g.:
```moonbit
pub fn stringify_async_logger_config(config : AsyncLoggerConfig, pretty~ : Bool = false) -> String {}
```

#### input

- `config : AsyncLoggerConfig` - Config to stringify.
- `pretty : Bool` - Pretty-print flag.

#### output

- `String` - JSON text.

---

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` returns compact JSON suitable for transport and snapshots.
- `pretty=true` returns indented JSON for humans.
- This helper is built on top of `async_logger_config_to_json(...)`.
- The exported text follows the supported async config schema rather than internal queue implementation details.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable Async Config

When async policy should be printed during startup or testing:
```moonbit
println(stringify_async_logger_config(AsyncLoggerConfig::new(max_pending=32), pretty=true))
```

In this example, the config is emitted in readable JSON.

#### When Need Compact Generated Config Text

When async settings should stay small:
```moonbit
let text = stringify_async_logger_config(
  AsyncLoggerConfig::new(flush=AsyncFlushPolicy::Shutdown),
)
```

In this example, compact JSON is returned without extra formatting.

### Error Case

e.g.:
- If callers need a `JsonValue` for composition, they should use `async_logger_config_to_json(...)` instead.

- If invalid constructor inputs were normalized earlier, the resulting text contains the normalized config values.

### Notes

Notes are here.

1. This API is convenient for config snapshots, examples, and tests.

2. Use `pretty=true` when readability matters.

3. Compact mode is a better default for machine-oriented output.

4. This helper exports async config data, not runtime logger state.
