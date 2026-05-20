---
name: style-tag-registry
group: api
category: formatter
update-time: 20260520
description: Create an empty style tag registry for custom formatter markup tags.
key-word:
    - style
    - registry
    - formatter
    - public
---

## Style-tag-registry

Create an empty `StyleTagRegistry` for custom formatter style tags. This is the starting point for defining named tags such as `accent` or aliases such as `danger`.

### Interface

```moonbit
pub fn style_tag_registry() -> StyleTagRegistry {
```

#### output

- `StyleTagRegistry` - Empty registry ready for `set_tag(...)` and alias operations.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned registry starts empty.
- This helper is intended for runtime formatter customization in code.
- Registries created here can be attached to `text_formatter(...)` through `with_style_tags(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Custom Named Tags

When formatter markup should define project-specific tag names:
```moonbit
let tags = style_tag_registry().set_tag("accent", fg=Some("#4cc9f0"), bold=true)
```

In this example, the registry becomes the container for custom named styles.

### Error Case

e.g.:
- If the formatter never enables the relevant style markup mode, tags in the registry may remain unused.

- An empty registry is valid, but it does not add any custom tags by itself.

### Notes

1. This helper creates a runtime registry, not a serializable config map.

2. Use `default_style_tag_registry()` when you want the built-in tag set as a starting point.
