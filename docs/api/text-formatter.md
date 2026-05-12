---
name: text-formatter
group: api
category: formatter
update-time: 20260512
description: Create a configurable text formatter for console, callback, and file-oriented text logging output.
key-word:
    - formatter
    - text
    - color
    - public
---

## Text-formatter

Create a `TextFormatter` that controls timestamp, level, target, field rendering, template substitution, color behavior, and style markup behavior. This is the main API for readable text output in `BitLogger`.

### Interface

```moonbit
pub fn text_formatter(
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
  style_tags~ : StyleTagRegistry? = None,
) -> TextFormatter {}
```

#### input

- `show_timestamp : Bool` - Whether timestamp text is rendered when the record carries a timestamp.
- `show_level : Bool` - Whether the level label is rendered.
- `show_target : Bool` - Whether the target is rendered.
- `show_fields : Bool` - Whether structured fields are rendered.
- `separator : String` - Separator between major rendered parts.
- `field_separator : String` - Separator used between field values in text output.
- `template : String` - Optional template using tokens such as `{level}`, `{target}`, `{message}`, `{timestamp}`, `{timestamp_ms}`, and `{fields}`.
- `color_mode : ColorMode` - `Never`, `Auto`, or `Always`.
- `color_support : ColorSupport` - `Basic` or `TrueColor`.
- `style_markup : StyleMarkupMode` - Controls whether message style tags are parsed.
- `target_style_markup : StyleMarkupMode` - Controls whether target style tags are parsed.
- `fields_style_markup : StyleMarkupMode` - Controls whether field-value style tags are parsed.
- `style_tags : StyleTagRegistry?` - Optional local tag registry.

#### output

- `TextFormatter` - A reusable text formatter instance for text sinks or direct formatting.

### Explanation

Detailed rules explaining key parameters and behaviors

- If `template` is empty, the formatter uses built-in part assembly.
- `color_mode=Auto` currently follows a conservative rule based on `NO_COLOR`.
- `style_markup`, `target_style_markup`, and `fields_style_markup` are independent scopes.
- Local `style_tags` override global tag registry lookup, which overrides builtin tags.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable Console Output

When logs should stay readable in terminals:
```moonbit
let formatter = text_formatter(
  show_timestamp=false,
  template="[{level}] {target} {message} :: {fields}",
)
let logger = Logger::new(text_console_sink(formatter), target="demo")
```

In this example, the formatter produces predictable text output without timestamps.

And the same formatter can be reused by multiple sinks.

#### When Need Styled ANSI Output

When you want visible severity or semantic tags in terminal output:
```moonbit
let formatter = text_formatter(color_mode=ColorMode::Always)
  .with_style_tags(default_style_tag_registry().set_tag("accent", fg=Some("#4cc9f0"), bold=true))
```

In this example, message text can use inline tags such as `<accent>...</>`.

### Error Case

e.g.:
- If `template` contains unknown text, the formatter keeps it as plain text.

- If a style tag is unknown or invalid, current behavior falls back to plain text rather than raising an error.

### Notes

1. Prefer `text_formatter(...)` when you want explicit control over readable text output.

2. `TextFormatter` is reusable and should usually be constructed once, then shared.

