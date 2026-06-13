---
name: text-formatter-with-style-markup
group: api
category: formatter
update-time: 20260613
description: Return a TextFormatter with a different message style-markup policy.
key-word:
    - formatter
    - style
    - markup
    - public
---

## Text-formatter-with-style-markup

Return a copy of a `TextFormatter` with a different message-text style-markup policy. This method is the focused way to change how inline tags inside the main log message are interpreted while preserving the rest of the formatter configuration.

### Interface

```moonbit
pub fn TextFormatter::with_style_markup(self : TextFormatter, style_markup : StyleMarkupMode) -> TextFormatter {
```

#### input

- `self : TextFormatter` - Base formatter to copy.
- `style_markup : StyleMarkupMode` - New message-text markup policy.

#### output

- `TextFormatter` - A new formatter value carrying the updated message markup setting.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method only changes `style_markup`, which controls the main message text.
- The returned formatter preserves timestamp, level, target, field, template, color, and registry settings from `self`.
- Target and field-value markup settings remain unchanged because they have separate dedicated scopes.
- The original formatter value is not mutated.

### How to Use

Here are some specific examples provided.

#### When Need To Restrict Message Tags To Built-ins

When messages should allow built-in tags but not custom registry-driven tags:
```moonbit
let formatter = text_formatter(color_mode=ColorMode::Always)
  .with_style_markup(StyleMarkupMode::Builtin)
```

In this example, message rendering switches to built-in-only tag resolution while the rest of the formatter stays the same.

#### When Need To Reuse One Formatter With Different Message Policies

When a shared base formatter should produce one literal and one styled variant:
```moonbit
let base = text_formatter(color_mode=ColorMode::Always)
let literal = base.with_style_markup(StyleMarkupMode::Disabled)
let rich = base.with_style_markup(StyleMarkupMode::Full)
```

In this example, both derived formatters keep the same non-markup configuration.

### Error Case

e.g.:
- There is no separate failure path for valid `TextFormatter` and `StyleMarkupMode` values.

- If callers need to change target or field markup behavior too, they must use the corresponding dedicated formatter methods instead of assuming this changes every scope.

### Notes

1. This method only affects the main message text, not target text or field values.

2. `without_style_markup()` is the convenience form for the common disabled case.
