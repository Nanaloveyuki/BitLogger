---
name: text-style
group: api
category: formatter
update-time: 20260520
description: Create a reusable text style used by style tags and formatter config helpers.
key-word:
    - style
    - formatter
    - color
    - public
---

## Text-style

Create a `TextStyle` describing foreground color, background color, and emphasis flags such as bold or underline. This helper is the basic style value used by formatter style tags and config-driven formatter settings.

### Interface

```moonbit
pub fn text_style(
  fg~ : String? = None,
  bg~ : String? = None,
  bold~ : Bool = false,
  dim~ : Bool = false,
  italic~ : Bool = false,
  underline~ : Bool = false,
) -> TextStyle {
```

#### input

- `fg : String?` - Optional foreground color, usually a named color or hex string.
- `bg : String?` - Optional background color.
- `bold : Bool` - Whether bold emphasis is enabled.
- `dim : Bool` - Whether dim emphasis is enabled.
- `italic : Bool` - Whether italic emphasis is enabled.
- `underline : Bool` - Whether underline emphasis is enabled.

#### output

- `TextStyle` - Reusable style value.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper creates a plain style value; it does not register tags by itself.
- The returned style is commonly used in `style_tag_registry()` and `TextFormatterConfig::new(style_tags=...)`.
- Color interpretation still depends on formatter color settings and runtime support.

### How to Use

Here are some specific examples provided.

#### When Need A Reusable Custom Tag Style

When a formatter should define a named style tag:
```moonbit
let accent = text_style(fg=Some("#4cc9f0"), bold=true)
```

In this example, `accent` becomes a reusable style value that can be attached to a style tag registry or config map.

### Error Case

e.g.:
- If a style uses colors but the formatter disables markup or color output, visible rendering may not reflect the full style.

- This helper does not validate higher-level tag naming because it only creates the style value itself.

### Notes

1. This is the basic building block for style-tag customization.

2. Use `style_tag_registry()` when you need named tags rather than a raw style value.
