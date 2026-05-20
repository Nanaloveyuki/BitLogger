---
name: split-by-level
group: api
category: sink
update-time: 20260520
description: Create a split sink that routes records by minimum enabled level.
key-word:
    - sink
    - split
    - level
    - public
---

## Split-by-level

Create a split sink that routes records to one of two sinks based on whether the record level is enabled at a given minimum level.

### Interface

```moonbit
pub fn[A, B] split_by_level(
  left : A,
  right : B,
  min_level~ : Level = Level::Warn,
) -> SplitSink[A, B] {
```

#### input

- `left : A` - Sink receiving records at or above `min_level`.
- `right : B` - Sink receiving records below `min_level`.
- `min_level : Level` - Threshold used for routing.

#### output

- `SplitSink[A, B]` - Level-based routing sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a convenience wrapper over `split_sink(...)`.
- High-severity and low-severity records can be separated without writing the predicate manually.
- It is useful for patterns such as warnings/errors to one destination and info/debug to another.

### How to Use

Here are some specific examples provided.

#### When Need Severity-based Routing

When warnings and errors should go to a special path:
```moonbit
let sink = split_by_level(callback_sink(fn(rec) {
  println(rec.message)
}), console_sink(), min_level=Level::Warn)
```

In this example, `WARN` and above go to the left sink.

### Error Case

e.g.:
- If routing should use target, message, or fields instead of level, use `split_sink(...)` with a custom predicate.

- Sink-specific write behavior still follows the wrapped sinks.

### Notes

1. This is a convenience routing helper for a common policy.

2. It preserves the same one-side-only routing model as `split_sink(...)`.
