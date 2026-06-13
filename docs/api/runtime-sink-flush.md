---
name: runtime-sink-flush
group: api
category: runtime
update-time: 20260613
description: Flush a RuntimeSink and return how many queued or file-backed operations were advanced.
key-word:
    - runtime
    - sink
    - flush
    - public
---

## Runtime-sink-flush

Flush a `RuntimeSink` and return how much work was advanced. This is the direct runtime control API behind configured logger flush behavior.

### Interface

```moonbit
pub fn RuntimeSink::flush(self : RuntimeSink) -> Int {
```

#### input

- `self : RuntimeSink` - Runtime sink whose pending file or queue work should be flushed.

#### output

- `Int` - Count of advanced operations as reported by the concrete runtime sink variant.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain console-style runtime sinks return `0` because they do not keep explicit buffered flush state here.
- Plain file runtime sinks call `FileSink::flush()` and convert the boolean result into `1` or `0`.
- Queue-wrapped runtime sinks forward to the wrapped queue sink's `flush()` behavior.
- This method is the direct sink-level API used by `ConfiguredLogger::flush(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime Flush Control

When code is working with a `RuntimeSink` value directly instead of going through `ConfiguredLogger`:
```moonbit
let flushed = sink.flush()
```

In this example, the runtime sink reports how much flush work was advanced.

#### When Need Queue Or File Progress Visibility

When support code should observe whether a direct flush request did useful work:
```moonbit
if sink.flush() > 0 {
  ()
}
```

In this example, the return value reflects whether queue draining or file flushing advanced any work.

### Error Case

e.g.:
- If the runtime sink shape has no flushable state, the method may simply return `0`.

- If callers need bounded queue progress, `drain(...)` is the better API.

### Notes

1. Use this helper when direct runtime sink flushing matters.

2. `ConfiguredLogger::flush(...)` is the higher-level wrapper for config-built loggers.
