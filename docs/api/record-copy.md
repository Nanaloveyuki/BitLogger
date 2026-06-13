---
name: record-copy
group: api
category: record
update-time: 20260613
description: Return a shallow copy of a record without changing any of its fields.
key-word:
    - record
    - copy
    - helper
    - public
---

## Record-copy

Return a copy of a `Record` with the same field values. This helper is useful when code wants an explicit independent record value before passing it to sinks, patches, or other downstream steps.

### Interface

```moonbit
pub fn Record::copy(self : Record) -> Record {}
```

#### input

- `self : Record` - Base record that should be copied.

#### output

- `Record` - New record value containing the same `level`, `message`, `timestamp_ms`, `target`, and `fields`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper returns a new `Record` value instead of reusing the original one directly.
- `level`, `message`, `timestamp_ms`, `target`, and `fields` are preserved unchanged.
- It is the narrowest explicit duplication helper for a record value.
- This is useful when a downstream path should receive its own record value even though the event data does not change.

### How to Use

Here are some specific examples provided.

#### When Need An Explicit Duplicate For Fanout-style Handling

When one path should keep the current record value while another path continues independently:
```moonbit
let rec = Record::new(Level::Info, "started", target="svc")
let duplicate = rec.copy()
```

In this example, the caller gets a second `Record` value with the same event data.

#### When Need A Stable Baseline Before Later Transformations

When one value should be copied before applying further replacement helpers:
```moonbit
let base = Record::new(Level::Warn, "retry")
let patched = base.copy().with_target("jobs.retry")
```

In this example, the copy step makes the later transformation intent explicit.

### Error Case

e.g.:
- `Record::copy()` itself does not have a runtime failure mode.

- If the code does not actually need a second record value, copying adds no new information and may be unnecessary.

### Notes

1. Use this helper when explicit value duplication improves clarity.

2. It pairs naturally with later `Record` transformation helpers when one path should preserve a baseline value first.
