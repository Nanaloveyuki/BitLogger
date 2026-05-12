---
name: field
group: api
category: record
update-time: 20260512
description: Create a single structured field value from a key and value pair.
key-word:
    - field
    - record
    - helper
    - public
---

## Field

Create a single `Field` value from a key and value pair. This is the basic helper used throughout logger, patch, and filter APIs whenever structured metadata needs to be attached to a record.

### Interface

```moonbit
pub fn field(key : String, value : String) -> Field {}
```

#### input

- `key : String` - Field key name.
- `value : String` - Field value text.

#### output

- `Field` - Structured field value ready to be used in a record or field array.

### Explanation

Detailed rules explaining key parameters and behaviors

- The helper constructs a `Field` directly from the provided key and value.
- No deduplication, normalization, or validation is applied.
- This is the standard primitive used by `fields(...)`, `append_fields(...)`, and all log write APIs that accept structured fields.
- The created field preserves the original input strings exactly.

### How to Use

Here are some specific examples provided.

#### When Add One Inline Event Field

When a single structured field is enough:
```moonbit
logger.info("accepted", fields=[field("user", "alice")])
```

In this example, the event carries one explicit structured attribute.

#### When Build Shared Context Fields

When binding one reusable metadata field to a logger:
```moonbit
let logger = Logger::new(console_sink(), target="audit")
  .bind([field("service", "billing")])
```

In this example, the field becomes part of every later emitted record.

### Error Case

e.g.:
- If `key` is empty, the resulting field still exists and keeps the empty string key.

- If `value` is empty, the field remains valid and simply stores an empty string value.

### Notes

1. Use this helper when only one field is needed and tuple syntax would be less direct.

2. Prefer stable field keys so filters and downstream tooling remain predictable.

