---
name: default-text-formatter-config
group: api
category: config
update-time: 20260520
description: Create the default TextFormatterConfig used by config and preset helpers.
key-word:
    - formatter
    - config
    - default
    - public
---

## Default-text-formatter-config

Create the default `TextFormatterConfig` used by config builders and presets. This helper is useful when callers want the library default config value explicitly rather than relying on optional parameter defaults.

### Interface

```moonbit
pub fn default_text_formatter_config() -> TextFormatterConfig {
```

#### output

- `TextFormatterConfig` - Default serializable formatter config value.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper returns the same baseline config value used by `text_console(...)`, `file(...)`, and `SinkConfig::new(...)` defaults.
- The implementation is exactly `TextFormatterConfig::new()`, so it stays aligned with the constructor defaults rather than duplicating a separate preset object.
- It is a config object, not a runtime `TextFormatter`.
- Call `to_formatter()` when a runtime formatter is needed.

### How to Use

Here are some specific examples provided.

#### When Need To Start From The Default Formatter Config Explicitly

When config code wants the baseline value before adjusting fields:
```moonbit
let base = default_text_formatter_config()
```

In this example, the default formatter config is available as a concrete value instead of an implicit optional argument default.

### Error Case

e.g.:
- There is no failure path for retrieving the default config value.

- If a runtime formatter is required immediately, this helper alone is not enough because it returns config rather than a formatter object.

### Notes

1. Use this helper for explicit config composition.

2. Use `text_formatter(...)` when you want a runtime formatter directly.

3. `parse_logger_config_text(...)` also falls back to this same baseline when a sink omits its nested `text_formatter` object.
