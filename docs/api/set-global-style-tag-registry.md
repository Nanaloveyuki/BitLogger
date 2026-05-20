---
name: set-global-style-tag-registry
group: api
category: formatter
update-time: 20260520
description: Replace the shared global style tag registry used by formatters without local overrides.
key-word:
    - style
    - registry
    - global
    - public
---

## Set-global-style-tag-registry

Replace the shared global `StyleTagRegistry`. This helper changes the default tag source used by formatters that do not define their own local registry.

### Interface

```moonbit
pub fn set_global_style_tag_registry(registry : StyleTagRegistry) -> Unit {
```

#### input

- `registry : StyleTagRegistry` - New shared global registry value.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper mutates process-wide shared formatter state.
- Only formatters without local style tags read from the global registry.
- It is useful for centralized theming or tests that need predictable tag behavior.

### How to Use

Here are some specific examples provided.

#### When Need A Process-wide Custom Tag Default

When multiple formatters should share a custom default tag registry:
```moonbit
set_global_style_tag_registry(
  style_tag_registry().set_tag("accent", fg=Some("#102030"), dim=true),
)
```

In this example, subsequent formatters without local tag registries can resolve `accent` from the shared global registry.

### Error Case

e.g.:
- If local formatter tags are already present, those local tags still take priority.

- Global mutation can affect later formatting broadly, so test code should usually restore or reset after temporary changes.

### Notes

1. Use `global_style_tag_registry()` to snapshot the previous value before replacement.

2. Use `reset_global_style_tag_registry()` to restore the library default global registry.
