---
name: text-formatter-with-color-support
group: api
category: formatter
update-time: 20260613
description: Return a TextFormatter with a different color precision setting.
key-word:
    - formatter
    - color
    - support
    - public
---

## Text-formatter-with-color-support

Return a copy of a `TextFormatter` with a different `ColorSupport` setting. This method is the focused way to change color precision for ANSI rendering while preserving the formatter's layout, markup, and registry behavior.

### Interface

```moonbit
pub fn TextFormatter::with_color_support(self : TextFormatter, color_support : ColorSupport) -> TextFormatter {
```

#### input

- `self : TextFormatter` - Base formatter to copy.
- `color_support : ColorSupport` - New color precision policy.

#### output

- `TextFormatter` - A new formatter value carrying the updated color support setting.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method only changes `color_support`.
- The returned formatter preserves timestamp, level, target, fields, template, markup settings, and style tags from `self`.
- The setting only matters when color output is enabled through `ColorMode`.
- The original formatter value is not mutated.

### How to Use

Here are some specific examples provided.

#### When Need To Downgrade To Basic ANSI Colors

When one formatter should stay compatible with terminals that only handle simpler color sequences:
```moonbit
let formatter = text_formatter(color_mode=ColorMode::Always)
  .with_color_support(ColorSupport::Basic)
```

In this example, the formatter keeps its overall behavior but prefers the basic ANSI color vocabulary.

#### When Need Two Precision Variants Of One Formatter

When the same base formatter should produce basic and truecolor variants:
```moonbit
let base = text_formatter(color_mode=ColorMode::Always)
let basic = base.with_color_support(ColorSupport::Basic)
let rich = base.with_color_support(ColorSupport::TrueColor)
```

In this example, both derived formatters keep the same markup and layout settings.

### Error Case

e.g.:
- There is no separate failure path for valid `TextFormatter` and `ColorSupport` values.

- If `ColorMode::Never` disables color output, changing `color_support` does not produce a visible effect.

### Notes

1. Use this method for color precision changes without rebuilding the whole formatter explicitly.

2. It is useful when one formatter definition should be reused across terminals with different color capabilities.
