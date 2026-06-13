---
name: text-formatter-with-fields-style-markup
group: api
category: formatter
update-time: 20260613
description: Return a TextFormatter with a different field-value style-markup policy.
key-word:
    - formatter
    - fields
    - markup
    - public
---

## Text-formatter-with-fields-style-markup

Return a copy of a `TextFormatter` with a different field-value style-markup policy. This method is the focused way to control whether inline tags inside rendered field values are interpreted while preserving the rest of the formatter configuration.

### Interface

```moonbit
pub fn TextFormatter::with_fields_style_markup(
  self : TextFormatter,
  style_markup : StyleMarkupMode,
) -> TextFormatter {
```

#### input

- `self : TextFormatter` - Base formatter to copy.
- `style_markup : StyleMarkupMode` - New field-value markup policy.

#### output

- `TextFormatter` - A new formatter value carrying the updated field markup setting.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method only changes `fields_style_markup`, which controls field-value rendering.
- The returned formatter preserves timestamp, level, target, message markup, template, color, and registry settings from `self`.
- Message and target markup settings remain unchanged because they have separate scopes.
- The original formatter value is not mutated.

### How to Use

Here are some specific examples provided.

#### When Need Styled Field Values Only

When structured fields should allow markup but the main message should not:
```moonbit
let formatter = text_formatter(color_mode=ColorMode::Always)
  .without_style_markup()
  .with_fields_style_markup(StyleMarkupMode::Full)
```

In this example, field values can use formatter tags even though the message body stays literal.

#### When Need To Downgrade Field Tag Resolution

When a base formatter should keep its overall layout but restrict field markup behavior:
```moonbit
let base = text_formatter(color_mode=ColorMode::Always, fields_style_markup=StyleMarkupMode::Full)
let basic = base.with_fields_style_markup(StyleMarkupMode::Builtin)
```

In this example, field-value rendering moves to built-in-only tag resolution.

### Error Case

e.g.:
- There is no separate failure path for valid `TextFormatter` and `StyleMarkupMode` values.

- If callers expect field keys themselves to become styled, current formatter behavior is still about field values rather than changing every part of structured-field rendering.

### Notes

1. This method only affects field-value markup handling.

2. It is useful when structured metadata should have a different markup policy than message or target text.
