---
name: level-at-least
group: api
category: filtering
update-time: 20260512
description: Create a reusable record predicate that keeps records at or above a minimum level.
key-word:
    - level
    - filter
    - predicate
    - public
---

## Level-at-least

Create a `RecordPredicate` that returns `true` when a record level is greater than or equal to a minimum threshold. This is the main helper for severity-based filtering.

### Interface

```moonbit
pub fn level_at_least(min_level : Level) -> RecordPredicate {}
```

#### input

- `min_level : Level` - The lowest level that should remain enabled.

#### output

- `RecordPredicate` - Predicate that keeps records whose `priority()` is at least the given minimum.

### Explanation

Detailed rules explaining key parameters and behaviors

- Matching is based on `Level::priority()`, not string comparison.
- Records at the exact same level as `min_level` are included.
- This helper is useful when a sink or child logger needs a stricter threshold than the parent logger.
- It composes cleanly with `all_of(...)` and `any_of(...)`.

### How to Use

Here are some specific examples provided.

#### When Keep Warnings And Errors

When a logger should keep only important records:
```moonbit
let logger = Logger::new(console_sink())
  .with_filter(level_at_least(Level::Warn))
```

In this example, `Warn` and `Error` records continue through the filter.

#### When Combine With Target Routing

When both severity and namespace matter:
```moonbit
let predicate = all_of([
  target_has_prefix("service.api"),
  level_at_least(Level::Info),
])
```

In this example, the predicate can be reused by multiple loggers or sinks.

### Error Case

e.g.:
- If `min_level` is `Level::Trace`, the predicate effectively allows all normal log records.

- If `min_level` is higher than the record level, the predicate returns `false` without modifying the record.

### Notes

1. Use this helper when you want filtering logic to remain explicit instead of embedding level checks inline.

2. This predicate is separate from a logger's own `min_level`, so both can be combined.

