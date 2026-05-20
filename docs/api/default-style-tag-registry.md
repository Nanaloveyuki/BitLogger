---
name: default-style-tag-registry
group: api
category: formatter
update-time: 20260520
description: Create the built-in style tag registry containing default semantic and color tags.
key-word:
    - style
    - registry
    - default
    - public
---

## Default-style-tag-registry

Create the built-in `StyleTagRegistry` containing the library's default style tags. This helper is useful when callers want to start from the standard tag set and then extend or override it.

### Interface

```moonbit
pub fn default_style_tag_registry() -> StyleTagRegistry {
```

#### output

- `StyleTagRegistry` - Registry seeded with built-in tags and aliases.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned registry contains the library's built-in style tag set.
- Callers can extend or override entries before attaching the registry to a formatter.
- This helper is useful when custom tags should coexist with built-in semantic tags.

### How to Use

Here are some specific examples provided.

#### When Need Built-in Tags Plus Local Overrides

When a formatter should keep defaults but customize one tag:
```moonbit
let tags = default_style_tag_registry().set_tag("success", fg=Some("#00ffaa"), underline=true)
```

In this example, the built-in registry is reused and then locally overridden.

### Error Case

e.g.:
- If the formatter disables style markup, built-in tags may not be applied even though the registry exists.

- If callers need a clean registry with no built-in tags, use `style_tag_registry()` instead.

### Notes

1. This helper is the easiest way to preserve the standard tag vocabulary.

2. It is commonly paired with `text_formatter(...).with_style_tags(...)`.
