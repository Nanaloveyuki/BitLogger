---
name: style-markup-mode
group: api
category: formatter
update-time: 20260613
description: Public style-markup enum alias used by text formatter message, target, and field rendering.
key-word:
    - style
    - formatter
    - alias
    - public
---

## Style-markup-mode

`StyleMarkupMode` is the public enum that controls whether inline style tags should be parsed by a text formatter. It is a direct alias to the formatter enum used for message text, target text, and field-value rendering scopes.

### Interface

```moonbit
pub type StyleMarkupMode = @utils.StyleMarkupMode
```

#### output

- `StyleMarkupMode` - Public formatter markup-policy enum with the variants `Disabled`, `Builtin`, and `Full`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a wrapper or separate parser surface.
- `StyleMarkupMode::Disabled` treats inline markup as plain text.
- `StyleMarkupMode::Builtin` limits tag resolution to the built-in tag set.
- `StyleMarkupMode::Full` allows local style tags, global style tags, and built-in tags to participate in resolution.
- The same enum is used by `style_markup`, `target_style_markup`, and `fields_style_markup` in formatter APIs.

### How to Use

Here are some specific examples provided.

#### When Need To Disable Inline Tag Parsing Entirely

When message text should remain literal even if it contains style-like tags:
```moonbit
let formatter = text_formatter(style_markup=StyleMarkupMode::Disabled)
```

In this example, strings such as `<accent>hello</>` are kept as plain text.

#### When Need Only Built-in Tag Support

When formatters should allow the built-in tag vocabulary without opening custom registry behavior:
```moonbit
let formatter = text_formatter(style_markup=StyleMarkupMode::Builtin)
```

In this example, built-in tags such as `<warning>...</>` can be resolved while custom registry tags are not the source of truth.

### Error Case

e.g.:
- `StyleMarkupMode` itself does not have a runtime failure mode.

- Unknown or invalid tags do not raise an error; current behavior falls back to plain text handling.

### Notes

1. Use `style_markup_mode_label(...)` when you need a stable string form for logging or assertions.

2. Message, target, and field rendering each have their own markup scope, so one formatter can mix different markup policies deliberately.
