---
name: sink-config-to-json
group: api
category: config
update-time: 20260512
description: Convert SinkConfig into a JSON value for export and nested logger config serialization.
key-word:
    - sink
    - config
    - json
    - public
---

## Sink-config-to-json

Convert `SinkConfig` into a `JsonValue`. This helper is used directly for sink export and indirectly when exporting `LoggerConfig`.

### Interface

```moonbit
pub fn sink_config_to_json(config : SinkConfig) -> @json_parser.JsonValue {}
```

#### input

- `config : SinkConfig` - Sink config to export.

#### output

- `JsonValue` - JSON representation of the sink configuration.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `kind`, `path`, `append`, `auto_flush`, and `text_formatter`.
- `rotation` is only included when present.
- `kind` is serialized using the stable parser-facing sink labels such as `console`, `json_console`, `text_console`, and `file`.
- `text_formatter` export is delegated to `text_formatter_config_to_json(...)`, so nested formatter settings follow the same config schema used elsewhere.
- The exported shape is schema-oriented and shared by larger config export helpers.
- This helper is especially useful when building larger config payloads manually.

### How to Use

Here are some specific examples provided.

#### When Need Sink-only Export

When only the sink portion should be emitted:
```moonbit
let json = sink_config_to_json(SinkConfig::new(kind=SinkKind::TextConsole))
```

In this example, sink config can be exported independently of the full logger config.

#### When Compose A Larger JSON Payload

When sink config should be embedded elsewhere:
```moonbit
let sink_json = sink_config_to_json(config.sink)
```

In this example, sink config becomes a structured JSON component.

### Error Case

e.g.:
- If `rotation` is absent, it is simply omitted from the exported sink config.

- If file-related fields are unused by the sink kind, they are still exported according to the stable config shape.

### Notes

1. Use this helper when you need a reusable JSON value rather than a final JSON string.

2. `logger_config_to_json(...)` reuses this helper for the nested `sink` field.

