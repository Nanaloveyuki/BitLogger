---
name: json-console-sink-type
group: api
category: sink
update-time: 20260613
description: Public JSON console sink type used for machine-readable synchronous stdout output.
key-word:
    - sink
    - json
    - type
    - public
---

## Json-console-sink-type

`JsonConsoleSink` is the public console sink type used for machine-readable JSON stdout output. It is the concrete sink type returned by `json_console_sink()` and is intended for structured log pipelines rather than human-focused text formatting.

### Interface

```moonbit
pub struct JsonConsoleSink {
  _dummy : Unit
}
```

#### output

- `JsonConsoleSink` - Public synchronous sink type that writes records to the console as JSON.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current visible field is `_dummy : Unit`, which exists only to carry the concrete sink type.
- `json_console_sink()` constructs this type as the built-in structured console output path.
- `Logger[JsonConsoleSink]` keeps the concrete machine-readable console sink type visible when typed composition matters.

### How to Use

Here are some specific examples provided.

#### When Need A Typed JSON Console Sink Value

When code should keep the concrete structured console sink type visible:
```moonbit
let sink : JsonConsoleSink = json_console_sink()
```

In this example, the sink value stays explicit and can be passed into typed logger construction.

#### When Need A Typed Structured Stdout Logger

When logging should preserve the JSON console sink type in the logger:
```moonbit
let logger : Logger[JsonConsoleSink] = Logger::new(json_console_sink(), target="api")
```

In this example, the concrete structured stdout sink remains part of the logger type.

### Error Case

e.g.:
- `JsonConsoleSink` itself does not have a runtime failure mode.

- Console output still depends on the current runtime environment even though the sink type is always constructible.

### Notes

1. Use `json_console_sink()` when you need a value of this type.

2. Use `ConsoleSink` or `FormattedConsoleSink` when output should be plain text or custom-formatted text instead of JSON.
