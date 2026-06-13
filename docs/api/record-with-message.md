---
name: record-with-message
group: api
category: record
update-time: 20260613
description: Return a copy of a record with a replaced message field.
key-word:
    - record
    - message
    - transform
    - public
---

## Record-with-message

Return a copy of a `Record` with a different `message`. This helper is the narrowest way to rewrite the visible event text while preserving the rest of the structured event data.

### Interface

```moonbit
pub fn Record::with_message(self : Record, message : String) -> Record {}
```

#### input

- `self : Record` - Base record whose message should be replaced.
- `message : String` - New message text for the returned record.

#### output

- `Record` - New record value carrying the updated message.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper returns a new record value instead of mutating the original one.
- Only the `message` field is replaced.
- `level`, `timestamp_ms`, `target`, and `fields` are preserved.
- This is useful for adapters, tests, or explicit value-level rewriting before formatting or sink dispatch.

### How to Use

Here are some specific examples provided.

#### When Need To Rewrite One Event Message

When one record should keep its metadata but use different visible text:
```moonbit
let rec = Record::new(Level::Error, "raw failure", target="bridge")
let next = rec.with_message("dispatch failed")
```

In this example, the new message is applied without rebuilding the rest of the record manually.

#### When Need To Normalize Message Text In Tests

When one test record should be adapted to a different wording:
```moonbit
let rec = Record::new(Level::Info, "ok").with_message("started")
```

In this example, the helper keeps the change focused on one field.

### Error Case

e.g.:
- If `message` is empty, the returned record is still valid and simply carries an empty message string.

- If the same rewrite should be reusable across many records, `prefix_message(...)` or a custom `RecordPatch` may be a better fit.

### Notes

1. Use this helper for one-off value-level message replacement.

2. Use patch helpers when message rewriting should participate in a reusable logger pipeline.
