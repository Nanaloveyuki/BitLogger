---
name: buffered-sink-flush
group: api
category: sink
update-time: 20260613
description: Flush buffered records from a BufferedSink into its wrapped sink.
key-word:
    - sink
    - buffer
    - flush
    - public
---

## Buffered-sink-flush

Flush buffered records from a `BufferedSink[S]` into its wrapped sink. This is the direct sink-level batching control API for simple synchronous buffering.

### Interface

```moonbit
pub fn[S : Sink] BufferedSink::flush(self : BufferedSink[S]) -> Unit {
```

#### input

- `self : BufferedSink[S]` - Buffered sink whose pending records should be forwarded to the wrapped sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- If the buffer is empty, the method does nothing.
- When buffered records exist, they are copied into a temporary `pending` array, the live buffer is cleared, and each record is then written to the wrapped sink in order.
- This helper drains only the local buffer; any later behavior still depends on the wrapped sink `S`.
- The method does not return a count or success flag.

### How to Use

Here are some specific examples provided.

#### When Need Explicit Batch Delivery

When a buffered sink should forward pending records before the threshold is reached:
```moonbit
sink.flush()
```

In this example, callers force buffered records to be written to the wrapped sink immediately.

#### When Need A Manual Flush Barrier

When tests or synchronous code want buffering but still need a deliberate release point:
```moonbit
let sink = buffered_sink(console_sink(), flush_limit=4)
sink.flush()
```

In this example, the buffered sink exposes a direct batching barrier without using queue semantics.

### Error Case

e.g.:
- If the wrapped sink's write behavior fails or has side effects, this helper does not add an extra reporting layer on top of `S`.

- If callers need a count-returning drain API with drop tracking, `QueuedSink::flush()` or `QueuedSink::drain()` may fit better.

### Notes

1. Use this helper when code owns a `BufferedSink` directly and wants explicit control over when buffered records are forwarded.

2. Automatic flush still happens when buffered record count reaches `flush_limit` during writes.
