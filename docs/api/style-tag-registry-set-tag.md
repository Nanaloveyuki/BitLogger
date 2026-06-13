---
name: style-tag-registry-set-tag
group: api
category: formatter
update-time: 20260613
description: Add or override a named style tag in a StyleTagRegistry.
key-word:
    - style
    - registry
    - tag
    - public
---

## Style-tag-registry-set-tag

Add or override one named style tag inside a `StyleTagRegistry`. This is the main mutation helper for building custom formatter tag vocabularies in code.

### Interface

```moonbit
pub fn StyleTagRegistry::set_tag(
  self : StyleTagRegistry,
  name : String,
  style~ : TextStyle = text_style(),
  fg~ : String? = None,
  bg~ : String? = None,
  bold~ : Bool = false,
  dim~ : Bool = false,
  italic~ : Bool = false,
  underline~ : Bool = false,
) -> StyleTagRegistry {
```

#### input

- `self : StyleTagRegistry` - Registry to update.
- `name : String` - Tag name to define or replace.
- `style : TextStyle` - Base style value to store before overlay options are applied.
- `fg : String?` - Optional foreground color override.
- `bg : String?` - Optional background color override.
- `bold : Bool` - Whether to enable bold in the stored style.
- `dim : Bool` - Whether to enable dim in the stored style.
- `italic : Bool` - Whether to enable italic in the stored style.
- `underline : Bool` - Whether to enable underline in the stored style.

#### output

- `StyleTagRegistry` - The same registry value after the named entry is updated.

### Explanation

Detailed rules explaining key parameters and behaviors

- The tag name is normalized before storage, so lookup is case-insensitive in practice.
- The explicit `fg`, `bg`, and boolean flags are merged on top of the supplied `style` value.
- Calling `set_tag(...)` for an existing name replaces that entry with the merged result.
- The method returns the registry itself so calls can be chained while building formatter configuration.

### How to Use

Here are some specific examples provided.

#### When Need A Custom Semantic Tag

When text output should recognize a project-specific tag name:
```moonbit
let tags = style_tag_registry()
  .set_tag("accent", fg=Some("#4cc9f0"), bold=true)
```

In this example, `<accent>...</>` becomes available to formatters that use the registry.

#### When Need To Start From An Existing Style

When a tag should reuse a prepared `TextStyle` and then tweak one field:
```moonbit
let base = text_style(fg=Some("#22cc88"))
let tags = style_tag_registry().set_tag("success", style=base, underline=true)
```

In this example, underline is layered on top of the base style value.

### Error Case

e.g.:
- If style markup is disabled in the formatter, defining tags here has no visible effect on rendered output.

- If the same tag name is set multiple times, the latest stored value wins.

### Notes

1. Use this method when custom tag definitions should live in a local registry instead of the global one.

2. `define_alias(...)` is the better fit when one tag name should mirror an existing tag exactly.
