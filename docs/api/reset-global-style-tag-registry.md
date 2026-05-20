---
name: reset-global-style-tag-registry
group: api
category: formatter
update-time: 20260520
description: Reset the shared global style tag registry back to the library default.
key-word:
    - style
    - registry
    - reset
    - public
---

## Reset-global-style-tag-registry

Reset the shared global `StyleTagRegistry` back to the library default. This helper is useful after temporary global overrides in tests or boot code.

### Interface

```moonbit
pub fn reset_global_style_tag_registry() -> Unit {
```

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper restores the shared global registry to the built-in default tag set.
- It is the simplest cleanup path after temporary global registry customization.
- Local formatter registries remain unaffected because they are not sourced from the shared global registry.

### How to Use

Here are some specific examples provided.

#### When Need To Undo Temporary Global Overrides

When tests or boot code changed the shared registry and want the default back:
```moonbit
set_global_style_tag_registry(style_tag_registry().set_tag("accent", fg=Some("#123456")))
reset_global_style_tag_registry()
```

In this example, subsequent formatters without local registries return to the library default global tag set.

### Error Case

e.g.:
- If a formatter already carries local tags, resetting the global registry does not change that formatter's local tag behavior.

- This helper only resets shared global formatter state; it does not alter serialized formatter configs.

### Notes

1. This is the cleanup helper paired with `set_global_style_tag_registry(...)`.

2. It is especially useful in tests that temporarily customize shared style behavior.
