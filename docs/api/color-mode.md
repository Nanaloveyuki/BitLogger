---
name: color-mode
group: api
category: formatter
update-time: 20260613
description: Public color-mode enum alias used by text formatters and formatter config.
key-word:
    - color
    - formatter
    - alias
    - public
---

## Color-mode

`ColorMode` is the public enum that controls when ANSI color rendering is enabled for text formatting. It is a direct alias to the formatter enum used by both `text_formatter(...)` and `TextFormatterConfig::new(...)`.

### Interface

```moonbit
pub type ColorMode = @utils.ColorMode
```

#### output

- `ColorMode` - Public formatter color-policy enum with the variants `Never`, `Auto`, and `Always`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a wrapper or a separate formatter mode.
- `ColorMode::Never` disables ANSI color output.
- `ColorMode::Always` always enables ANSI color rendering.
- `ColorMode::Auto` currently follows the built-in `NO_COLOR` environment check.
- The same enum is used by runtime formatters and serializable formatter config objects.

### How to Use

Here are some specific examples provided.

#### When Need Plain Text Without ANSI Codes

When logs should stay uncolored even if the terminal supports color:
```moonbit
let formatter = text_formatter(color_mode=ColorMode::Never)
```

In this example, rendered text keeps the formatter output readable without ANSI escape sequences.

#### When Need Forced Terminal Colors

When tests or demos should always emit colored output:
```moonbit
let formatter = text_formatter(color_mode=ColorMode::Always)
```

In this example, ANSI color rendering is enabled regardless of `NO_COLOR`.

### Error Case

e.g.:
- `ColorMode` itself does not have a runtime failure mode.

- `ColorMode::Auto` is policy-based, so the final visible result still depends on environment state such as `NO_COLOR`.

### Notes

1. Use `color_mode_label(...)` when you need a stable string form for diagnostics or tests.

2. This enum controls whether color is used, while `ColorSupport` controls how rich the color encoding can be.
