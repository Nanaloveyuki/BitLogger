---
name: filter-sink
group: api
category: sink
update-time: 20260520
description: Create a sink that forwards only records matching a predicate.
key-word:
    - sink
    - filter
    - predicate
    - public
---

## Filter-sink

Create a sink that forwards only records matching a predicate. This helper is the sink-level counterpart to `Logger::with_filter(...)`.

### Interface

```moonbit
pub fn[S] filter_sink(sink : S, predicate : (Record) -> Bool) -> FilterSink[S] {
```

#### input

- `sink : S` - Wrapped sink receiving records that pass the predicate.
- `predicate : (Record) -> Bool` - Filtering function evaluated for each record.

#### output

- `FilterSink[S]` - Predicate-filtering sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- Only records for which the predicate returns `true` are forwarded.
- This helper is useful for sink-first composition and explicit routing graphs.
- Use the logger-level helper when the filter should be attached after `Logger::new(...)` instead.

### How to Use

Here are some specific examples provided.

#### When Need Predicate Filtering At Sink Construction Time

When a sink graph should reject records before they reach the destination:
```moonbit
let sink = filter_sink(console_sink(), fn(rec) {
  rec.target == "kept"
})
```

In this example, only matching records are forwarded to the wrapped sink.

### Error Case

e.g.:
- If record selection should be attached to an already-built logger, use `with_filter(...)` instead.

- Predicate logic is caller-defined, so accidental over-filtering comes from predicate choice.

### Notes

1. This helper is useful for sink-first composition graphs.

2. It works well with predicate builders such as `target_is(...)` and `all_of(...)`.
