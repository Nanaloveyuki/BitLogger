---
name: text-formatter-config-type
group: api
category: config
update-time: 20260613
description: Public text formatter config alias used for serializable formatter settings.
key-word:
    - formatter
    - config
    - alias
    - public
---

## Text-formatter-config-type

`TextFormatterConfig` is the public serializable config type used to describe text rendering behavior. It is a direct alias to the formatter config model used by config parsing, config serialization, and runtime formatter conversion.

### Interface

```moonbit
pub type TextFormatterConfig = @utils.TextFormatterConfig
```

#### output

- `TextFormatterConfig` - Public formatter config object containing timestamp, level, target, field, template, color, markup, and style-tag settings.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a runtime `TextFormatter` instance.
- The current fields are `show_timestamp`, `show_level`, `show_target`, `show_fields`, `separator`, `field_separator`, `template`, `color_mode`, `color_support`, `style_markup`, `target_style_markup`, `fields_style_markup`, and `style_tags`.
- `TextFormatterConfig::new(...)` constructs this type as the main code-side entry point.
- `text_formatter_config_to_json(...)`, `stringify_text_formatter_config(...)`, and `TextFormatterConfig::to_formatter()` all consume the same public config shape.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Serializable Formatter Policy

When formatter settings should remain structured config data before becoming a runtime formatter:
```moonbit
let config : TextFormatterConfig = TextFormatterConfig::new(show_timestamp=false)
```

In this example, the formatter policy stays as a typed config object instead of a runtime formatter value.

#### When Need To Inspect Or Export Formatter Config Before Runtime Use

When configuration should be reviewed or serialized before a logger is built:
```moonbit
let config = TextFormatterConfig::new(template="[{level}] {message}")
println(stringify_text_formatter_config(config, pretty=true))
```

In this example, the same public config type supports both inspection and later conversion.

### Error Case

e.g.:
- `TextFormatterConfig` itself does not have a runtime failure mode.

- If `style_tags` is empty, later `to_formatter()` conversion simply creates no local tag registry.

### Notes

1. Use `TextFormatterConfig::new(...)` when you need a value of this type in code.

2. Use `TextFormatter` when you need the runtime rendering object directly instead of serializable config data.
