---
name: color-mode-label
group: api
category: formatter
update-time: 20260520
description: Convert a ColorMode value into its stable string label.
key-word:
    - color
    - formatter
    - label
    - public
---

## Color-mode-label

Convert `ColorMode` into its stable string label. This helper is useful for diagnostics, tests, and config inspection output that should mirror the built-in color mode names.

### Interface

```moonbit
pub fn color_mode_label(mode : ColorMode) -> String {
```

#### input

- `mode : ColorMode` - Color mode enum value to label.

#### output

- `String` - Stable label such as `never`, `auto`, or `always`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned strings match the built-in color mode vocabulary.
- This helper is presentation-oriented and does not by itself enable or disable color rendering.
- It is useful when tests or diagnostics should expose the configured color policy clearly.

### How to Use

Here are some specific examples provided.

#### When Need A Readable Color Mode Name

When config or test output should include the current color policy:
```moonbit
let label = color_mode_label(ColorMode::Always)
```

In this example, `label` becomes `"always"`.

### Error Case

e.g.:
- There is no failure path for valid `ColorMode` values.

- If code needs rendering behavior rather than display text, the enum value itself is usually more useful than the label string.

### Notes

1. This helper is mostly useful for readable inspection and assertions.

2. It is a natural companion to `color_support_label(...)`.
