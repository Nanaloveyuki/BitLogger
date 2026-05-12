---
name: redact-fields
group: api
category: patching
update-time: 20260512
description: Create a reusable record patch that redacts multiple field keys.
key-word:
    - patch
    - redact
    - fields
    - public
---

## Redact-fields

Create a `RecordPatch` that replaces the value of every field whose key appears in a provided key list. Use it for shared masking rules across several sensitive fields.

### Interface

```moonbit
pub fn redact_fields(keys : Array[String], placeholder~ : String = "***") -> RecordPatch {}
```

#### input

- `keys : Array[String]` - Field keys whose values should be redacted.
- `placeholder : String` - Replacement value written into each matching field.

#### output

- `RecordPatch` - Patch that returns a record with matching field values redacted.

### Explanation

Detailed rules explaining key parameters and behaviors

- The patch maps over the record field list and rewrites any field whose key is contained in `keys`.
- Non-matching fields are preserved.
- The same placeholder is applied to every matching key in the set.
- This helper is useful for masking bundles such as `token`, `password`, and `secret` with one patch.

### How to Use

Here are some specific examples provided.

#### When Mask Several Sensitive Keys

When one logger must protect multiple credentials:
```moonbit
let logger = Logger::new(console_sink())
  .with_patch(redact_fields(["token", "password", "secret"]))
```

In this example, every matching field value is masked before the sink sees it.

#### When Share One Custom Mask

When the output should show one explicit policy marker:
```moonbit
let patch = redact_fields([
  "access_key",
  "session_key",
], placeholder="[hidden]")
```

In this example, all matching fields use the same replacement text.

### Error Case

e.g.:
- If `keys` is empty, the patch behaves like a pass-through field mapper.

- If the same key appears multiple times in `keys`, matching behavior is unchanged because membership is what matters.

### Notes

1. This helper is better than stacking many single-key patches when all keys share the same placeholder policy.

2. It only rewrites structured fields, not text inside the message body.

