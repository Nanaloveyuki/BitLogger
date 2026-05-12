---
name: any-of
group: api
category: filtering
update-time: 20260512
description: Create a reusable record predicate that passes when any nested predicate matches.
key-word:
    - combine
    - filter
    - predicate
    - public
---

## Any-of

Create a `RecordPredicate` that returns `true` when at least one predicate in the array returns `true`. This helper is useful for routing several independent cases through the same path.

### Interface

```moonbit
pub fn any_of(predicates : Array[RecordPredicate]) -> RecordPredicate {}
```

#### input

- `predicates : Array[RecordPredicate]` - Predicates where any successful match should admit the record.

#### output

- `RecordPredicate` - Predicate that returns `true` when at least one nested predicate returns `true`.

### Explanation

Detailed rules explaining key parameters and behaviors

- Predicates are evaluated in array order.
- Evaluation stops early on the first predicate that returns `true`.
- If the array is empty, the combined predicate returns `false` because no predicate matched.
- This helper is useful when several targets, levels, or field signatures should share one sink.

### How to Use

Here are some specific examples provided.

#### When Accept Several Target Paths

When multiple subsystems should share one route:
```moonbit
let predicate = any_of([
  target_is("audit"),
  target_has_prefix("security"),
])
```

In this example, either matching branch is enough for the record to pass.

#### When Combine Different Diagnostic Conditions

When several independent signals are interesting:
```moonbit
let predicate = any_of([
  level_at_least(Level::Error),
  message_contains("timeout"),
  field_equals("retryable", "true"),
])
```

In this example, one satisfied condition is enough to keep the record visible.

### Error Case

e.g.:
- If `predicates` is empty, the returned predicate always evaluates to `false`.

- If one nested predicate is too broad, it may shadow the intent of the other branches.

### Notes

1. Put the most common or cheapest success path earlier when evaluation cost matters.

2. Use `any_of(...)` when a single sink should accept multiple independent match patterns.

