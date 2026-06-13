---
name: fanout-sink-type
group: api
category: sink
update-time: 20260613
description: Public fanout sink type used for duplicating records to two underlying sinks.
key-word:
    - sink
    - fanout
    - type
    - public
---

## Fanout-sink-type

`FanoutSink[A, B]` is the public routing sink type used for duplicating each record to two underlying sinks. It is the concrete sink type returned by `fanout_sink(...)` and preserves both wrapped sink types in its type parameters.

### Interface

```moonbit
pub struct FanoutSink[A, B] {
  left : A
  right : B
}
```

#### output

- `FanoutSink[A, B]` - Public synchronous sink type that forwards each record to both wrapped sinks.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields are `left : A` and `right : B`.
- `fanout_sink(...)` constructs this type directly from two sink values.
- The sink preserves both wrapped sink types in the public type, which is useful when typed composition still matters after duplication is introduced.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Dual-output Sink Value

When code should keep the concrete duplication sink type visible:
```moonbit
let sink : FanoutSink[ConsoleSink, JsonConsoleSink] = fanout_sink(console_sink(), json_console_sink())
```

In this example, the sink value stays explicit and preserves both destination sink types.

#### When Need A Typed Logger With Duplicated Delivery

When logging should preserve the fanout sink type in the logger:
```moonbit
let logger : Logger[FanoutSink[ConsoleSink, JsonConsoleSink]] = Logger::new(
  fanout_sink(console_sink(), json_console_sink()),
  target="dual",
)
```

In this example, the concrete duplication sink remains part of the logger type.

### Error Case

e.g.:
- `FanoutSink[A, B]` itself does not have a runtime failure mode.

- Runtime behavior still depends on both wrapped sinks, so any sink-specific limitations remain unchanged behind the fanout wrapper.

### Notes

1. Use `fanout_sink(...)` when you need a value of this type.

2. Use `SplitSink[A, B]` when records should go to one side conditionally instead of always going to both sides.
