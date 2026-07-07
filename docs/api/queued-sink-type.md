---
name: queued-sink-type
group: api
category: sink
update-time: 20260613
description: Public queued sink type used for explicit synchronous queueing over another sink.
key-word:
    - sink
    - queue
    - type
    - public
---

## Queued-sink-type

`QueuedSink[S]` is the public queue wrapper sink type used for explicit synchronous queueing over another sink. It is the concrete sink type returned by `queued_sink(...)` and preserves the wrapped sink type in its type parameter.

### Interface

```moonbit
pub struct QueuedSink[S] {
  sink : S
  queue : @queue.Queue[Record]
  max_pending : Int
  overflow : QueueOverflowPolicy
  dropped_count : Ref[Int]
}
```

#### output

- `QueuedSink[S]` - Public synchronous sink type that queues records before they are drained to the wrapped sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields are `sink : S`, `queue : @queue.Queue[Record]`, `max_pending : Int`, `overflow : QueueOverflowPolicy`, and `dropped_count : Ref[Int]`.
- The `overflow` field resolves to the shared `@queue_model.QueueOverflowPolicy` owner.
- `queued_sink(...)` constructs this type directly from a wrapped sink and queue policy.
- The sink preserves the wrapped sink type `S`, which is useful when typed composition still matters after queueing is introduced.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Queued Sink Value

When code should keep the concrete queue wrapper sink type visible:
```moonbit
let sink : QueuedSink[ConsoleSink] = queued_sink(console_sink(), max_pending=4)
```

In this example, the sink value stays explicit and preserves the wrapped console sink type.

#### When Need A Typed Logger With Explicit Queueing

When logging should preserve the queue wrapper sink type in the logger:
```moonbit
let logger : Logger[QueuedSink[ConsoleSink]] = Logger::new(
  queued_sink(console_sink(), max_pending=2, overflow=QueueOverflowPolicy::DropOldest),
  target="queue",
)
```

In this example, the concrete queued sink remains part of the logger type.

### Error Case

e.g.:
- `QueuedSink[S]` itself does not have a runtime failure mode.

- Runtime behavior still depends on the wrapped sink `S`, and records may be dropped when the queue reaches the configured bound.

### Notes

1. Use `queued_sink(...)` when you need a value of this type.

2. Use `BufferedSink[S]` when simple threshold buffering is enough and overflow policy is unnecessary.
