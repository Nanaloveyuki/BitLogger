---
name: target-has-prefix
group: api
category: filtering
update-time: 20260512
description: Create a reusable record predicate that matches records by target prefix.
key-word:
    - target
    - filter
    - predicate
    - public
---

## Target-has-prefix

Create a `RecordPredicate` that returns `true` when a record target starts with a given prefix. This helper is commonly used with `with_filter(...)`, `filter_sink(...)`, `all_of(...)`, and routing logic.

### Interface

```moonbit
pub fn target_has_prefix(prefix : String) -> RecordPredicate {}
```

#### input

- `prefix : String` - Prefix expected at the start of `rec.target`.

#### output

- `RecordPredicate` - Predicate that matches records whose target starts with the given prefix.

### Explanation

Detailed rules explaining key parameters and behaviors

- Matching is based on `String::has_prefix(...)` over the full target string.
- This helper does not modify records; it only returns a reusable predicate.
- Prefix-based matching is especially useful when using hierarchical targets such as `app.worker.job`.
- It composes cleanly with `all_of(...)`, `any_of(...)`, and `not_(...)`.

### How to Use

Here are some specific examples provided.

#### When Filter A Target Namespace

When a logger should keep one target subtree:
```moonbit
let logger = Logger::new(console_sink(), target="app")
  .with_filter(target_has_prefix("app.worker"))
```

In this example, only records under `app.worker...` remain visible.

And child targets continue to compose naturally.

#### When Combine With Level Rules

When both namespace and severity matter:
```moonbit
let predicate = all_of([
  target_has_prefix("service.api"),
  level_at_least(Level::Warn),
])
```

In this example, the predicate stays reusable across multiple loggers or sinks.

### Error Case

e.g.:
- If `prefix` is empty, the predicate effectively matches every target because every string starts with an empty prefix.

- If no target matches the prefix, the predicate simply returns `false` for those records.

### Notes

Notes are here.

1. This helper is most useful when targets are structured hierarchically.

2. Prefer this helper over ad hoc inline prefix logic for readability.

3. Use `target_is(...)` instead when exact equality is required.

4. Combine with `message_contains(...)` or field predicates for narrower routing rules.
