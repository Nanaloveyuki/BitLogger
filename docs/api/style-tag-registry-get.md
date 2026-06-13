---
name: style-tag-registry-get
group: api
category: formatter
update-time: 20260613
description: Look up one style tag from a StyleTagRegistry.
key-word:
    - style
    - registry
    - lookup
    - public
---

## Style-tag-registry-get

Look up one named style tag from a `StyleTagRegistry`. This is the direct inspection helper for tests, setup validation, or custom formatter logic that needs the stored `TextStyle` value.

### Interface

```moonbit
pub fn StyleTagRegistry::get(self : StyleTagRegistry, name : String) -> TextStyle? {
```

#### input

- `self : StyleTagRegistry` - Registry to inspect.
- `name : String` - Tag name to look up.

#### output

- `TextStyle?` - `Some(style)` when the tag exists, otherwise `None`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The tag name is normalized before lookup.
- This method only checks the current registry value passed as `self`.
- Missing names return `None` instead of raising an error.
- This is useful when code needs the style value itself rather than only presence or absence.

### How to Use

Here are some specific examples provided.

#### When Need To Inspect A Custom Tag

When setup code or tests should verify that a tag was stored:
```moonbit
let tags = style_tag_registry().set_tag("accent", fg=Some("#4cc9f0"))
match tags.get("accent") {
  Some(style) => ignore(style)
  None => panic()
}
```

In this example, the registry returns the stored `TextStyle` for the tag.

#### When Need Graceful Missing-tag Handling

When code should tolerate an absent entry:
```moonbit
let tags = style_tag_registry()
let maybe_style = tags.get("missing")
```

In this example, `maybe_style` becomes `None` instead of failing.

### Error Case

e.g.:
- There is no separate failure path for a missing tag; the method returns `None`.

- If code only needs a yes-or-no existence check, `contains(...)` is simpler than reading the optional style value.

### Notes

1. Use this method when callers need the stored `TextStyle` itself.

2. This lookup does not automatically fall back to the global registry or builtin tags.
