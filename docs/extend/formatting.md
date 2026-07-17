# Text Formatting And Style Tags

Formatting changes presentation while keeping the record's level, target, message, and fields intact. Use text output for people; use JSON output when another system parses the record.

## Customize The Text Shape

```moonbit
let logger = @log.build_logger(
  @log.text_console(
    min_level=@log.Level::Info,
    target="service",
    text_formatter=@log.TextFormatterConfig::new(
      show_timestamp=false,
      field_separator=",",
      template="[{level}] {target} {message} :: {fields}",
    ),
  ),
)

logger.info("ready", fields=[@log.field("port", "8080")])
```

The template controls the visible order. Keep fields separate from the message so they can still be rendered consistently across sinks.

## Add Named Styles

```moonbit
let formatter = @log.text_formatter(
  show_timestamp=false,
  color_mode=@log.ColorMode::Always,
).with_style_tags(
  @log.default_style_tag_registry()
  .set_tag("accent", fg=Some("#4cc9f0"), bold=true),
)
```

Style tags are terminal presentation metadata. Do not use them as the only way to encode operational meaning; preserve that meaning in level, target, and fields.

## API Reference

- [`text_console(...)`](../api/text-console.md)
- [`TextFormatterConfig`](../api/text-formatter-config.md)
- [`text_formatter(...)`](../api/text-formatter.md)
- [`ColorMode`](../api/color-mode.md)
