---
name: record-predicate
group: api
category: helper
update-time: 20260613
description: Public predicate function type used for logger filtering and record selection.
key-word:
    - predicate
    - filter
    - record
    - public
---

## Record-predicate

`RecordPredicate` is the public function type used for record filtering. It represents any function that receives a `Record` and returns `Bool`, and it is the shared shape behind helpers such as `level_at_least(...)`, `target_is(...)`, and `filter_sink(...)`.

### Interface

```moonbit
pub type RecordPredicate = @utils.RecordPredicate
```

#### output

- `RecordPredicate` - A function type equivalent to `(Record) -> Bool`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a new runtime wrapper.
- Any function matching `(Record) -> Bool` can be used wherever a `RecordPredicate` is expected.
- Predicates are used by `Logger::with_filter(...)`, `filter_sink(...)`, and helper constructors in `filters.mbt`.
- The alias exists to make filtering APIs clearer and easier to read in public signatures.

### How to Use

Here are some specific examples provided.

#### When Need A Custom Logger Filter

When a logger should only accept records that match local rules:
```moonbit
let predicate : RecordPredicate = fn(rec) { rec.level.priority() >= Level::Warn.priority() }
let logger = Logger::new(console_sink()).with_filter(predicate)
```

In this example, the alias makes the custom filter shape explicit.

#### When Compose Existing Predicate Helpers

When several reusable filters should be combined:
```moonbit
let predicate : RecordPredicate = all_of([
  target_has_prefix("service"),
  not_(message_contains("ignore")),
])
```

In this example, the alias describes the common type returned by the helper constructors.

### Error Case

e.g.:
- A predicate that always returns `false` is valid but will suppress all matching writes.

- A predicate that is expensive to evaluate can add avoidable cost to every filtered record.

### Notes

1. Use the alias when function signatures should communicate filtering intent clearly.

2. Helper constructors in `filters.mbt` are usually preferable to handwritten predicates for common cases.
