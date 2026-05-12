---
name: field-equals
group: api
category: filtering
update-time: 20260512
description: Create a reusable record predicate that matches a field by exact key and value.
key-word:
    - field
    - filter
    - predicate
    - public
---

## Field-equals

Create a `RecordPredicate` that returns `true` when a record contains a field whose key and value both match exactly. Use it for stable attribute-based routing.

### Interface

```moonbit
pub fn field_equals(key : String, value : String) -> RecordPredicate {}
```

#### input

- `key : String` - Field key to inspect.
- `value : String` - Exact value expected for that key.

#### output

- `RecordPredicate` - Predicate that matches records containing a field with the expected key and value.

### Explanation

Detailed rules explaining key parameters and behaviors

- Matching requires both `field.key == key` and `field.value == value`.
- The predicate returns `true` on the first matching field.
- This helper is useful for routing records by environment, tenant, operation name, or fixed tags.
- It is stricter than `has_field(...)` because presence alone is not enough.

### How to Use

Here are some specific examples provided.

#### When Keep One Tenant Stream

When log routing should isolate one tenant:
```moonbit
let logger = Logger::new(console_sink())
  .with_filter(field_equals("tenant", "acme"))
```

In this example, records for other tenants are excluded.

#### When Combine With Exact Target Matching

When field and target must both match:
```moonbit
let predicate = all_of([
  target_is("billing"),
  field_equals("region", "cn"),
])
```

In this example, only billing records tagged for the `cn` region remain.

### Error Case

e.g.:
- If `key` or `value` is empty, matching still uses exact equality and may produce no results unless records contain the same empty string.

- If a record contains the key with multiple values, any one exact match is enough for the predicate to return `true`.

### Notes

1. Prefer exact field matching over message substring matching for long-term routing rules.

2. Keep field naming stable across producers if this predicate is reused in shared configs.

