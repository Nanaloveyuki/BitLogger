---
name: target-is
group: api
category: filtering
update-time: 20260512
description: Create a reusable record predicate that matches a single exact target.
key-word:
    - target
    - filter
    - predicate
    - public
---

## Target-is

Create a `RecordPredicate` that returns `true` only when a record target exactly matches the expected string. Use it when one specific logical source should pass through a filter.

### Interface

```moonbit
pub fn target_is(target : String) -> RecordPredicate {}
```

#### input

- `target : String` - Exact target value expected from the record.

#### output

- `RecordPredicate` - Predicate that matches records whose `rec.target` equals `target`.

### Explanation

Detailed rules explaining key parameters and behaviors

- Matching uses direct string equality.
- This helper does not perform prefix or fuzzy matching.
- It is useful for isolating one subsystem when targets are intentionally stable.
- Combine it with level predicates when a single target needs stricter routing rules.

### How to Use

Here are some specific examples provided.

#### When Keep One Exact Target

When only one service target should pass:
```moonbit
let logger = Logger::new(console_sink())
  .with_filter(target_is("gateway.http"))
```

In this example, records from sibling targets such as `gateway.ws` are excluded.

#### When Route A Single Target To A Sink

When a split path needs an exact match:
```moonbit
let predicate = all_of([
  target_is("audit"),
  level_at_least(Level::Info),
])
```

In this example, the filter remains predictable because it does not rely on naming prefixes.

### Error Case

e.g.:
- If `target` is empty, only records whose target is also an empty string will match.

- If record targets are generated dynamically, exact matching may be too strict and lead to no matches.

### Notes

1. Prefer `target_has_prefix(...)` when targets are hierarchical and you want subtree matching.

2. Exact target filters are easiest to maintain when target naming is stable across the project.

