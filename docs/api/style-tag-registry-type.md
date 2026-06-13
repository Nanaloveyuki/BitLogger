---
name: style-tag-registry-type
group: api
category: formatter
update-time: 20260613
description: Public style-tag registry alias used for formatter tag lookup and customization.
key-word:
    - style
    - registry
    - alias
    - public
---

## Style-tag-registry-type

`StyleTagRegistry` is the public registry type used to map style-tag names to `TextStyle` values. It is a direct alias to the registry model used by local formatter tag sets, global tag customization, and default tag helpers.

### Interface

```moonbit
pub type StyleTagRegistry = @utils.StyleTagRegistry
```

#### output

- `StyleTagRegistry` - Public style-tag registry value containing named `TextStyle` entries.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a formatter instance.
- The current registry model stores named `TextStyle` entries internally.
- `style_tag_registry()` creates an empty value of this type.
- `default_style_tag_registry()`, `global_style_tag_registry()`, and formatter methods such as `with_style_tags(...)` all operate on this same public registry type.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Registry For Local Formatter Tags

When style tags should be assembled before they are attached to a formatter:
```moonbit
let tags : StyleTagRegistry = style_tag_registry()
  .set_tag("accent", fg=Some("#4cc9f0"), bold=true)
```

In this example, the registry remains a standalone typed value until a formatter uses it.

#### When Need To Pass A Registry Through Shared Setup Code

When application boot code should return or store a reusable tag set:
```moonbit
let tags = default_style_tag_registry()
```

In this example, the alias makes it explicit that the value is the registry itself rather than one formatter.

### Error Case

e.g.:
- `StyleTagRegistry` itself does not have a runtime failure mode.

- Unknown tag lookups simply produce no matching style instead of raising an error.

### Notes

1. Use `style_tag_registry()` or `default_style_tag_registry()` when you need a value of this type in code.

2. Attach this registry to a `TextFormatter` when tag lookup should affect actual rendered output.
