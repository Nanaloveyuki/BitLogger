---
name: record-with-fields
group: api
category: record
update-time: 20260613
description: Return a copy of a record with a replaced field array.
key-word:
    - record
    - fields
    - transform
    - public
---

## Record-with-fields

Return a copy of a `Record` with a different field array. This helper is the narrowest way to replace structured metadata while preserving the record's level, message, timestamp, and target.

### Interface

```moonbit
pub fn Record::with_fields(self : Record, fields : Array[Field]) -> Record {}
```

#### input

- `self : Record` - Base record whose field array should be replaced.
- `fields : Array[Field]` - New structured field list for the returned record.

#### output

- `Record` - New record value carrying the updated fields.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper returns a new record value instead of mutating the original one.
- Only the `fields` array is replaced.
- `level`, `message`, `timestamp_ms`, and `target` are preserved.
- This is useful when one record should swap its metadata wholesale rather than append more fields.

### How to Use

Here are some specific examples provided.

#### When Need To Replace Metadata Entirely

When one record should keep its message and severity but use a new field set:
```moonbit
let rec = Record::new(Level::Info, "accepted", fields=[field("user", "alice")])
let sanitized = rec.with_fields([field("user", "***")])
```

In this example, the original field array is replaced rather than extended.

#### When Need To Clear Per-record Fields

When structured metadata should be removed from one value:
```moonbit
let rec = Record::new(Level::Warn, "retry", fields=[field("job", "42")])
let plain = rec.with_fields([])
```

In this example, the returned record keeps the same event identity but carries no fields.

### Error Case

e.g.:
- If `fields` is empty, the returned record is still valid and simply carries no structured metadata.

- If code should append or merge fields instead of replacing them, `append_fields(...)` or a custom patch is the better fit.

### Notes

1. Use this helper when one record should swap its entire field array.

2. Use `append_fields(...)` when enrichment should preserve the original field list and add more entries afterward.
