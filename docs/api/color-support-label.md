---
name: color-support-label
group: api
category: formatter
update-time: 20260520
description: Convert a ColorSupport value into its stable string label.
key-word:
    - color
    - formatter
    - label
    - public
---

## Color-support-label

Convert `ColorSupport` into its stable string label. This helper is useful for diagnostics, tests, and config-oriented output that should mirror the built-in color support names.

### Interface

```moonbit
pub fn color_support_label(support : ColorSupport) -> String {
```

#### input

- `support : ColorSupport` - Color support enum value to label.

#### output

- `String` - Stable label such as `basic` or `truecolor`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned strings are stable enum labels used by config and tests.
- This helper is presentation-oriented and does not change formatter behavior by itself.
- It is useful when code should display or assert a readable color support mode.

### How to Use

Here are some specific examples provided.

#### When Need A Readable Color Support Name

When diagnostics or tests should show the selected color capability:
```moonbit
let label = color_support_label(ColorSupport::Basic)
```

In this example, `label` becomes `"basic"`.

### Error Case

e.g.:
- There is no failure path for valid `ColorSupport` values.

- If code needs to choose rendering behavior, the enum value itself is usually more useful than its label string.

### Notes

1. This helper is mostly useful for readable output and assertions.

2. It pairs naturally with config parsing and formatter inspection tests.
