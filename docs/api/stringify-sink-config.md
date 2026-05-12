---
name: stringify-sink-config
group: api
category: config
update-time: 20260512
description: Serialize SinkConfig into compact or pretty JSON text.
key-word:
    - sink
    - config
    - stringify
    - public
---

## Stringify-sink-config

Serialize `SinkConfig` into JSON text. This helper is the direct text output path for sink configuration when examples, tooling, or diagnostics want the sink section by itself.

### Interface

```moonbit
pub fn stringify_sink_config(config : SinkConfig, pretty~ : Bool = false) -> String {}
```

#### input

- `config : SinkConfig` - Sink config to serialize.
- `pretty : Bool` - Whether output should be pretty-printed.

#### output

- `String` - Serialized sink config JSON.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` gives compact JSON.
- `pretty=true` gives indented output.
- This helper builds on top of `sink_config_to_json(...)`.
- It is useful when examples or generated docs want to show only sink-specific config.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable Sink Config

When sink config should be printed for review:
```moonbit
println(stringify_sink_config(SinkConfig::new(kind=SinkKind::File, path="app.log"), pretty=true))
```

In this example, the sink section is easy to inspect visually.

#### When Need Compact Embedded Output

When sink config should be emitted in a compact form:
```moonbit
println(stringify_sink_config(config.sink))
```

In this example, the helper provides a ready-made machine-oriented representation.

### Error Case

e.g.:
- If callers need a JSON value instead of text, use `sink_config_to_json(...)` instead.

- If optional `rotation` is absent, the serialized sink config simply omits that field.

### Notes

Notes are here.

1. This helper is convenient for documentation, examples, and generated config output.

2. Use `pretty=true` when humans are the primary audience.

3. The output describes the config schema, not live runtime sink state.

4. This API pairs naturally with `SinkConfig::new(...)` and `sink_config_to_json(...)`.
