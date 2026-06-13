---
name: text-formatter-without-style-markup
group: api
category: formatter
update-time: 20260613
description: Return a TextFormatter with message style markup disabled.
key-word:
    - formatter
    - style
    - disable
    - public
---

## Text-formatter-without-style-markup

Return a copy of a `TextFormatter` with message style markup disabled. This is the convenience helper for the common case where message text should stay literal even if it contains tag-like syntax.

### Interface

```moonbit
pub fn TextFormatter::without_style_markup(self : TextFormatter) -> TextFormatter {
```

#### input

- `self : TextFormatter` - Base formatter to copy.

#### output

- `TextFormatter` - A new formatter value whose message markup policy is `StyleMarkupMode::Disabled`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method is a convenience wrapper over `with_style_markup(StyleMarkupMode::Disabled)`.
- Only the message-text markup scope changes.
- Target and field-value markup settings are preserved as-is.
- The original formatter value is not mutated.

### How to Use

Here are some specific examples provided.

#### When Need Literal Message Text

When log messages may contain `<tag>`-like text that should not be parsed:
```moonbit
let formatter = text_formatter(color_mode=ColorMode::Always)
  .without_style_markup()
```

In this example, message text is rendered literally instead of interpreting inline style tags.

#### When Need A Safe Variant Of A Styled Base Formatter

When one formatter should keep the same colors and template but stop parsing message tags:
```moonbit
let base = text_formatter(color_mode=ColorMode::Always)
let safe = base.without_style_markup()
```

In this example, the derived formatter only changes the message markup policy.

### Error Case

e.g.:
- There is no dedicated failure path for valid `TextFormatter` values.

- If target or field scopes should also stop parsing tags, callers need the corresponding dedicated formatter methods rather than this message-only helper.

### Notes

1. Use this helper when the disabled case is what you want directly.

2. It is equivalent to calling `with_style_markup(StyleMarkupMode::Disabled)` explicitly.
