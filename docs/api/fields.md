---
name: fields
group: api
category: record
update-time: 20260512
description: Build structured field arrays ergonomically from key-value tuples.
key-word:
    - fields
    - record
    - helper
    - public
---

## Fields

Create an `Array[Field]` from an array of `(String, String)` tuples. This helper reduces repetitive `field(...)` calls when binding context or constructing event fields.

### Interface

```moonbit
pub fn fields(entries : Array[(String, String)]) -> Array[Field] {}
```

#### input

- `entries : Array[(String, String)]` - Tuple entries where `.0` is the field key and `.1` is the field value.

#### output

- `Array[Field]` - Structured field array ready for logger APIs.

### Explanation

Detailed rules explaining key parameters and behaviors

- Each tuple becomes one `Field` value.
- Order is preserved.
- This helper is purely ergonomic and does not add validation beyond normal string handling.
- It is commonly used with `bind(...)`, `with_context_fields(...)`, and per-event field arguments.

### How to Use

Here are some specific examples provided.

#### When Build Reusable Context Fields

When binding stable metadata to a logger:
```moonbit
let logger = Logger::new(console_sink(), target="audit")
  .bind(fields([("service", "billing"), ("scope", "login")]))
```

In this example, tuple syntax is shorter and easier to scan than repeated `field(...)` calls.

#### When Build Small Per-event Field Arrays

When logging a few fields inline:
```moonbit
logger.info("accepted", fields=fields([("user", "alice"), ("status", "ok")]))
```

In this example, the helper keeps call sites compact.

### Error Case

e.g.:
- If `entries` is empty, the result is just an empty field array.

- Duplicate keys are preserved rather than collapsed.

### Notes

1. Use `field(...)` when only one field is needed.

2. Use `fields(...)` when tuple syntax improves readability.

