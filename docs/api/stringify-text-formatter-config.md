---
name: stringify-text-formatter-config
group: api
category: config
update-time: 20260512
description: Serialize TextFormatterConfig into compact or pretty JSON text for export and diagnostics.
key-word:
    - formatter
    - config
    - stringify
    - public
---

## Stringify-text-formatter-config

Serialize `TextFormatterConfig` into JSON text. This helper is the highest-level export path when formatter config should be printed, logged, or copied as config text.

### Interface

```moonbit
pub fn stringify_text_formatter_config(
  config : TextFormatterConfig,
  pretty~ : Bool = false,
) -> String {}
```

#### input

- `config : TextFormatterConfig` - Formatter config to serialize.
- `pretty : Bool` - Whether JSON should be pretty-printed.

#### output

- `String` - Serialized JSON text for the formatter config.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` returns compact JSON.
- `pretty=true` returns indented JSON for humans.
- This helper is built on top of `text_formatter_config_to_json(...)`.
- The output preserves the supported formatter config schema instead of any runtime-only formatter instance details.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable Formatter Config

When formatter settings should be inspected during setup:
```moonbit
println(stringify_text_formatter_config(default_text_formatter_config(), pretty=true))
```

In this example, the pretty output is suitable for diagnostics or docs.

#### When Need Compact Export Text

When generated config should stay small:
```moonbit
let text = stringify_text_formatter_config(
  TextFormatterConfig::new(show_fields=false),
)
```

In this example, compact JSON is returned for storage or transport.

### Error Case

e.g.:
- If callers need a JSON value for composition, they should use `text_formatter_config_to_json(...)` instead.

- If `style_tags` is empty, the serialized text omits that field rather than forcing an empty object.

### Notes

1. This helper is useful for config snapshots, examples, and tests.

2. Use `pretty=true` when readability matters.

