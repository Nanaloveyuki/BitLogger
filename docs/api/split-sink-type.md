---
name: split-sink-type
group: api
category: sink
update-time: 20260613
description: Public split sink type used for routing records to one of two underlying sinks with a predicate.
key-word:
    - sink
    - split
    - type
    - public
---

## Split-sink-type

`SplitSink[A, B]` is the public routing sink type used for sending each record to one of two underlying sinks based on a predicate. It is the concrete sink type returned by both `split_sink(...)` and `split_by_level(...)`, and it preserves both wrapped sink types in its type parameters.

### Interface

```moonbit
pub struct SplitSink[A, B] {
  left : A
  right : B
  predicate : (Record) -> Bool
}
```

#### output

- `SplitSink[A, B]` - Public synchronous sink type that routes each record to one of two wrapped sinks.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields are `left : A`, `right : B`, and `predicate : (Record) -> Bool`.
- `split_sink(...)` constructs this type directly from two sink values and a predicate.
- `split_by_level(...)` also returns this same type after building a level-based predicate wrapper.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Predicate-routing Sink Value

When code should keep the concrete routing sink type visible:
```moonbit
let sink : SplitSink[ConsoleSink, JsonConsoleSink] = split_sink(
  console_sink(),
  json_console_sink(),
  fn(rec) { rec.target == "audit" },
)
```

In this example, the sink value stays explicit and preserves both destination sink types plus the routing behavior.

#### When Need A Typed Logger With Conditional Delivery

When logging should preserve the split sink type in the logger:
```moonbit
let logger : Logger[SplitSink[ConsoleSink, JsonConsoleSink]] = Logger::new(
  split_by_level(console_sink(), json_console_sink(), min_level=Level::Warn),
  target="route",
)
```

In this example, the concrete conditional routing sink remains part of the logger type.

### Error Case

e.g.:
- `SplitSink[A, B]` itself does not have a runtime failure mode.

- Routing behavior still depends on the stored predicate and both wrapped sinks, so misrouting or sink-specific limitations remain outside the split type itself.

### Notes

1. Use `split_sink(...)` or `split_by_level(...)` when you need a value of this type.

2. Use `FanoutSink[A, B]` when each record should always be delivered to both sides instead of one side conditionally.
