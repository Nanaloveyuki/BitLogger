---
name: record-with-target
group: api
category: record
update-time: 20260613
description: Return a copy of a record with a replaced target field.
key-word:
    - record
    - target
    - transform
    - public
---

## Record-with-target

Return a copy of a `Record` with a different `target`. This helper is the narrowest way to retarget one record value while preserving its level, message, timestamp, and fields.

### Interface

```moonbit
pub fn Record::with_target(self : Record, target : String) -> Record {}
```

#### input

- `self : Record` - Base record whose target should be replaced.
- `target : String` - New target value for the returned record.

#### output

- `Record` - New record value carrying the updated target.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper returns a new record value instead of mutating the original one.
- Only the `target` field is replaced.
- `level`, `message`, `timestamp_ms`, and `fields` are preserved.
- This is useful for adapters, patches, or tests that need one explicit retargeted record value.

### How to Use

Here are some specific examples provided.

#### When Need To Retarget One Existing Record

When one record should be reclassified under a different namespace:
```moonbit
let rec = Record::new(Level::Info, "started", target="worker")
let api_rec = rec.with_target("api")
```

In this example, only the returned record carries the new target.

#### When Need Direct Value-level Rewriting In Tests

When a formatter or filter test should exercise a different target without rebuilding the full record:
```moonbit
let rec = Record::new(Level::Warn, "retry").with_target("jobs.retry")
```

In this example, the retargeting stays local to one record value.

### Error Case

e.g.:
- If `target` is empty, the returned record is still valid and simply carries an empty target.

- If code should rewrite many records consistently, a reusable patch such as `set_target(...)` may be a better fit than calling this helper repeatedly.

### Notes

1. Use this helper for value-level retargeting of one record.

2. Use `set_target(...)` when the same transformation should be reused as a `RecordPatch`.
