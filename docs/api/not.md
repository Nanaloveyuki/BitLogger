---
name: not
group: api
category: filtering
update-time: 20260512
description: Create a reusable record predicate that negates another predicate.
key-word:
    - negate
    - filter
    - predicate
    - public
---

## Not

Create a `RecordPredicate` that returns the logical inverse of another predicate. This helper is the standard way to express exclusion rules without rewriting predicate bodies.

### Interface

```moonbit
pub fn not_(predicate : RecordPredicate) -> RecordPredicate {}
```

#### input

- `predicate : RecordPredicate` - Existing predicate to invert.

#### output

- `RecordPredicate` - Predicate that returns `true` when the original predicate returns `false`.

### Explanation

Detailed rules explaining key parameters and behaviors

- `not_(...)` delegates evaluation to the original predicate and flips the boolean result.
- It does not change the record or short-circuit upstream logic outside the wrapped predicate.
- This helper is useful for excluding known noisy targets, fields, or message patterns.
- It composes well with `all_of(...)` and `any_of(...)` for more expressive routing rules.

### How to Use

Here are some specific examples provided.

#### When Exclude One Target Prefix

When everything except one noisy subsystem should pass:
```moonbit
let logger = Logger::new(console_sink())
  .with_filter(not_(target_has_prefix("debug.spam")))
```

In this example, records under `debug.spam...` are filtered out.

#### When Invert A Field Match

When one tenant should be excluded from a shared stream:
```moonbit
let predicate = not_(field_equals("tenant", "internal"))
```

In this example, all non-internal tenant records continue through the filter.

### Error Case

e.g.:
- If the wrapped predicate always returns `true`, the negated predicate always returns `false`.

- If the wrapped predicate is too broad, the inversion may unintentionally admit unrelated records.

### Notes

1. Prefer `not_(...)` over duplicating inverse logic inline because the intent is easier to read.

2. Negation is most maintainable when the wrapped predicate is itself narrow and well named.

