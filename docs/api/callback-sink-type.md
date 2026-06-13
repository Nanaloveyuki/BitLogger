---
name: callback-sink-type
group: api
category: sink
update-time: 20260613
description: Public callback sink type used for forwarding structured records to user code.
key-word:
    - sink
    - callback
    - type
    - public
---

## Callback-sink-type

`CallbackSink` is the public callback sink type used for forwarding structured `Record` values to user code. It is the concrete sink type returned by `callback_sink(...)` and is intended for tests, adapters, and custom integrations that want raw record access.

### Interface

```moonbit
pub struct CallbackSink {
  callback : (Record) -> Unit
}
```

#### output

- `CallbackSink` - Public synchronous sink type that forwards full `Record` values to a stored callback.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current field is `callback : (Record) -> Unit`.
- `callback_sink(...)` constructs this type directly from a record callback.
- Unlike `FormattedCallbackSink`, this sink preserves full structured record access instead of converting records into text first.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Structured Callback Sink Value

When code should keep the concrete record-callback sink type visible:
```moonbit
let sink : CallbackSink = callback_sink(fn(rec) { println(rec.message) })
```

In this example, the sink value stays explicit and preserves direct access to structured record data.

#### When Need A Typed Callback-backed Logger

When logging should preserve the raw-record callback sink type in the logger:
```moonbit
let logger : Logger[CallbackSink] = Logger::new(callback_sink(fn(rec) { println(rec.target) }))
```

In this example, the concrete callback sink remains part of the logger type.

### Error Case

e.g.:
- `CallbackSink` itself does not have a runtime failure mode.

- Behavior inside the stored callback is fully user-defined, so failures there are outside the sink type's own API contract.

### Notes

1. Use `callback_sink(...)` when you need a value of this type.

2. Use `FormattedCallbackSink` when the destination expects final rendered text rather than full `Record` values.
