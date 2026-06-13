---
name: sink-config-type
group: api
category: config
update-time: 20260613
description: Public sink config alias used for serializable built-in sink selection and settings.
key-word:
    - sink
    - config
    - alias
    - public
---

## Sink-config-type

`SinkConfig` is the public serializable config type used to describe the built-in sink shape and its related settings. It is a direct alias to the sink config model used by config parsing, logger building, and sink config serializers.

### Interface

```moonbit
pub type SinkConfig = @utils.SinkConfig
```

#### output

- `SinkConfig` - Public sink config object containing `kind`, `path`, `append`, `auto_flush`, `rotation`, and `text_formatter`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a runtime sink instance.
- The current fields are `kind : SinkKind`, `path : String`, `append : Bool`, `auto_flush : Bool`, `rotation : FileRotation?`, and `text_formatter : TextFormatterConfig`.
- `SinkConfig::new(...)` constructs this type as the main code-side entry point.
- `sink_config_to_json(...)`, `stringify_sink_config(...)`, and `build_logger(...)` all consume the same public config shape.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Built-in Sink Description

When sink selection and file/text settings should remain config data before logger construction:
```moonbit
let sink : SinkConfig = SinkConfig::new(kind=SinkKind::TextConsole)
```

In this example, the sink choice stays as a typed config object instead of becoming a runtime sink immediately.

#### When Need To Inspect Or Export Sink Settings

When a sink definition should be serialized or reviewed before build time:
```moonbit
let sink = SinkConfig::new(kind=SinkKind::File, path="app.log")
println(stringify_sink_config(sink, pretty=true))
```

In this example, the same public config type supports both inspection and later runtime assembly.

### Error Case

e.g.:
- `SinkConfig` itself does not have a runtime failure mode.

- File-oriented fields can still be present on a non-file sink config, but those values may remain unused by the runtime builder.

### Notes

1. Use `SinkConfig::new(...)` when you need a value of this type in code.

2. Use concrete sink constructors when you need a runtime sink directly instead of serializable config data.
