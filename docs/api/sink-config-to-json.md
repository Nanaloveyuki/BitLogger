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

Notes are here.

1. This API is sink-config export only, not runtime sink inspection.

2. Use `stringify_sink_config(...)` for direct string output.

3. This helper is reused by `logger_config_to_json(...)`.

4. It is useful for tooling that needs nested config JSON values.
