---
name: style-tag-registry-define-alias
group: api
category: formatter
update-time: 20260613
description: Define one style-tag name as an alias of another style entry.
key-word:
    - style
    - registry
    - alias
    - public
---

## Style-tag-registry-define-alias

Define one tag name as an alias of another style entry. This helper copies an existing style into the current registry so alternate names can reuse the same visual meaning.

### Interface

```moonbit
pub fn StyleTagRegistry::define_alias(
  self : StyleTagRegistry,
  name : String,
  target : String,
) -> StyleTagRegistry {
```

#### input

- `self : StyleTagRegistry` - Registry to update.
- `name : String` - Alias name to create.
- `target : String` - Existing tag name whose style should be copied.

#### output

- `StyleTagRegistry` - The same registry value after alias resolution is attempted.

### Explanation

Detailed rules explaining key parameters and behaviors

- The method first checks the current registry for `target`.
- If the local registry does not have the target, it falls back to the global style tag registry.
- If the global registry also lacks the target, it falls back to the built-in tag set.
- When no matching target exists in any of those sources, the registry is returned unchanged.
- The resolved style is copied into `name`; this is not a live reference that tracks future target changes.

### How to Use

Here are some specific examples provided.

#### When Need A Friendlier Local Alias

When one project wants a local tag name that mirrors an existing style:
```moonbit
let tags = default_style_tag_registry().define_alias("danger", "error")
```

In this example, `danger` is stored using the same style as the resolved `error` tag.

#### When Need To Alias A Custom Local Tag

When several names should share one custom style definition:
```moonbit
let tags = style_tag_registry()
  .set_tag("accent", fg=Some("#4cc9f0"), bold=true)
  .define_alias("brand", "accent")
```

In this example, `brand` copies the current local `accent` style into the registry.

### Error Case

e.g.:
- If the target tag cannot be resolved locally, globally, or from builtins, no new alias entry is added.

- If callers need a tag with modified style fields rather than an exact copy, use `set_tag(...)` instead.

### Notes

1. This helper is useful for keeping multiple semantic names visually aligned.

2. Alias resolution prefers the current registry before consulting global or built-in tags.
