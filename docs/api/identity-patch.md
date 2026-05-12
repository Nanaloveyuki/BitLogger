---
name: identity-patch
group: api
category: patching
update-time: 20260512
description: Create a reusable record patch that returns records unchanged.
key-word:
    - patch
    - transform
    - record
    - public
---

## Identity-patch

Create a `RecordPatch` that returns the input record unchanged. This helper is useful as a neutral default, a placeholder in configuration, or a composition baseline.

### Interface

```moonbit
pub fn identity_patch() -> RecordPatch {}
```

#### output

- `RecordPatch` - Patch function that returns the original record without modification.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned patch is a pure pass-through transformation.
- It does not allocate new fields or rewrite existing properties.
- This helper is useful when a patch slot must be provided but no mutation is currently needed.
- It also works as a safe baseline inside `compose_patches(...)` pipelines.

### How to Use

Here are some specific examples provided.

#### When Need A Neutral Patch

When a logger pipeline expects a patch but no rewrite is required yet:
```moonbit
let logger = Logger::new(console_sink())
  .with_patch(identity_patch())
```

In this example, the logger shape stays consistent while records remain unchanged.

#### When Build Patches Conditionally

When a branch may or may not enable a real patch:
```moonbit
let patch = if enable_redaction {
  redact_field("token")
} else {
  identity_patch()
}
```

In this example, caller code can still treat the result as a normal `RecordPatch`.

### Error Case

e.g.:
- `identity_patch()` has no failure path; it simply returns the original record.

- If a caller expects visible transformation, using this patch will intentionally produce none.

### Notes

1. Use this helper when you want a no-op patch with explicit intent instead of a custom inline closure.

2. It is especially useful in conditional or generated patch pipelines.

