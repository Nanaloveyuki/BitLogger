---
name: style-tag-registry-contains
group: api
category: formatter
update-time: 20260613
description: Check whether a StyleTagRegistry contains a named style tag.
key-word:
    - style
    - registry
    - contains
    - public
---

## Style-tag-registry-contains

Check whether a `StyleTagRegistry` contains one named tag. This is the boolean inspection companion to `get(...)` when code only needs existence rather than the stored style value.

### Interface

```moonbit
pub fn StyleTagRegistry::contains(self : StyleTagRegistry, name : String) -> Bool {
```

#### input

- `self : StyleTagRegistry` - Registry to inspect.
- `name : String` - Tag name to check.

#### output

- `Bool` - `true` when the registry contains the tag, otherwise `false`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The tag name is normalized before the presence check.
- This method only checks the current registry value, not the global registry or builtin tag set.
- It is useful when code should branch on tag availability without unpacking `TextStyle?`.

### How to Use

Here are some specific examples provided.

#### When Need A Simple Presence Check

When setup code should verify that a registry carries one custom tag:
```moonbit
let tags = style_tag_registry().set_tag("accent", fg=Some("#4cc9f0"))
println(tags.contains("accent"))
```

In this example, the result is `true`.

#### When Need To Guard Optional Registry Behavior

When later logic should only run for existing tags:
```moonbit
let tags = style_tag_registry()
if tags.contains("danger") {
  println("defined")
}
```

In this example, the guarded block runs only when the local registry already defines the tag.

### Error Case

e.g.:
- Missing tags simply produce `false`.

- If code needs the actual stored style value, `get(...)` is the better API.

### Notes

1. This is the lightest-weight way to probe one registry entry.

2. The method is useful in tests that only care about tag presence.
