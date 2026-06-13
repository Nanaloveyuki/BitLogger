---
name: runtime-sink-file-flush
group: api
category: runtime
update-time: 20260613
description: Flush the file sink behind a RuntimeSink when one is present.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-flush

Flush the file sink behind a `RuntimeSink`. This helper is the direct file-specific runtime flush surface for code that owns a sink value instead of a `ConfiguredLogger`.

### Interface

```moonbit
pub fn RuntimeSink::file_flush(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file sink should be flushed.

#### output

- `Bool` - Whether the underlying file flush succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants forward directly to `FileSink::flush()`.
- `QueuedFile` runtime variants first attempt `sink.flush()` on the queue wrapper, then call `sink.sink.flush()` on the wrapped file sink.
- For `QueuedFile`, the queue flush result is ignored and the returned `Bool` comes from the inner file flush.
- For `QueuedFile`, this step may also be the point where queued records finally reach the inner file sink, so write-failure counters can change here even if earlier `log(...)` calls only enqueued records.
- Non-file runtime variants return `false`.

### How to Use

Here are some specific examples provided.

#### When Need Explicit Direct File Durability Steps

When code holds a file-backed `RuntimeSink` directly and should flush it explicitly:
```moonbit
ignore(sink.file_flush())
```

In this example, the runtime sink attempts to flush its file-backed output directly.

#### When Need A File-specific Success Flag

When code should branch on the outcome of a direct file flush:
```moonbit
let ok = sink.file_flush()
```

In this example, callers can distinguish file flush success from a non-file sink shape.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers want generic queue or sink advancement instead of file-specific behavior, `flush()` is the broader API.

### Notes

1. Prefer this helper when direct runtime code specifically cares about file flush behavior.

2. Queued file sinks may perform both queue flush work and file flush work here, including surfacing delayed write failures from previously queued records.
