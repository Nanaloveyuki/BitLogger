---
name: text-formatter-config-to-formatter
group: api
category: config
update-time: 20260613
description: Convert a TextFormatterConfig into a runtime TextFormatter value.
key-word:
    - formatter
    - config
    - runtime
    - public
---

## Text-formatter-config-to-formatter

Convert a `TextFormatterConfig` into a runtime `TextFormatter` value. This helper is the main config-to-runtime bridge used by sync and async logger builder paths when serializable formatter settings should become a concrete formatter object.

### Interface

```moonbit
pub fn TextFormatterConfig::to_formatter(self : TextFormatterConfig) -> TextFormatter {
```

#### input

- `self : TextFormatterConfig` - Serializable formatter config to convert into a runtime formatter.

#### output

- `TextFormatter` - Runtime formatter built from the config fields.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper forwards the stored visibility flags, separators, template, color settings, and markup settings into `text_formatter(...)`.
- When `style_tags` is empty, the runtime formatter is built without a local style-tag registry.
- When `style_tags` is non-empty, the config map is converted into a fresh `StyleTagRegistry` and each stored tag is registered on that new registry before formatter construction.
- This conversion does not mutate the source config object.
- Sync and async config-driven builder paths both rely on this helper when a text formatter config must become a concrete runtime formatter.

### How to Use

Here are some specific examples provided.

#### When Need A Runtime Formatter From Parsed Config

When serializable formatter settings should become a real formatter for a sink or direct rendering:
```moonbit
let config = TextFormatterConfig::new(show_timestamp=false, template="[{level}] {message}")
let formatter = config.to_formatter()
```

In this example, config data is converted into the runtime formatter object only when it is actually needed.

#### When Need Builder-path Formatter Conversion

When config-driven logger assembly should produce a text-console formatter:
```moonbit
let formatter = config.sink.text_formatter.to_formatter()
```

In this example, the same helper used by runtime builder code is called directly from user code.

### Error Case

e.g.:
- This conversion itself does not have a normal failure mode; it only rehydrates config fields into a runtime formatter.

- If callers want serializable config data rather than a runtime formatter, keep using `TextFormatterConfig` or its JSON helpers instead.

### Notes

1. Use this helper when serializable formatter config should become a concrete `TextFormatter`.

2. Pair it with `text_formatter_config_to_json(...)` or `stringify_text_formatter_config(...)` when the same formatter policy must also be exported or persisted.
