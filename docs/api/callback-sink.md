---
name: callback-sink
group: api
category: sink
update-time: 20260520
description: Create a sink that forwards records to a user callback.
key-word:
    - sink
    - callback
    - record
    - public
---

## Callback-sink

Create a sink that forwards each `Record` to a callback. This is the most direct built-in integration hook for tests, adapters, and custom side effects.

### Interface

```moonbit
pub fn callback_sink(callback : (Record) -> Unit) -> CallbackSink {
```

#### input

- `callback : (Record) -> Unit` - Function called for each emitted record.

#### output

- `CallbackSink` - Sink that forwards records to the callback.

### Explanation

Detailed rules explaining key parameters and behaviors

- The callback receives the full structured record.
- This sink is useful for tests, custom bridges, or integration code that wants raw record access.
- Formatting is not applied automatically because the callback works on `Record` values directly.

### How to Use

Here are some specific examples provided.

#### When Need To Capture Structured Records

When tests or adapters want direct access to target, message, and fields:
```moonbit
let logger = Logger::new(
  callback_sink(fn(rec) {
    println(rec.target)
  }),
  target="hook",
)
```

In this example, the callback sees the structured record rather than pre-rendered text.

### Error Case

e.g.:
- If text output is needed instead of raw records, use `text_callback_sink(...)`.

- Callback behavior is fully user-defined, so failures inside the callback are outside the sink's own API contract.

### Notes

1. This sink is commonly useful in tests and adapters.

2. It composes naturally with filter, patch, fanout, and queue wrappers.
