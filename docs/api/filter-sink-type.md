---
name: filter-sink-type
group: api
category: sink
update-time: 20260613
description: Public filter sink type used for predicate-based record forwarding over another sink.
key-word:
    - sink
    - filter
    - type
    - public
---

## Filter-sink-type

`FilterSink[S]` is the public predicate wrapper sink type used for forwarding only matching records to another sink. It is the concrete sink type returned by `filter_sink(...)` and preserves the wrapped sink type in its type parameter.

### Interface

```moonbit
pub struct FilterSink[S] {
  sink : S
  predicate : (Record) -> Bool
}
```

#### output

- `FilterSink[S]` - Public synchronous sink type that forwards only predicate-matching records to the wrapped sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields are `sink : S` and `predicate : (Record) -> Bool`.
- `filter_sink(...)` constructs this type directly from a wrapped sink and predicate.
- The sink preserves the wrapped sink type `S`, which is useful when typed composition still matters after filtering is introduced.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Predicate-filtering Sink Value

When code should keep the concrete filter wrapper sink type visible:
```moonbit
let sink : FilterSink[ConsoleSink] = filter_sink(console_sink(), fn(rec) { rec.target == "kept" })
```

In this example, the sink value stays explicit and preserves the wrapped console sink type.

#### When Need A Typed Logger With Sink-level Filtering

When logging should preserve the filter wrapper sink type in the logger:
```moonbit
let logger : Logger[FilterSink[ConsoleSink]] = Logger::new(
  filter_sink(console_sink(), fn(rec) { rec.level == Level::Warn }),
)
```

In this example, the concrete filter sink remains part of the logger type.

### Error Case

e.g.:
- `FilterSink[S]` itself does not have a runtime failure mode.

- Runtime behavior still depends on the wrapped sink `S`, and record selection errors come from the supplied predicate rather than the type itself.

### Notes

1. Use `filter_sink(...)` when you need a value of this type.

2. Use `PatchSink[S]` when records should be rewritten rather than accepted or rejected.
