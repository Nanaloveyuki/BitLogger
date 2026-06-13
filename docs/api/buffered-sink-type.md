---
name: buffered-sink-type
group: api
category: sink
update-time: 20260613
description: Public buffered sink type used for threshold-based synchronous batching over another sink.
key-word:
    - sink
    - buffer
    - type
    - public
---

## Buffered-sink-type

`BufferedSink[S]` is the public buffering sink type used for threshold-based synchronous batching over another sink. It is the concrete sink type returned by `buffered_sink(...)` and preserves the wrapped sink type in its type parameter.

### Interface

```moonbit
pub struct BufferedSink[S] {
  sink : S
  buffer : Ref[Array[Record]]
  flush_limit : Int
}
```

#### output

- `BufferedSink[S]` - Public synchronous sink type that buffers records before forwarding them to the wrapped sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields are `sink : S`, `buffer : Ref[Array[Record]]`, and `flush_limit : Int`.
- `buffered_sink(...)` constructs this type directly from a wrapped sink and flush threshold.
- The sink preserves the wrapped sink type `S`, which is useful when typed composition still matters after buffering is introduced.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Buffered Sink Value

When code should keep the concrete buffering sink type visible:
```moonbit
let sink : BufferedSink[ConsoleSink] = buffered_sink(console_sink(), flush_limit=2)
```

In this example, the sink value stays explicit and preserves the wrapped console sink type.

#### When Need A Typed Logger With Synchronous Batching

When logging should preserve the buffering sink type in the logger:
```moonbit
let logger : Logger[BufferedSink[ConsoleSink]] = Logger::new(
  buffered_sink(console_sink(), flush_limit=2),
  target="buffered",
)
```

In this example, the concrete buffered sink remains part of the logger type.

### Error Case

e.g.:
- `BufferedSink[S]` itself does not have a runtime failure mode.

- Runtime behavior still depends on the wrapped sink `S`, and buffered records can remain pending if flushing never happens.

### Notes

1. Use `buffered_sink(...)` when you need a value of this type.

2. Use `QueuedSink[S]` when overflow-aware queueing behavior is needed instead of simple buffering.
