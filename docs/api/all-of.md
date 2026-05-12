---
name: all-of
group: api
category: filtering
update-time: 20260512
description: Create a reusable record predicate that requires every nested predicate to pass.
key-word:
    - combine
    - filter
    - predicate
    - public
---

## All-of

Create a `RecordPredicate` that returns `true` only when every predicate in the array returns `true`. This helper is the standard way to build strict multi-condition filters.

### Interface

```moonbit
pub fn all_of(predicates : Array[RecordPredicate]) -> RecordPredicate {}
```

#### input

- `predicates : Array[RecordPredicate]` - Predicates that must all succeed for a record to match.

#### output

- `RecordPredicate` - Predicate that returns `true` only when every nested predicate returns `true`.

### Explanation

Detailed rules explaining key parameters and behaviors

- Predicates are evaluated in array order.
- Evaluation stops early on the first predicate that returns `false`.
- If the array is empty, the combined predicate returns `true` because no condition failed.
- This helper is ideal for combining namespace, level, and field requirements into one reusable rule.

### How to Use

Here are some specific examples provided.

#### When Require Several Conditions

When routing should be both target- and level-aware:
```moonbit
let predicate = all_of([
  target_has_prefix("service.api"),
  level_at_least(Level::Warn),
])
```

In this example, records must satisfy both conditions before they pass.

#### When Add Field Constraints

When only contextual failures should remain:
```moonbit
let predicate = all_of([
  message_contains("failed"),
  has_field("request_id"),
  not_(field_equals("tenant", "internal")),
])
```

In this example, the filter stays readable even though the rule has several parts.

### Error Case

e.g.:
- If `predicates` is empty, the returned predicate always evaluates to `true`.

- If one nested predicate is too strict, the whole combination may reject more records than expected.

### Notes

1. Put the cheapest or most selective predicates earlier when evaluation cost matters.

2. `all_of(...)` is usually easier to maintain than a custom inline predicate closure.

