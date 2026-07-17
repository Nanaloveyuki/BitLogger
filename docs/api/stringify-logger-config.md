---
name: stringify-logger-config
group: api
category: config
update-time: 20260512
description: Serialize LoggerConfig into compact or pretty JSON text for persistence and diagnostics.
key-word:
    - logger
    - config
    - stringify
    - public
---

## Stringify-logger-config

Serialize `LoggerConfig` into JSON text. This is the easiest way to emit typed logger configuration as a string for persistence, examples, diagnostics, or generated config files.

### Interface

```moonbit
pub fn stringify_logger_config(config : LoggerConfig, pretty~ : Bool = false) -> String {}
```

#### input

- `config : LoggerConfig` - Config to serialize.
- `pretty : Bool` - Whether JSON output should be pretty-printed.

#### output

- `String` - Serialized logger config JSON.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` produces compact JSON.
- `pretty=true` produces indented human-readable JSON.
- This helper builds on top of `logger_config_to_json(...)`.
- Internally it serializes the `Json` result with `value.stringify(...)` or `value.stringify(indent=2)`, so the text form stays aligned with the structured logger-config export helper.
- Output is stable and suited for roundtrip config workflows.

### How to Use

Here are some specific examples provided.

#### When Need A Human-readable Generated Config

When config should be printed or checked by humans:
```moonbit
println(stringify_logger_config(config, pretty=true))
```

In this example, the output is readable enough for documentation or operator inspection.

#### When Need Compact Export

When config should be emitted as a compact payload:
```moonbit
println(stringify_logger_config(config))
```

In this example, the config stays small and machine-oriented.

### Error Case

e.g.:
- If callers need a JSON value rather than text, use `logger_config_to_json(...)` instead.

- If config contains optional `queue=None`, the output omits that section rather than failing.

### Notes

1. Use this helper when the next consumer expects JSON text instead of `Json`.

2. Use `logger_config_to_json(...)` when you still need to embed the config inside a larger JSON object before final stringification.

