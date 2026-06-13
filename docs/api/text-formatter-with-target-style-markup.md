---
name: text-formatter-with-target-style-markup
group: api
category: formatter
update-time: 20260613
description: Return a TextFormatter with a different target-text style-markup policy.
key-word:
    - formatter
    - target
    - markup
    - public
---

## Text-formatter-with-target-style-markup

Return a copy of a `TextFormatter` with a different target-text style-markup policy. This method is the focused way to control whether inline tags inside rendered targets are interpreted while preserving the formatter's message and field behavior.

### Interface

```moonbit
pub fn TextFormatter::with_target_style_markup(
  self : TextFormatter,
  style_markup : StyleMarkupMode,
) -> TextFormatter {
```

#### input

- `self : TextFormatter` - Base formatter to copy.
- `style_markup : StyleMarkupMode` - New target-text markup policy.

#### output

- `TextFormatter` - A new formatter value carrying the updated target markup setting.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method only changes `target_style_markup`, which controls rendered target text.
- The returned formatter preserves timestamp, level, message markup, field markup, template, color, and registry settings from `self`.
- Message and field-value markup settings remain unchanged because each scope is configured independently.
- The original formatter value is not mutated.

### How to Use

Here are some specific examples provided.

#### When Need Styled Targets But Literal Messages

When targets may carry semantic tags while messages should remain plain text:
```moonbit
let formatter = text_formatter(color_mode=ColorMode::Always)
  .without_style_markup()
  .with_target_style_markup(StyleMarkupMode::Builtin)
```

In this example, target rendering can parse built-in tags while message text stays literal.

#### When Need To Disable Target Tag Parsing Explicitly

When code should keep every formatter setting except target markup behavior:
```moonbit
let base = text_formatter(color_mode=ColorMode::Always, target_style_markup=StyleMarkupMode::Full)
let safe = base.with_target_style_markup(StyleMarkupMode::Disabled)
```

In this example, only the target markup scope changes.

### Error Case

e.g.:
- There is no separate failure path for valid `TextFormatter` and `StyleMarkupMode` values.

- If callers need message or field-value markup changes too, they must use the dedicated formatter methods for those scopes.

### Notes

1. This method only affects target rendering.

2. It is useful when target namespaces use a different markup policy than the main message body.
