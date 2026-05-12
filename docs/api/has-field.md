---
name: has-field
group: api
category: filtering
update-time: 20260512
description: Create a reusable record predicate that checks whether a field key exists.
key-word:
    - field
    - filter
    - predicate
    - public
---

## Has-field

Create a `RecordPredicate` that returns `true` when a record contains at least one field with the given key. Use it when presence alone matters more than a specific field value.

### Interface

```moonbit
pub fn has_field(key : String) -> RecordPredicate {}
```

#### input

- `key : String` - Field key that should exist in the record.

#### output

- `RecordPredicate` - Predicate that matches records containing a field whose key equals `key`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The predicate scans `rec.fields` in order and stops on the first matching key.
- Only the key is checked; the field value is ignored.
- This helper works well for optional metadata such as `request_id`, `tenant`, or `trace_id`.
- It can be combined with `field_equals(...)` when some records need stricter field matching.

### How to Use

Here are some specific examples provided.

#### When Keep Records Carrying Correlation Data

When only records with tracing context should pass:
```moonbit
let logger = Logger::new(console_sink())
  .with_filter(has_field("trace_id"))
```

In this example, records without `trace_id` are filtered out.

#### When Combine With Severity Rules

When contextual records should also meet a level threshold:
```moonbit
let predicate = all_of([
  has_field("request_id"),
  level_at_least(Level::Warn),
])
```

In this example, only warning-or-higher records with request context remain.

### Error Case

e.g.:
- If `key` is empty, the predicate only matches fields whose key is also empty.

- If the same key appears multiple times, the predicate still returns `true` after the first match.

### Notes

1. Use this helper when field presence is meaningful even if the actual value changes every time.

2. Field ordering does not change the result, only the early return cost.

