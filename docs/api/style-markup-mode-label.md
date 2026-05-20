---
name: style-markup-mode-label
group: api
category: formatter
update-time: 20260520
description: Convert a StyleMarkupMode value into its stable string label.
key-word:
    - style
    - formatter
    - label
    - public
---

## Style-markup-mode-label

Convert `StyleMarkupMode` into its stable string label. This helper is useful for diagnostics, tests, and config inspection output.

### Interface

```moonbit
pub fn style_markup_mode_label(mode : StyleMarkupMode) -> String {
```

#### input

- `mode : StyleMarkupMode` - Markup mode enum value to label.

#### output

- `String` - Stable label such as `disabled`, `builtin`, or `full`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned strings match the built-in markup mode vocabulary.
- This helper is presentation-oriented and does not change formatting behavior by itself.
- It is especially useful when tests or logs should expose the active markup policy clearly.

### How to Use

Here are some specific examples provided.

#### When Need A Readable Markup Mode Name

When diagnostics should show which markup mode is active:
```moonbit
let label = style_markup_mode_label(StyleMarkupMode::Builtin)
```

In this example, `label` becomes `"builtin"`.

### Error Case

e.g.:
- There is no failure path for valid `StyleMarkupMode` values.

- If code needs behavior rather than display text, the enum value itself is usually more useful than the returned label.

### Notes

1. This helper is mainly useful for human-readable inspection and assertions.

2. It pairs naturally with formatter config tests and debug output.
