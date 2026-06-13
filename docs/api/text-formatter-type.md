---
name: text-formatter-type
group: api
category: formatter
update-time: 20260613
description: Public text-formatter alias used for structured text rendering configuration and reuse.
key-word:
    - formatter
    - text
    - alias
    - public
---

## Text-formatter-type

`TextFormatter` is the public reusable formatter type used for readable text log rendering. It is a direct alias to the formatter model used by text sinks, formatter customization helpers, and direct `format_text(...)` calls.

### Interface

```moonbit
pub type TextFormatter = @utils.TextFormatter
```

#### output

- `TextFormatter` - Public text-rendering value containing timestamp, level, target, field, template, color, markup, and style-tag settings.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a sink or logger by itself.
- The current fields are `show_timestamp`, `show_level`, `show_target`, `show_fields`, `separator`, `field_separator`, `template`, `color_mode`, `color_support`, `style_markup`, `target_style_markup`, `fields_style_markup`, and `style_tags`.
- `text_formatter(...)` constructs this type as the main runtime entry point.
- The same value type is consumed by `format_text(...)`, `text_console_sink(...)`, and config-to-runtime bridges such as `TextFormatterConfig::to_formatter()`.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Reusable Formatter Value

When one formatter should be created once and shared across multiple sinks or formatting calls:
```moonbit
let formatter : TextFormatter = text_formatter(show_timestamp=false, template="[{level}] {message}")
```

In this example, the formatter remains a reusable typed value instead of being tied to one output path.

#### When Need Direct Formatting Without Building A Logger

When code should format a record through a previously prepared formatter:
```moonbit
let formatter = text_formatter(color_mode=ColorMode::Always)
println(format_text(Record::new(Level::Info, "started"), formatter=formatter))
```

In this example, the formatter type is used directly as a rendering dependency.

### Error Case

e.g.:
- `TextFormatter` itself does not have a runtime failure mode.

- Unknown style tags or unsupported visible styling fall back to plain text behavior instead of raising formatter-construction errors.

### Notes

1. Use `text_formatter(...)` when you need a value of this type in code.

2. Use `TextFormatterConfig` when the same rendering policy should be stored or transported as config data first.
