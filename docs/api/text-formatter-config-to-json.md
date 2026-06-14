---
name: text-formatter-config-to-json
group: api
category: config
update-time: 20260512
description: Convert TextFormatterConfig into a JSON value for formatter export, persistence, or generated config output.
key-word:
    - formatter
    - config
    - json
    - public
---

## Text-formatter-config-to-json

Convert a typed `TextFormatterConfig` into a `JsonValue`. This helper exports formatter toggles, separators, color settings, markup behavior, and optional style tags in a machine-readable form.

### Interface

```moonbit
pub fn text_formatter_config_to_json(config : TextFormatterConfig) -> @json_parser.JsonValue {}
```

#### input

- `config : TextFormatterConfig` - Formatter configuration to export.

#### output

- `JsonValue` - Structured JSON representation of the formatter config.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes visibility flags, separators, template, color settings, and markup settings.
- `style_tags` is exported only when the map is not empty.
- Enum-like formatter options are serialized using their stable label strings.
- `color_mode`, `color_support`, and the markup-mode fields are emitted through their label helpers, so the exported strings stay aligned with the parser-facing formatter config vocabulary.
- Nested `style_tags` entries are exported as plain JSON objects keyed by tag name, with each `TextStyle` rendered as structured config data rather than runtime registry state.
- The JSON shape matches the formatter section accepted by config parsing.

### How to Use

Here are some specific examples provided.

#### When Need Structured Formatter Export

When formatter config should be embedded inside a larger config object:
```moonbit
let value = text_formatter_config_to_json(TextFormatterConfig::new(show_target=false))
```

In this example, callers can compose the JSON value without re-implementing serialization.

#### When Need To Persist Formatter Settings

When generated formatter policy should be stored or inspected:
```moonbit
let formatter_json = text_formatter_config_to_json(
  TextFormatterConfig::new(separator=" | ", template="[{level}] {message}"),
)
```

In this example, the config becomes transport-friendly structured data.

### Error Case

e.g.:
- If `style_tags` is empty, the field is omitted instead of being emitted as an empty object.

- If callers need immediate text output rather than a JSON value, they should use `stringify_text_formatter_config(...)` instead.

### Notes

1. Use this helper when you need a reusable JSON value rather than a final JSON string.

2. `sink_config_to_json(...)` reuses this helper for the nested `text_formatter` field.

