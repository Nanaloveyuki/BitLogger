---
name: default-sink-config
group: api
category: config
update-time: 20260520
description: Create the default SinkConfig used by logger config helpers.
key-word:
    - sink
    - config
    - default
    - public
---

## Default-sink-config

Create the default `SinkConfig` used by logger config helpers. This helper is useful when callers want the library's baseline sink config value explicitly.

### Interface

```moonbit
pub fn default_sink_config() -> SinkConfig {
```

#### output

- `SinkConfig` - Default sink config value.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper returns the same baseline sink config used by `LoggerConfig::new(...)` defaults.
- The default sink config is console-oriented unless later replaced by explicit config composition.
- The implementation is exactly `SinkConfig::new()`, so the returned value uses the standard constructor defaults: `kind=Console`, empty `path`, `append=true`, `auto_flush=true`, no rotation, and the default text formatter config.
- `parse_logger_config_text(...)` also falls back to this same helper when the `sink` object is omitted from JSON input.
- It is a typed config object, not a runtime sink instance.

### How to Use

Here are some specific examples provided.

#### When Need An Explicit Baseline Sink Config

When config assembly wants the default sink as a concrete value:
```moonbit
let sink = default_sink_config()
```

In this example, the baseline sink config can be reused or embedded explicitly.

### Error Case

e.g.:
- There is no failure path for retrieving the default sink config.

- If a real sink instance is required for direct `Logger::new(...)` code paths, use a sink constructor such as `console_sink()` instead.

### Notes

1. This helper is for config-driven assembly, not runtime sink wiring.

2. It is most useful in explicit config composition code.

3. Use `default_logger_config()` when callers want the full top-level config default instead of only the sink portion.
