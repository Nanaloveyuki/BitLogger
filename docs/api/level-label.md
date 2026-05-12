---
name: level-label
group: api
category: level
update-time: 20260512
description: Convert a level into its uppercase display label.
key-word:
    - level
    - label
    - helper
    - public
---

## Level-label

Convert a `Level` into its uppercase display label. This helper is useful for formatting, diagnostics, and user-visible output that should mirror the built-in level names.

### Interface

```moonbit
pub fn Level::label(self : Level) -> String {}
```

#### input

- `self : Level` - Level value whose display label should be returned.

#### output

- `String` - Uppercase label such as `TRACE`, `DEBUG`, `INFO`, `WARN`, or `ERROR`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned strings are uppercase built-in labels.
- This helper is intended for readable output and formatter logic.
- It is separate from `priority()`, which is for numeric ordering.
- The label reflects the enum variant directly and does not depend on any logger configuration.

### How to Use

Here are some specific examples provided.

#### When Show A Level In Custom Output

When a callback or formatter wants a readable label:
```moonbit
let label = Level::Warn.label()
```

In this example, `label` becomes `"WARN"`.

#### When Build Simple Human-readable Diagnostics

When direct console text should include the level name:
```moonbit
let rec = Record::new(Level::Error, "dispatch failed")
println(rec.level.label())
```

In this example, the output uses the built-in uppercase severity name.

### Error Case

e.g.:
- There is no failure path for valid `Level` values.

- If code needs numeric ordering rather than display text, `label()` is the wrong helper.

### Notes

1. Use this helper for presentation and diagnostics.

2. Prefer `priority()` or `enabled()` for threshold logic.

