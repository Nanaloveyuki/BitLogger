---
name: default-logger-config
group: api
category: config
update-time: 20260520
description: Create the default LoggerConfig used by config-driven logger builders.
key-word:
    - logger
    - config
    - default
    - public
---

## Default-logger-config

Create the default `LoggerConfig` used by config-driven logger builders. This helper is useful when callers want the library's baseline top-level config value explicitly before customization.

### Interface

```moonbit
pub fn default_logger_config() -> LoggerConfig {
```

#### output

- `LoggerConfig` - Default top-level logger config.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper returns the same baseline config shape used by `LoggerConfig::new()` defaults.
- It includes the default minimum level, empty target, disabled timestamp, default sink config, and no queue wrapper.
- The implementation is exactly `LoggerConfig::new()`, so it stays aligned with the constructor defaults rather than duplicating a separate preset object.
- That means `build_logger(...)` can consume the returned value directly, and `build_async_logger(...)` reuses the same sync-side defaults before adding the outer async layer.
- It is useful for explicit config composition when callers want a known baseline object.

### How to Use

Here are some specific examples provided.

#### When Need A Baseline Top-level Config Value

When config code prefers to start from the full default object:
```moonbit
let config = default_logger_config()
```

In this example, the default logger config is available as a concrete value for later adjustment or serialization.

### Error Case

e.g.:
- There is no failure path for retrieving the default config value.

- If runtime construction is needed immediately, pass the config to `build_logger(...)` or use a runtime logger constructor directly.

### Notes

1. This helper is the top-level default config entry point.

2. It is useful for explicit config-first workflows and tests.

3. Use `default_sink_config()` when callers only want the baseline sink portion rather than the full top-level logger config.
