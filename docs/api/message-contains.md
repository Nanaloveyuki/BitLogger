---
name: message-contains
group: api
category: filtering
update-time: 20260512
description: Create a reusable record predicate that matches records by message fragment.
key-word:
    - message
    - filter
    - predicate
    - public
---

## Message-contains

Create a `RecordPredicate` that returns `true` when a log message contains the given fragment. This helper is mainly useful for diagnostics, temporary routing, and focused debugging.

### Interface

```moonbit
pub fn message_contains(fragment : String) -> RecordPredicate {}
```

#### input

- `fragment : String` - Substring expected to appear in `rec.message`.

#### output

- `RecordPredicate` - Predicate that matches records whose message contains the fragment.

### Explanation

Detailed rules explaining key parameters and behaviors

- Matching uses `String::contains(...)` on the full message text.
- The predicate is case-sensitive unless the message was normalized earlier.
- This helper is convenient for ad hoc triage when targets or fields are not enough.
- It should usually complement more stable filters rather than replace them in long-term configs.

### How to Use

Here are some specific examples provided.

#### When Watch A Temporary Error Pattern

When a debugging session focuses on one phrase:
```moonbit
let logger = Logger::new(console_sink())
  .with_filter(message_contains("retry failed"))
```

In this example, only messages carrying that fragment remain visible.

#### When Combine With Target Filtering

When the same message should be isolated inside one subsystem:
```moonbit
let predicate = all_of([
  target_has_prefix("worker.sync"),
  message_contains("timeout"),
])
```

In this example, unrelated timeout messages from other targets are ignored.

### Error Case

e.g.:
- If `fragment` is empty, the predicate effectively matches every message because every string contains an empty substring.

- If messages are localized or reformatted frequently, fragment-based matching can become brittle.

### Notes

1. Prefer field- or target-based filtering for stable production rules.

2. Message substring filters are most valuable during debugging and migration periods.

