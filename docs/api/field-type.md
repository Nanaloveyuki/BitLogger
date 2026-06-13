---
name: field-type
group: api
category: record
update-time: 20260613
description: Public field alias used for structured key-value metadata attached to records.
key-word:
    - field
    - record
    - alias
    - public
---

## Field-type

`Field` is the public structured metadata item type used on records, logger context, filters, and patch helpers. It is a direct alias to the core record field model that stores one key and one value string.

### Interface

```moonbit
pub type Field = @core.Field
```

#### output

- `Field` - Public structured field value containing `key` and `value` text.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a constructor helper by itself.
- The current fields are `key : String` and `value : String`.
- `field(...)` and `fields(...)` construct this type as the main public helpers.
- The same value type is consumed by `Record::new(...)`, `Logger::bind(...)`, write APIs that accept `fields`, field-based predicates, and record patch helpers.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Reusable Metadata Value

When one field should be created once and reused across records or loggers:
```moonbit
let service_field : Field = field("service", "billing")
```

In this example, the metadata stays as a typed reusable value instead of being rebuilt inline each time.

#### When Need To Attach Structured Context To A Record

When code should pass field values into record creation directly:
```moonbit
let rec = Record::new(Level::Info, "accepted", fields=[field("user", "alice")])
```

In this example, the field type becomes part of the record's structured metadata payload.

### Error Case

e.g.:
- `Field` itself does not have a runtime failure mode.

- Empty keys or values are still stored as-is because the type is plain structured data rather than a validated schema.

### Notes

1. Use `field(...)` when you need a value of this type in code.

2. Use arrays of `Field` when attaching multiple metadata entries to records, loggers, or global emitters.
