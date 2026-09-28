---
name: redact-field
group: api
category: patching
update-time: 20260928
description: Create a reusable record patch that redacts one field, including secrets inside its value.
key-word:
    - patch
    - redact
    - fields
    - public
---

## Redact-field

Create a `RecordPatch` that rewrites every field whose key matches the given key. A plain value is replaced by `placeholder`. If `sujy123456/lunasieve` finds a secret inside the value, only that secret span is replaced and the surrounding text stays.

### Interface

```moonbit
pub fn redact_field(key : String, placeholder~ : String = "***") -> RecordPatch {}
```

#### input

- `key : String` - Field key whose matching values should be replaced.
- `placeholder : String` - Replacement value written into each matching field.

#### output

- `RecordPatch` - Patch that returns a record with matching field values redacted.

### Explanation

Detailed rules explaining key parameters and behaviors

- The patch maps over the full field list and rewrites each field whose key equals `key`.
- A value with no detected secret is replaced entirely by `placeholder`.
- A value that contains a detected secret is passed to lunasieve `redact`, using `placeholder` as the replacement for each secret span.
- Non-matching fields and the message body are preserved unchanged.

### How to Use

Here are some specific examples provided.

#### When Mask One Sensitive Field

When authentication logs may carry a token:
```moonbit
let logger = Logger::new(console_sink(), target="auth")
  .with_patch(redact_field("token"))
```

In this example, every `token` field value is replaced before output.

#### When Use A Custom Placeholder

When compliance rules require a specific visible marker:
```moonbit
let patch = redact_field("password", placeholder="[redacted]")
```

In this example, matching field values become `[redacted]` instead of the default mask.

### Error Case

e.g.:
- If the record has no matching field key, the patch returns a structurally identical field list.

- If `placeholder` is empty, matching values are replaced by an empty string.

### Notes

1. This helper only rewrites fields; it does not search message text.

2. Use `redact_fields(...)` when several keys should share the same masking rule.

