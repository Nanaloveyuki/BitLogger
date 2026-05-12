---
name: logger-config-to-json
group: api
category: config
update-time: 20260512
description: Convert LoggerConfig into a JSON value for export, persistence, or generated config output.
key-word:
    - logger
    - config
    - json
    - public
---

## Logger-config-to-json

Convert a typed `LoggerConfig` into a `JsonValue`. This helper is the structured export path when config should be persisted, inspected, or embedded into larger JSON payloads.

### Interface

```moonbit
pub fn logger_config_to_json(config : LoggerConfig) -> @json_parser.JsonValue {}
```

#### input

- `config : LoggerConfig` - Typed logger configuration.

#### output

- `JsonValue` - JSON representation of the logger config.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `min_level`, `target`, `timestamp`, `sink`, and optional `queue`.
- Sink export is delegated to `sink_config_to_json(...)`.
- The result is suitable for downstream JSON composition as well as stringification.
- Exported JSON follows the stable supported config schema rather than raw internal runtime state.

### How to Use

Here are some specific examples provided.

#### When Need Generated Config Output

When code constructs config and later exports it:
```moonbit
let json = logger_config_to_json(LoggerConfig::new(target="svc"))
```

In this example, the typed config becomes a structured JSON value.

#### When Need To Embed Logger Config In A Larger Payload

When logger config should be one part of a bigger object:
```moonbit
let payload = logger_config_to_json(config)
```

In this example, the helper avoids re-implementing config serialization by hand.

### Error Case

e.g.:
- If `queue` is `None`, the exported JSON simply omits the queue field.

- If some sink options are unused by the chosen sink kind, they still follow the supported config export shape rather than a runtime-only interpretation.

### Notes

1. Use this API when you need a JSON value instead of text output.

2. Use `stringify_logger_config(...)` for immediate string output.

