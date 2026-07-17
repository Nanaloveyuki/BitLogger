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

Convert a typed `LoggerConfig` into a `Json`. This helper is the structured export path when config should be persisted, inspected, or embedded into larger JSON payloads.

### Interface

```moonbit
pub fn logger_config_to_json(config : LoggerConfig) -> Json {}
```

#### input

- `config : LoggerConfig` - Typed logger configuration.

#### output

- `Json` - JSON representation of the logger config.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `min_level`, `target`, `timestamp`, `sink`, and optional `queue`.
- Sink export is delegated to `sink_config_to_json(...)`.
- Queue export is delegated to `queue_config_to_json(...)` only when `config.queue` is present; otherwise the `queue` field is omitted entirely.
- `min_level` is serialized using `Level::label()`, so the emitted string follows the same stable config vocabulary accepted by the parser.
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

1. Use this helper when you need a reusable JSON value rather than a final JSON string.

2. Use `stringify_logger_config(...)` when the next consumer expects JSON text instead of `Json`.

