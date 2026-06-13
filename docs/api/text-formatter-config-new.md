---
name: text-formatter-config-new
group: api
category: config
update-time: 20260613
description: Construct a TextFormatterConfig value for config-driven text formatting.
key-word:
    - formatter
    - config
    - constructor
    - public
---

## Text-formatter-config-new

Construct a `TextFormatterConfig` value for config-driven text formatting. This constructor stores text formatting options as serializable data that can later be converted into a runtime `TextFormatter`.

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
) -> TextFormatterConfig {
```

#### input

- `show_timestamp : Bool` - Whether formatted text should include timestamps.
- `show_level : Bool` - Whether formatted text should include the record level.
- `show_target : Bool` - Whether formatted text should include the record target.
- `show_fields : Bool` - Whether formatted text should include structured fields.
- `separator : String` - Separator used between the main rendered parts.
- `field_separator : String` - Separator used between rendered fields.
- `template : String` - Optional text template used by the runtime formatter.
- `color_mode : ColorMode` - Color-emission policy for the runtime formatter.
- `color_support : ColorSupport` - Color capability level used when color is enabled.
- `style_markup : StyleMarkupMode` - Markup handling for the main formatted output.
- `target_style_markup : StyleMarkupMode` - Markup handling for the rendered target field.
- `fields_style_markup : StyleMarkupMode` - Markup handling for rendered field values.
- `style_tags : Map[String, TextStyle]` - Local tag definitions stored as plain config data.

#### output

- `TextFormatterConfig` - Config object that can later be serialized or converted to a runtime formatter.

### Explanation

Detailed rules explaining key parameters and behaviors

- The constructor stores the supplied formatting options directly as config data.
- Default values match the normal config-oriented text formatting defaults, including `color_mode=ColorMode::Never` and markup settings for full main-output markup with disabled target and field markup.
- `style_tags` are stored as concrete `TextStyle` values instead of a runtime registry.
- This constructor is the main typed entry point for formatter config used by `SinkConfig`, `LoggerConfig`, and JSON parse/stringify workflows.

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

In this example, formatter settings are stored as config rather than a runtime-only formatter.

#### When Embed Formatter Config In Sink Config

When a text-rendering policy should be part of a larger sink definition:
```moonbit
let sink = SinkConfig::new(
  kind=SinkKind::TextConsole,
  text_formatter=TextFormatterConfig::new(show_target=false),
)
```

In this example, formatter config becomes one field in a broader sink configuration object.

### Error Case

e.g.:
- If `template` is empty, later runtime formatting falls back to the normal part-assembly path.

- If `style_tags` is empty, no local formatter tag registry is created when converting to a runtime formatter.

### Notes

1. Prefer this constructor when formatter behavior must be stored, parsed, or serialized.

2. Prefer `text_formatter(...)` when writing direct runtime code without config objects.
