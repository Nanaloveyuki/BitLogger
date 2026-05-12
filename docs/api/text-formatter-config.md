---
name: text-formatter-config
group: api
category: config
update-time: 20260512
description: Build a serializable formatter config object that bridges JSON config and runtime text formatting.
key-word:
    - formatter
    - config
    - json
    - public
---

## Text-formatter-config

Create a `TextFormatterConfig` object for config-driven text rendering. This is the serializable counterpart to `text_formatter(...)` and is the main bridge between JSON config parsing and runtime formatter construction.

### Interface

```moonbit
pub fn TextFormatterConfig::new(
  show_timestamp~ : Bool = true,
  show_level~ : Bool = true,
  show_target~ : Bool = true,
  show_fields~ : Bool = true,
  separator~ : String = " ",
  field_separator~ : String = " ",
  template~ : String = "",
  color_mode~ : ColorMode = ColorMode::Never,
  color_support~ : ColorSupport = ColorSupport::TrueColor,
  style_markup~ : StyleMarkupMode = StyleMarkupMode::Full,
  target_style_markup~ : StyleMarkupMode = StyleMarkupMode::Disabled,
  fields_style_markup~ : StyleMarkupMode = StyleMarkupMode::Disabled,
  style_tags~ : Map[String, TextStyle] = {},
) -> TextFormatterConfig {}
```

#### input

- Parameters mirror `text_formatter(...)` but are stored in a serializable config object.
- `style_tags : Map[String, TextStyle]` - Local tag definitions stored as plain config data.

#### output

- `TextFormatterConfig` - Config object that can later be serialized or converted to a runtime formatter.

### Explanation

Detailed rules explaining key parameters and behaviors

- This type is data-oriented and suitable for JSON parse/stringify workflows.
- `to_formatter()` converts config into a runtime `TextFormatter`.
- `style_tags` are stored as concrete style objects instead of alias-style runtime behavior.
- This config type is used by `SinkConfig`, `LoggerConfig`, and config-driven sink assembly.

### How to Use

Here are some specific examples provided.

#### When Need Config-built Text Output

When text formatting should be configured rather than hard-coded:
```moonbit
let formatter = TextFormatterConfig::new(
  show_timestamp=false,
  template="[{level}] {message}",
  color_mode=ColorMode::Always,
)
```

In this example, the formatter settings are stored as config rather than a runtime-only formatter.

And the same value can be serialized or embedded in larger logger config objects.

#### When Need Runtime Bridge After Parsing

When config has already been parsed from JSON:
```moonbit
let runtime_formatter = config.sink.text_formatter.to_formatter()
```

In this example, JSON-driven settings become a real runtime formatter only when needed.

### Error Case

e.g.:
- If `template` is empty, runtime formatting falls back to the normal part-assembly path.

- If `style_tags` is empty, no local formatter tag registry is created.

### Notes

Notes are here.

1. Prefer this API when formatter behavior must be stored, parsed, or serialized.

2. Prefer `text_formatter(...)` when writing direct runtime code without config.

3. `to_formatter()` is the key bridge from config to runtime behavior.

4. This type is central to config-driven text sink assembly.
