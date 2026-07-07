---
name: runtime-sink-flush
group: api
category: runtime
update-time: 20260707
description: Compatibility RuntimeSink flush helper that still returns one Int by collapsing generic queue progress and plain-file fallback steps.
key-word:
    - runtime
    - sink
    - flush
    - public
---

## Runtime-sink-flush

Flush a `RuntimeSink` and return one compatibility count. This helper is still available for older code, but new generic runtime code should prefer `flush_progress()` because it exposes queue advancement and plain-file fallback steps separately.

### Interface

```moonbit
pub fn RuntimeSink::flush(self : RuntimeSink) -> Int {
```

#### input

- `self : RuntimeSink` - Runtime sink whose pending file or queue work should be flushed.

#### output

- `Int` - Compatibility count produced from the structured `flush_progress()` result.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method now delegates to `flush_progress()` and sums `queue_advanced_count + file_flush_step_count` back into one compatibility number.
- Plain console-style runtime sinks still return `0` because the structured result stays zeroed.
- Plain file runtime sinks still expose their generic fallback through `1` or `0`, but that value now comes from `file_flush_step_count` in the structured result.
- Queue-wrapped runtime sinks still return the number of queued records consumed during that flush.
- For queued file sinks, a positive returned count still means queue advancement, not a durable file-write count.
- This method remains the direct sink-level API used by `ConfiguredLogger::flush(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime Flush Control

When older code is already built around one numeric flush count:
```moonbit
let flushed = sink.flush()
```

In this example, the runtime sink still reports one compatibility count.

#### When Need Queue Or File Progress Visibility

When code only needs a coarse non-zero check and does not care which runtime dimension advanced:
```moonbit
if sink.flush() > 0 {
  ()
}
```

In this example, the count still reflects generic runtime advancement, not durable file success.

### Error Case

e.g.:
- If the runtime sink shape has no flushable state, the method may simply return `0`.

- If callers need truthful generic progress semantics, `flush_progress()` is the better API.

- If callers need bounded queue progress, `drain_progress(...)` is usually the better API.

- If callers need file-specific success semantics on a file-backed sink, `file_flush()` is the better API.

### Notes

1. Treat this method as a compatibility helper for older numeric code.

2. Prefer `flush_progress()` in new generic runtime code.

3. `ConfiguredLogger::flush(...)` is the higher-level wrapper for config-built loggers.
