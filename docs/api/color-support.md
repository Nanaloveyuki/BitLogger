---
name: color-support
group: api
category: formatter
update-time: 20260613
description: Public color-support enum alias used by text formatters and formatter config.
key-word:
    - color
    - formatter
    - alias
    - public
---

## Color-support

`ColorSupport` is the public enum that controls how much color precision a text formatter should use when ANSI color output is enabled. It is a direct alias to the formatter enum used by both runtime formatters and serializable formatter config.

### Interface

```moonbit
pub type ColorSupport = @utils.ColorSupport
```

#### output

- `ColorSupport` - Public formatter color-capability enum with the variants `Basic` and `TrueColor`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a wrapper or a separate rendering engine.
- `ColorSupport::Basic` prefers named/basic ANSI color codes.
- `ColorSupport::TrueColor` allows 24-bit color codes when the style input uses values such as hex colors.
- This setting only matters when color output is enabled through `ColorMode`.
- The same enum is used by `text_formatter(...)` and `TextFormatterConfig::new(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Conservative Basic ANSI Colors

When output should stay within the smaller named ANSI color set:
```moonbit
let formatter = text_formatter(
  color_mode=ColorMode::Always,
  color_support=ColorSupport::Basic,
)
```

In this example, style rendering prefers the basic color vocabulary instead of 24-bit codes.

#### When Need Hex-style Richer Color Rendering

When custom style tags should preserve truecolor output where possible:
```moonbit
let formatter = text_formatter(
  color_mode=ColorMode::Always,
  color_support=ColorSupport::TrueColor,
)
```

In this example, formatter styles can emit richer ANSI color codes for hex-based styles.

### Error Case

e.g.:
- `ColorSupport` itself does not have a runtime failure mode.

- If `ColorMode::Never` disables ANSI color output, changing `ColorSupport` does not produce a visible effect.

### Notes

1. Use `color_support_label(...)` when you need a stable string form.

2. This enum controls color precision, not whether color rendering is enabled at all.
