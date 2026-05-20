---
name: global-style-tag-registry
group: api
category: formatter
update-time: 20260520
description: Read the shared global style tag registry used by formatters without local tag overrides.
key-word:
    - style
    - registry
    - global
    - public
---

## Global-style-tag-registry

Read the shared global `StyleTagRegistry`. This helper is useful when code wants to inspect or reuse the current process-wide formatter tag registry.

### Interface

```moonbit
pub fn global_style_tag_registry() -> StyleTagRegistry {
```

#### output

- `StyleTagRegistry` - Current shared global style tag registry.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper reads the shared global registry used when a formatter has no local registry override.
- It is useful for inspection, temporary replacement, or restoration workflows.
- Local formatter registries still take priority over the global registry.

### How to Use

Here are some specific examples provided.

#### When Need To Snapshot And Restore Global Tags

When tests or boot code temporarily replace the shared registry:
```moonbit
let previous = global_style_tag_registry()
set_global_style_tag_registry(style_tag_registry().set_tag("accent", fg=Some("#123456")))
set_global_style_tag_registry(previous)
```

In this example, the current global registry is captured and later restored.

### Error Case

e.g.:
- If a formatter already has local style tags, global tag changes may not affect that formatter.

- This helper only reads the shared registry; it does not mutate it.

### Notes

1. Use `set_global_style_tag_registry(...)` or `reset_global_style_tag_registry()` for mutation.

2. Global registry changes should be made carefully because they affect subsequent formatting without local overrides.
