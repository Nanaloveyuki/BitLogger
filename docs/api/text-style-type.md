---
name: text-style-type
group: api
category: formatter
update-time: 20260613
description: Public text-style alias used for formatter tag definitions and config-driven style values.
key-word:
    - style
    - formatter
    - alias
    - public
---

## Text-style-type

`TextStyle` is the public value type used to describe foreground color, background color, and emphasis flags for formatter styling. It is a direct alias to the style model used by tag registries, formatter config maps, and inline-style resolution.

### Interface

```moonbit
pub type TextStyle = @utils.TextStyle
```

#### output

- `TextStyle` - Public style value containing `fg`, `bg`, `bold`, `dim`, `italic`, and `underline`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a formatter instance or registry.
- The current fields are `fg : String?`, `bg : String?`, `bold : Bool`, `dim : Bool`, `italic : Bool`, and `underline : Bool`.
- `text_style(...)` constructs this type as the normal handwritten entry point.
- The same value type is stored in `StyleTagRegistry` entries and in `TextFormatterConfig` style-tag maps.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Style Value For Reuse

When one style should be defined once and reused across tag registrations or config assembly:
```moonbit
let accent : TextStyle = text_style(fg=Some("#4cc9f0"), bold=true)
```

In this example, the style stays as structured data instead of being tied to one formatter immediately.

#### When Need To Pass A Style Through Formatter Configuration

When style values should be assembled first and attached later:
```moonbit
let warning = text_style(fg=Some("yellow"), bold=true)
```

In this example, the alias makes it explicit that the value can travel through config or registry code unchanged.

### Error Case

e.g.:
- `TextStyle` itself does not have a runtime failure mode.

- A style value can still produce no visible ANSI effect if the chosen formatter disables color or style markup.

### Notes

1. Use `text_style(...)` when you need a value of this type in code.

2. Use `StyleTagRegistry` when named reusable style lookup is needed instead of one standalone style value.
